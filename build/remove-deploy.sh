#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : remove deploy directories.
# @license  : Apache License 2.0
# @since    : 2026-07-13
# @desc     : support RHEL 7+, Oracle Linux 7+, Ubuntu 16.04+, RockyOS 8+
# @installation : 
#   1. insert 'source <path>/remove-deploy.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/remove-deploy.sh' into 
#      etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

##
# 스크립트 사용 방법 및 오류 원인을 출력합니다.
#
# @param $1 {string} (오류 발생 시 원인 메시지)
# @param $2 {string} (오류 발생 라인)
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
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME -d <디렉토리경로> [옵션]"
  echo "옵션:"
  echo "  -d, --directory <경로>    탐색을 시작할 기준 디렉토리 경로 (필수)"
  echo "  -h, --help                이 도움말을 표시하고 종료합니다."
}

##
# 에러 메시지를 출력하고 스크립트를 종료합니다.
#
# @param $1 {string} (출력할 메시지)
#
# @return (표준 에러로 출력 후 exit 1)
##
die() {
  help "[ERROR] $*" "$LINENO"
  exit 1
}

# 에러 발생 시 도움말 함수 호출 트랩
trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

##
# 주어진 디렉토리를 탐색하여 조건을 만족하는 대상과 삭제된 deploy 정보를 집계 및 출력합니다.
#
# @param $1 {string} 탐색을 시작할 기준 디렉토리 경로
#
# @return (처리 결과 로그 및 통계 정보 출력)
##
clean_deploy_dirs() {
  local target_dir="$1"

  # 입력 데이터로 사용되는 디렉토리 경로 존재 검증
  if [[ ! -d "${target_dir}" ]]; then
    die "입력된 디렉토리 경로를 찾을 수 없습니다: ${target_dir}"
  fi

  printf '[INFO] [%s] 디렉토리를 기준으로 탐색을 시작합니다.\n' "${target_dir}"

  local matched_dirs=()
  local deleted_dirs=()

  # find 명령어의 -print0와 read -d ''를 사용하여 
  # 띄어쓰기 및 특수문자가 포함된 경로를 안전하게 배열로 처리합니다.
  while IFS= read -r -d '' dir; do
    matched_dirs+=("$dir")
    
    local deploy_path="${dir}/deploy"
    if [[ -d "${deploy_path}" ]]; then
      # 중간 경로가 없는 경우를 대비한 안전한 삭제
      rm -rf "${deploy_path}"
      deleted_dirs+=("${deploy_path}")
    fi
  done < <(find "${target_dir}" -type d \( -exec test -d "{}/.git" \; -o -exec test -f "{}/.project" \; \) -print0 -prune)

  echo
  echo "================================================================================"
  echo "[작업 결과 요약]"
  echo "================================================================================"
  printf " - 탐색된 전체 프로젝트 디렉토리 개수 : %d 개\n" "${#matched_dirs[@]}"
  printf " - 'deploy' 디렉토리 삭제 개수        : %d 개\n" "${#deleted_dirs[@]}"
  
  if [[ ${#deleted_dirs[@]} -gt 0 ]]; then
    echo
    echo "[삭제된 'deploy' 디렉토리 정보]"
    for del_dir in "${deleted_dirs[@]}"; do
      printf " - %s\n" "${del_dir}"
    done
  fi
  echo "================================================================================"
}

TARGET_DIRECTORY=""

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      help "" ""
      exit 0
      ;;
    -d|--directory)
      TARGET_DIRECTORY="$2"
      shift 2
      ;;
    -*)
      die "알 수 없는 옵션입니다: $1"
      ;;
    *)
      die "잘못된 인자 전달입니다: $1"
      ;;
  esac
done

# 필수 파라미터 확인
if [[ -z "${TARGET_DIRECTORY}" ]]; then
  die "-d 또는 --directory 옵션을 사용하여 디렉토리 경로를 입력해야 합니다."
fi

clean_deploy_dirs "${TARGET_DIRECTORY}"

exit 0

