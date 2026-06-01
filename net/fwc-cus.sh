#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : firewall-cmd zone info wrapper.
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
  echo "  --zone=<zone 이름>   정보를 조회할 zone 이름 (여러 번 사용 가능)"
  echo "  --active-zone        활성화된 모든 zone의 정보 조회"
  echo "  --reload             방화벽 설정 리로드 및 활성화된 zone(active-zone) 정보 조회"
  echo "  -h, --help           도움말 출력"
}

##
# firewall-cmd 명령어가 존재하는지, firewalld가 실행 중인지 확인합니다.
#
# @param (없음)
#
# @return (없음, 조건 불만족 시 스크립트 종료)
##
check_firewalld() {
  if ! command -v firewall-cmd >/dev/null 2>&1; then
    help "firewall-cmd 명령어를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi

  # sudo 없이 현재 상태 조회가 가능한지 확인, 안되면 sudo 사용 여부를 체크
  if ! firewall-cmd --state >/dev/null 2>&1 && ! sudo firewall-cmd --state >/dev/null 2>&1; then
    help "firewalld 서비스가 실행 중이 아닙니다." "$LINENO"
    exit 1
  fi
}

##
# 시스템에서 현재 활성화된 zone의 목록을 추출합니다.
#
# @param (없음)
#
# @return (활성화된 zone 이름 목록을 띄어쓰기로 구분하여 출력)
##
get_active_zones() {
  sudo firewall-cmd --get-active-zones | awk '!/^[ \t]/{print $1}'
}

##
# 특정 zone에 대해 --list-all 정보를 출력합니다.
#
# @param $1 {string} 조회할 zone 이름
#
# @return (해당 zone의 list-all 상세 정보 출력)
##
print_zone_info() {
  local zone_name="$1"
  echo "================================================================================"
  echo "🛡️  Zone: $zone_name"
  echo "================================================================================"
  
  if ! sudo firewall-cmd --zone="$zone_name" --list-all 2>/dev/null; then
    echo "⚠️  '$zone_name' zone을 찾을 수 없거나 정보를 조회할 수 없습니다."
  fi
  echo ""
}

# -----------------------------------------------------------------------------
# 메인 로직 시작
# -----------------------------------------------------------------------------

# 사전 검증
check_firewalld

TARGET_ZONES=()
ACTIVE_ZONE_FLAG="false"
RELOAD_FLAG="false"

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --zone=*)
      TARGET_ZONES+=("${1#*=}")
      shift
      ;;
    --active-zone)
      ACTIVE_ZONE_FLAG="true"
      shift
      ;;
    --reload)
      RELOAD_FLAG="true"
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      help "알 수 없는 옵션입니다: $1" "$LINENO"
      exit 1
      ;;
  esac
done

if [ ${#TARGET_ZONES[@]} -eq 0 ] && [ "$ACTIVE_ZONE_FLAG" == "false" ] && [ "$RELOAD_FLAG" == "false" ]; then
  help "조회할 대상(--zone=<이름> 또는 --active-zone) 또는 동작(--reload)을 입력해 주세요." "$LINENO"
  exit 1
fi

# 1. --reload 처리 (방화벽 설정 리로드 및 active-zone 강제 활성화)
if [ "$RELOAD_FLAG" == "true" ]; then
  echo "🔄 Reloading firewall list..."
  sudo firewall-cmd --reload
  echo ""
  
  # reload 시 항상 활성화된 zone 정보를 제공하도록 플래그 켜기
  ACTIVE_ZONE_FLAG="true"
fi

# 중복 조회를 방지하기 위해 연관 배열(Associative Array) 사용
declare -A UNIQUE_ZONES

# 2. --active-zone 처리 (RELOAD_FLAG에 의해 자동으로 실행될 수 있음)
if [ "$ACTIVE_ZONE_FLAG" == "true" ]; then
  active_zones=$(get_active_zones)
  for z in $active_zones; do
    UNIQUE_ZONES["$z"]=1
  done
fi

# 3. --zone 처리
for z in "${TARGET_ZONES[@]}"; do
  UNIQUE_ZONES["$z"]=1
done

# 4. 결과 출력 (알파벳 순으로 정렬하여 출력)
if [ ${#UNIQUE_ZONES[@]} -eq 0 ]; then
  echo "⚠️ 조회할 대상 zone이 없습니다."
  exit 0
fi

mapfile -t sorted_zones < <(printf "%s\n" "${!UNIQUE_ZONES[@]}" | sort)

for z in "${sorted_zones[@]}"; do
  print_zone_info "$z"
done

echo "✨ 모든 작업이 완료되었습니다!"
exit 0
