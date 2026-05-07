#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : gitlab-clone.sh
# @license  : Apache License 2.0
# @since    : 2026-05-07
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/gitlab-clone.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/gitlab-clone.completion' into 
#      etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")

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
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME -u <GitLab URL> -g <그룹 경로> -t <AccessToken> [-d <저장디렉토리>]"
  echo ""
  echo "옵션:"
  echo "  -u, --url       GitLab 서비스 URL (예: https://gitlab.ymtech.co.kr) (필수)"
  echo "  -g, --group     GitLab 대상 그룹 정보 (예: etri-igmoip) (필수)"
  echo "  -t, --token     GitLab API 접근용 Access Token (필수)"
  echo "  -d, --dir       프로젝트를 Clone 할 대상 최상위 디렉토리 (선택, 기본값: 현재 경로)"
  echo "  -h, --help      도움말 출력"
}

##
# 필수 유틸리티(curl, jq, git) 설치 여부를 확인합니다.
#
# @return (설치되지 않은 유틸리티가 있을 경우 오류 메시지와 함께 스크립트 종료)
##
check_dependencies() {
  for cmd in curl jq git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      help "필수 명령어 '$cmd'가 설치되어 있지 않습니다." "$LINENO"
      exit 1
    fi
  done
}

##
# 문자열을 URL 인코딩(URL Encoding)하여 API 호출에 적합하게 변환합니다.
#
# @param $1 {String} 인코딩할 원본 문자열
#
# @return 인코딩된 문자열 출력
##
urlencode() {
  local string="$1"
  local strlen=${#string}
  local encoded=""
  local pos c o
  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}

##
# 대상 그룹이 GitLab 서비스에 실제로 존재하는지(또는 접근 권한이 있는지) 사전 검증합니다.
#
# @param $1 {String} 확인할 대상 그룹의 URL 인코딩된 경로
#
# @return (그룹이 존재하지 않을 경우, 디렉토리를 생성하지 않고 안내 문구 출력 후 즉시 강제 종료)
##
verify_group_exists() {
  local group_id="$1"
  local api_url="${GITLAB_HOST}/api/v4/groups/${group_id}"
  
  # HTTP 상태 코드만 추출하여 존재 여부 확인
  local http_code=$(curl -s -o /dev/null -w "%{http_code}" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$api_url")
  
  if [ "$http_code" -ne 200 ]; then
    echo ""
    echo "🚫 안내: 요청하신 그룹('${RAW_GROUP_PATH}')은 GitLab 서비스에 존재하지 않거나 접근 권한이 없습니다."
    echo "💡 작업을 중단합니다. 대상 그룹 이름을 다시 한번 확인해 주세요. (HTTP 응답 코드: $http_code)"
    echo ""
    # 도움말(help) 함수를 호출하지 않고 스크립트를 즉시 종료합니다.
    exit 1
  fi
}

##
# 특정 GitLab 그룹(또는 하위 그룹) 내의 프로젝트와 서브 그룹을 재귀적으로 탐색하고 조치합니다.
#
# @param $1 {String} GitLab API용 그룹 ID 또는 URL 인코딩된 그룹 경로
# @param $2 {String} 데이터를 저장/생성할 대상 물리 디렉토리 경로
#
# @return (대상 디렉토리 생성 및 하위 프로젝트 git clone 실행)
##
traverse_group() {
  local group_id="$1"
  local current_dir="$2"

  if [ ! -d "$current_dir" ]; then
    mkdir -p "$current_dir" || { help "디렉토리 생성 실패: $current_dir" "$LINENO"; exit 1; }
  fi

  local page=1
  while true; do
    local projects_api="${GITLAB_HOST}/api/v4/groups/${group_id}/projects?per_page=100&page=${page}&include_subgroups=false"
    local res=$(curl -s --fail -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$projects_api")
    
    if [ -z "$res" ]; then break; fi
    local count=$(echo "$res" | jq -r '. | length')
    if [ "$count" -eq 0 ]; then break; fi

    echo "$res" | jq -c '.[] | {path: .path, http_url_to_repo: .http_url_to_repo}' | while read -r project; do
      local p_path=$(echo "$project" | jq -r '.path')
      local p_url=$(echo "$project" | jq -r '.http_url_to_repo')
      local target_path="${current_dir}/${p_path}"

      if [ ! -d "$target_path" ]; then
        echo "[Clone] $p_path 프로젝트 복제 중... -> $target_path"
        local auth_url=$(echo "$p_url" | sed -e "s|http://|http://oauth2:${GITLAB_TOKEN}@|" -e "s|https://|https://oauth2:${GITLAB_TOKEN}@|")
        git clone "$auth_url" "$target_path"
      else
        echo "[Skip] 이미 존재하는 프로젝트입니다: $target_path"
      fi
    done
    ((page++))
  done

  page=1
  while true; do
    local subgroups_api="${GITLAB_HOST}/api/v4/groups/${group_id}/subgroups?per_page=100&page=${page}"
    local res=$(curl -s --fail -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$subgroups_api")
    
    if [ -z "$res" ]; then break; fi
    local count=$(echo "$res" | jq -r '. | length')
    if [ "$count" -eq 0 ]; then break; fi

    echo "$res" | jq -c '.[] | {id: .id, path: .path}' | while read -r subgroup; do
      local sub_id=$(echo "$subgroup" | jq -r '.id')
      local sub_path=$(echo "$subgroup" | jq -r '.path')
      local next_dir="${current_dir}/${sub_path}"

      echo "[Group] 서브 그룹 진입: $sub_path"
      traverse_group "$sub_id" "$next_dir"
    done
    ((page++))
  done
}

##
# 입력받은 파라미터를 파싱하고 검증합니다.
#
# @param $@ {Array} 스크립트 실행 시 전달된 전체 파라미터
#
# @return (변수 할당 및 필수 파라미터 누락 시 명확한 도움말 출력 후 종료)
##
parse_arguments() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -u|--url) TARGET_URL="$2"; shift ;;
      -g|--group) TARGET_GROUP="$2"; shift ;;
      -t|--token) GITLAB_TOKEN="$2"; shift ;;
      -d|--dir) TARGET_DIR="$2"; shift ;;
      -h|--help) help; exit 0 ;;
      *) help "알 수 없는 옵션입니다: $1" "$LINENO"; exit 1 ;;
    esac
    shift
  done

  local missing_params=""
  
  if [ -z "$TARGET_URL" ]; then
    missing_params+="-u/--url(GitLab 서비스 URL) "
  fi
  if [ -z "$TARGET_GROUP" ]; then
    missing_params+="-g/--group(대상 그룹 정보) "
  fi
  if [ -z "$GITLAB_TOKEN" ]; then
    missing_params+="-t/--token(Access Token) "
  fi

  if [ ! -z "$missing_params" ]; then
    help "다음 필수 파라미터가 입력되지 않았습니다: $missing_params" "$LINENO"
    exit 1
  fi

  if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)"
  fi

  TARGET_URL="${TARGET_URL%/}"
}

# 메인 실행 흐름
check_dependencies
parse_arguments "$@"

GITLAB_HOST="$TARGET_URL"
RAW_GROUP_PATH="$TARGET_GROUP"
ENCODED_GROUP_PATH=$(urlencode "$RAW_GROUP_PATH")

# [핵심 변경점] 디렉토리를 생성하기 전에, GitLab 서비스에 해당 그룹이 존재하는지 철저히 사전 검증합니다.
verify_group_exists "$ENCODED_GROUP_PATH"

ROOT_CLONE_DIR="${TARGET_DIR}/${RAW_GROUP_PATH}"

echo "========================================="
echo "GitLab Host  : $GITLAB_HOST"
echo "Group Path   : $RAW_GROUP_PATH"
echo "Target Dir   : $TARGET_DIR"
echo "Clone Dir    : $ROOT_CLONE_DIR"
echo "========================================="

traverse_group "$ENCODED_GROUP_PATH" "$ROOT_CLONE_DIR"

echo "작업이 성공적으로 완료되었습니다."
exit 0

