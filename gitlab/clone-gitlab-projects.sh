#!/usr/bin/env bash

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
  echo "사용법: ./$FILENAME -g <그룹 경로> [-d <저장디렉토리>]"
  echo ""
  echo "옵션:"
  echo "  -g, --group     GitLab 대상 그룹 정보 (필수)"
  echo "  -d, --dir       프로젝트를 Clone 할 대상 최상위 디렉토리 (선택, 기본값: 현재 경로)"
  echo "  -h, --help      도움말 출력"
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
      -g|--group) TARGET_GROUP="$2"; shift ;;
      -d|--dir) TARGET_DIR="$2"; shift ;;
      -h|--help) help; exit 0 ;;
      *) help "알 수 없는 옵션입니다: $1" "$LINENO"; exit 1 ;;
    esac
    shift
  done

  # 누락된 파라미터를 저장할 변수 초기화
  local missing_params=""

  if [ -z "$TARGET_GROUP" ]; then
    missing_params+="-g/--group(대상 그룹 정보) "
  fi

  # 누락된 파라미터가 하나라도 있다면 명확히 알려주고 종료
  if [ ! -z "$missing_params" ]; then
    help "다음 필수 파라미터가 입력되지 않았습니다: $missing_params" "$LINENO"
    exit 1
  fi

  if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)"
  fi
}

parse_arguments $@

# Gitlab URL (예: https://gitlab.your-company.com)
GITLAB_URL=""
# Gitlab Personal Access Token
GITLAB_PAT=""
# gitlab-clone.sh -u <GitLab URL> -g <그룹 경로> -t <AccessToken> [-d <저장디렉토리>]
gitlab-clone.sh -u "${GITLAB_URL}" -t "${GITLAB_PAT}" $@

exit 0
