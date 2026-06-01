#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : nexus snapshot manager.
# @license  : Apache License 2.0
# @since    : 2026-06-01
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/<파일명>" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into 
#      etc/bashrc for all users.
# =======================================

readonly FILENAME=$(basename "$0")

##
# 스크립트의 사용법을 출력하거나 오류 발생 시 콜스택을 출력합니다.
#
# @param $1 {string} (오류 원인 메시지, 선택사항)
# @param $2 {string} (오류 발생 라인, 선택사항)
#
# @return (도움말 내용 출력)
##
help(){
  if [ ! -z "$1" ];
  then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  # TODO: Usage 내용 작성
  echo "사용법: $FILENAME [옵션]"
  echo "옵션:"
  echo "  -g, --group-id <id>      Nexus Group ID (콤마로 다중 입력 가능)"
  echo "  -a, --artifact-id <id>   Nexus Artifact ID (콤마로 다중 입력 가능)"
  echo "  -h, --help               도움말 출력"
  echo
  echo "💡 파라미터 없이 실행 시 대화형 모드(Interactive Mode)로 진입합니다."
  echo "🚨 참고 1: 실행 중 Ctrl + C를 누르면 즉시 스크립트가 강제 종료됩니다."
  echo "📝 참고 2: 삭제 시 생성되는 로그 파일은 임시 공간(/tmp)에 자동 저장되며 30일이 지나면 삭제됩니다."
}

##
# jq 패키지 설치 여부를 검증하고, 없을 경우 패키지 관리자를 통해 설치를 유도합니다.
#
# @param (없음)
#
# @return (없음)
##
ensure_jq() {
  if ! command -v jq > /dev/null 2>&1; then
    echo "⚠️ [안내] JSON 처리를 위한 'jq' 패키지가 시스템에 설치되어 있지 않습니다."
    read -p "🛠️ 'jq' 패키지를 지금 설치하시겠습니까? (sudo 권한이 필요할 수 있습니다) [Y/n]: " install_confirm
    install_confirm=${install_confirm:-Y}
    
    if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
      echo "🔍 시스템 패키지 관리자를 확인하고 'jq' 설치를 시도합니다..."
      if command -v apt-get > /dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y jq
      elif command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y epel-release 2>/dev/null
        sudo dnf install -y jq
      elif command -v yum > /dev/null 2>&1; then
        sudo yum install -y epel-release 2>/dev/null
        sudo yum install -y jq
      else
        help "❌ 지원되는 패키지 관리자(apt, dnf, yum)를 찾을 수 없습니다. 수동으로 'jq'를 설치해 주세요." "$LINENO"
        exit 1
      fi
      
      if ! command -v jq > /dev/null 2>&1; then
        help "❌ 'jq' 설치에 실패했습니다. 관리자에게 문의하거나 수동으로 설치해 주세요." "$LINENO"
        exit 1
      fi
      echo "✅ 'jq' 패키지가 성공적으로 설치되었습니다. 작업을 계속 진행합니다."
      echo "--------------------------------------------------------------------------------"
    else
      help "❌ 스크립트 실행을 위해 'jq' 패키지가 반드시 필요합니다. 스크립트를 종료합니다." "$LINENO"
      exit 1
    fi
  fi
}

##
# 30일이 지난 오래된 임시 로그 파일을 삭제합니다.
#
# @param $1 {string} 로그 디렉토리 경로
#
# @return (없음)
##
cleanup_old_logs() {
  local log_dir="$1"
  if [ -d "$log_dir" ]; then
    find "$log_dir" -maxdepth 1 -name "nexus-snapshot-manager_*.log" -type f -mtime +30 -delete 2>/dev/null
  fi
}

##
# 디렉토리 경로의 존재 여부를 검증하고, 없을 경우 자동 생성합니다.
#
# @param $1 {string} 파일 또는 디렉토리 경로
#
# @return (없음)
##
ensure_directory() {
  local target_path="$1"
  local dir_path=$(dirname "$target_path")
  
  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path" || { help "디렉토리 생성 실패: $dir_path" "$LINENO"; exit 1; }
  fi
}

##
# Nexus REST API에서 continuationToken을 순회하며 특정 필드 데이터를 모두 추출합니다.
#
# @param $1 {string} 검색 쿼리 조건 (예: "maven.groupId=com.example")
# @param $2 {string} jq 추출 필드 (예: ".group" 또는 '"\(.name):\(.version)"')
#
# @return (개행으로 구분된 추출된 필드 데이터 목록)
##
fetch_nexus_field() {
  local query="$1"
  local field="$2"
  
  local api_endpoint="${NEXUS_URL}/service/rest/v1/search?repository=${NEXUS_REPO}"
  if [ ! -z "$query" ]; then
    api_endpoint="${api_endpoint}&${query}"
  fi

  local token=""
  local has_more="true"
  
  while [ "$has_more" == "true" ]; do
    local current_url="$api_endpoint"
    if [ ! -z "$token" ] && [ "$token" != "null" ]; then
      current_url="${current_url}&continuationToken=${token}"
    fi

    local response=$(curl -s -u "${NEXUS_USER}:${NEXUS_PASS}" -X GET "$current_url")
    if [ -z "$response" ]; then break; fi
    
    echo "$response" | jq -r ".items[] | ${field}" | grep -v "null"
    
    token=$(echo "$response" | jq -r '.continuationToken // "null"')
    if [ "$token" == "null" ]; then
      has_more="false"
    fi
  done
}

##
# 특정 Group ID, Artifact ID, Base Version에 해당하는 배포 파일 목록을 조회하고 최신순으로 정렬합니다.
#
# @param $1 {string} Group ID
# @param $2 {string} Artifact ID
# @param $3 {string} Base Version (예: 2.1.0-SNAPSHOT)
#
# @return (JSON 배열 형식의 Snapshot 메타데이터 출력)
##
fetch_nexus_snapshots() {
  local group="$1"
  local artifact="$2"
  local base_version="$3"
  
  local api_endpoint="${NEXUS_URL}/service/rest/v1/search?repository=${NEXUS_REPO}&maven.groupId=${group}&maven.artifactId=${artifact}&maven.baseVersion=${base_version}"
  local token=""
  local has_more="true"
  local result="[]"
  
  while [ "$has_more" == "true" ]; do
    local current_url="$api_endpoint"
    if [ ! -z "$token" ] && [ "$token" != "null" ]; then
      current_url="${current_url}&continuationToken=${token}"
    fi

    local response=$(curl -s -u "${NEXUS_USER}:${NEXUS_PASS}" -X GET "$current_url")
    if [ -z "$response" ]; then break; fi
    
    local items=$(echo "$response" | jq -c '[.items[] | select(.version | contains("SNAPSHOT") or contains("-"))]')
    if [ "$items" != "[]" ]; then
      result=$(echo "$result" | jq -c ". + $items")
    fi
    
    token=$(echo "$response" | jq -r '.continuationToken // "null"')
    if [ "$token" == "null" ]; then
      has_more="false"
    fi
  done
  
  echo "$result" | jq -r 'sort_by(.assets[0].lastModified) | reverse'
}

# -----------------------------------------------------------------------------
# 강제 종료 트랩(Trap) 설정
# -----------------------------------------------------------------------------
trap 'echo -e "\n\n🚨 [안내] Ctrl+C 입력이 감지되어 스크립트를 즉시 강제 종료합니다."; exit 130' SIGINT

# -----------------------------------------------------------------------------
# 메인 로직 시작
# -----------------------------------------------------------------------------

# 0. 로깅 설정 및 오래된 로그 정리
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/nexus-snapshot-manager_$(date '+%Y%m%d_%H%M%S').log"
cleanup_old_logs "$LOG_DIR"

# 1. 의존성 및 변수 검증
ensure_jq

if [ -z "$NEXUS_URL" ] || [ -z "$NEXUS_REPO" ] || [ -z "$NEXUS_USER" ] || [ -z "$NEXUS_PASS" ]; then
  help "필수 환경 변수(NEXUS_URL, NEXUS_REPO, NEXUS_USER, NEXUS_PASS)가 설정되지 않았습니다." "$LINENO"
  exit 1
fi

GROUP_ID=""
ARTIFACT_ID=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -g|--group-id) GROUP_ID="$2"; shift ;;
    -a|--artifact-id) ARTIFACT_ID="$2"; shift ;;
    -h|--help) help; exit 0 ;;
    *) help "알 수 없는 파라미터입니다: $1" "$LINENO"; exit 1 ;;
  esac
  shift
done

if [ -z "$GROUP_ID" ] && [ ! -z "$ARTIFACT_ID" ]; then
  help "Group ID가 입력되지 않은 경우 Artifact ID는 사용할 수 없습니다." "$LINENO"
  exit 1
fi

# 2. Group ID 처리
selected_groups=()

if [ -z "$GROUP_ID" ]; then
  echo "🔍 Nexus에서 Group ID 목록을 조회 중입니다..."
  mapfile -t all_groups < <(fetch_nexus_field "" ".group" | sort -u)
  
  if [ ${#all_groups[@]} -eq 0 ]; then
    echo "⚠️ 조회된 Group ID가 없습니다."
    exit 0
  fi
  
  idx=1
  for g in "${all_groups[@]}"; do
    printf "📦 [%2d] %s\n" "$idx" "$g"
    ((idx++))
  done
  
  # 전체 선택 '0' 안내 추가
  read -p "⌨️ 선택할 Group ID 번호를 콤마(,)로 구분하여 입력하세요 (예: 1,2,5 / 전체선택: 0): " group_inputs
  IFS=',' read -ra indices <<< "$group_inputs"
  
  # '0'이 포함되어 있는지 검사 (전체 선택 로직)
  select_all="false"
  for i in "${indices[@]}"; do
    i=$(echo "$i" | xargs)
    if [ "$i" == "0" ]; then
      select_all="true"
      break
    fi
  done
  
  if [ "$select_all" == "true" ]; then
    selected_groups=("${all_groups[@]}")
  else
    for i in "${indices[@]}"; do
      i=$(echo "$i" | xargs)
      if [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le "${#all_groups[@]}" ]; then
        selected_groups+=("${all_groups[$((i-1))]}")
      fi
    done
  fi
else
  IFS=',' read -ra selected_groups <<< "$GROUP_ID"
fi

if [ ${#selected_groups[@]} -eq 0 ]; then
  echo "🛑 선택된 Group ID가 없어 스크립트를 종료합니다."
  exit 0
fi

# 3. Artifact ID 및 Version 매핑
declare -a target_components=()
display_idx=1

for g in "${selected_groups[@]}"; do
  printf "📂 [%2d] %s\n" "$display_idx" "$g"
  
  # 이전 그룹의 데이터가 남지 않도록 초기화 (카운트 배열 추가)
  unset art_versions art_ver_counts
  declare -A art_versions
  declare -A art_ver_counts
  
  if [ -z "$ARTIFACT_ID" ]; then
    mapfile -t comp_list < <(fetch_nexus_field "maven.groupId=$g" '"\(.name):\(.version)"')
    for comp in "${comp_list[@]}"; do
      art="${comp%%:*}"
      ver="${comp#*:}"
      bv=$(echo "$ver" | sed -E 's/-[0-9]{8}\.[0-9]{6}-[0-9]+$/-SNAPSHOT/')
      if [[ "$bv" == *"-SNAPSHOT" ]]; then
        if [[ ! " ${art_versions[$art]} " =~ " $bv " ]]; then
          art_versions["$art"]+="$bv "
        fi
        # [추가됨] 발견된 배포파일(Version) 개수 누적
        ((art_ver_counts["${art}:${bv}"]++))
      fi
    done
  else
    IFS=',' read -ra provided_arts <<< "$ARTIFACT_ID"
    for pa in "${provided_arts[@]}"; do
      pa=$(echo "$pa" | xargs)
      mapfile -t comp_list < <(fetch_nexus_field "maven.groupId=$g&maven.artifactId=$pa" '"\(.name):\(.version)"')
      for comp in "${comp_list[@]}"; do
        art="${comp%%:*}"
        ver="${comp#*:}"
        bv=$(echo "$ver" | sed -E 's/-[0-9]{8}\.[0-9]{6}-[0-9]+$/-SNAPSHOT/')
        if [[ "$bv" == *"-SNAPSHOT" ]]; then
          if [[ ! " ${art_versions[$art]} " =~ " $bv " ]]; then
            art_versions["$art"]+="$bv "
          fi
          # [추가됨] 발견된 배포파일(Version) 개수 누적
          ((art_ver_counts["${art}:${bv}"]++))
        fi
      done
    done
  fi
  
  arts=("${!art_versions[@]}")
  if [ ${#arts[@]} -gt 0 ]; then
    IFS=$'\n' sorted_arts=($(sort <<<"${arts[*]}"))
    unset IFS
    for a in "${sorted_arts[@]}"; do
      echo "  🔹 $a"
      read -ra vers <<< "${art_versions[$a]}"
      IFS=$'\n' sorted_vers=($(sort <<<"${vers[*]}"))
      unset IFS
      for v in "${sorted_vers[@]}"; do
        # [추가됨] 누적된 개수를 가져와서 1,000단위 콤마 포맷(sed) 적용
        count="${art_ver_counts["${a}:${v}"]}"
        formatted_count=$(echo "$count" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
        
        # [수정됨] 버전 정보와 함께 포맷팅된 개수 표출
        echo "    🔸 $v : $formatted_count 개"
        target_components+=("$g:$a:$v")
      done
    done
  else
     echo "  ⚠️ 해당하는 SNAPSHOT 배포 파일이 없습니다."
  fi
  
  ((display_idx++))
done

if [ ${#target_components[@]} -eq 0 ]; then
  echo "🛑 처리할 대상이 없어 종료합니다."
  exit 0
fi

# 4. 남길 개수 및 삭제 확인
keep_count=1

while true; do
  read -p "🎯 남길 배포파일 개수를 입력하세요. (기본값: 1개): " keep_count_input
  keep_count=${keep_count_input:-1}
  
  if [[ "$keep_count" =~ ^[0-9]+$ ]] && [ "$keep_count" -ge 1 ]; then
    while true; do
      read -p "❓ 삭제하시겠습니까? [Y/N]: " confirm_del
      if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
        break 2
      elif [ -z "$confirm_del" ]; then
        read -p "❓ 종료하시겠습니까? [Y/N]: " confirm_exit
        if [[ "$confirm_exit" =~ ^[Yy]$ ]]; then
          exit 0
        fi
      elif [[ "$confirm_del" =~ ^[Nn]$ ]]; then
        echo "🛑 작업을 취소하고 종료합니다."
        exit 0
      else
         continue
      fi
    done
  else
    read -p "❓ 종료하시겠습니까? [Y or any]: " confirm_exit
    if [[ "$confirm_exit" =~ ^[Yy]$ ]]; then
      exit 0
    fi
  fi
done

# 5. 삭제 처리 및 임시 로그 저장
echo "📊 [삭제 진행 결과]"
deleted_any="false"

ensure_directory "$LOG_FILE"

for comp in "${target_components[@]}"; do
  g="${comp%%:*}"
  rest="${comp#*:}"
  a="${rest%%:*}"
  bv="${rest#*:}"
  
  snapshots_json=$(fetch_nexus_snapshots "$g" "$a" "$bv")
  total_count=$(echo "$snapshots_json" | jq '. | length')
  
  if [ "$total_count" -le "$keep_count" ]; then
    echo "🛡️ [$g:$a:$bv] 현재 Snapshot 수($total_count)가 유지 목표치($keep_count)보다 작거나 같아 유지합니다."
    continue
  fi
  
  delete_targets=$(echo "$snapshots_json" | jq -r ". | .[$keep_count:]")
  delete_ids=$(echo "$delete_targets" | jq -r '.[].id')
  
  for id in $delete_ids; do
    real_version=$(echo "$delete_targets" | jq -r ".[] | select(.id==\"$id\") | .version")
    
    curl -s -u "${NEXUS_USER}:${NEXUS_PASS}" -X DELETE "${NEXUS_URL}/service/rest/v1/components/${id}"
    
    info="$g:$a:$real_version"
    echo "🗑️ 삭제됨 -> $info"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 삭제됨: $info (ID: $id)" >> "$LOG_FILE"
    deleted_any="true"
  done
done

# 6. 로그 정보 및 내용 출력
if [ "$deleted_any" == "true" ]; then
  echo ""
  echo "================================================================================"
  echo "📝 [로그 정보]"
  echo " 📌 생성 경로: $LOG_FILE"
  echo " 📃 파일 내용:"
  cat "$LOG_FILE"
  echo "================================================================================"
fi

echo "✨ 모든 작업이 완료되었습니다!"
exit 0
