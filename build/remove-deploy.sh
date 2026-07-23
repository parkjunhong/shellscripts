#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : remove deploy directories.
# @license  : Apache License 2.0
# @since    : 2026-07-14
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/remove-deploy.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/remove-deploy.sh' into /etc/bashrc for all users.
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

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

##
# 하단에 진행률 상태 표시줄을 렌더링합니다.
#
# @param $1 {number} 현재 처리한 디렉토리 개수
# @param $2 {number} 전체 대상 디렉토리 개수
# @param $3 {number} 삭제된 deploy 디렉토리 개수
#
# @return (표준 출력으로 진행률 업데이트)
##
draw_progress() {
  local current="$1"
  local total="$2"
  local deleted="$3"
  local percent="0.00"

  if [[ "$total" -gt 0 ]]; then
    # awk를 활용하여 소수점 2자리까지 정확하게 비율 계산
    percent=$(awk -v c="$current" -v t="$total" 'BEGIN {printf "%.2f", (c/t)*100}')
  fi

  # \r로 줄의 맨 앞으로 이동 후 \033[K로 현재 커서 이후를 지우고 진행률 표시
  printf "\r\033[K⏳ [진행률: %6s%%] | %d / %d / %d" "$percent" "$total" "$current" "$deleted"
}

##
# 작업 대상 정보를 사전 수집한 후, 화면을 활용해 실시간 상태 및 진행률을 표기합니다.
#
# @param $1 {string} 탐색을 시작할 기준 디렉토리 경로
#
# @return (처리 결과 실시간 출력 및 최종 요약 정보)
##
clean_deploy_dirs() {
  local target_dir="$1"

  if [[ ! -d "${target_dir}" ]]; then
    die "입력된 디렉토리 경로를 찾을 수 없습니다: ${target_dir}"
  fi

  # 모든 경로를 절대경로로 변환
  local abs_target_dir
  abs_target_dir=$(realpath "${target_dir}")

  echo "🔍 [1/2] 작업대상 디렉토리 정보를 수집 중입니다... (기준: ${abs_target_dir})"
  
  local targets=()
  # find 결과의 절대경로를 배열로 수집
  while IFS= read -r -d '' dir; do
    targets+=("$dir")
  done < <(find "${abs_target_dir}" -type d \( -exec test -d "{}/.git" \; -o -exec test -f "{}/.project" \; \) -print0 -prune)

  local total="${#targets[@]}"
  if [[ "$total" -eq 0 ]]; then
    echo "🛑 조건(.git 또는 .project 존재)을 만족하는 디렉토리를 찾지 못했습니다."
    return
  fi

  echo "🚀 [2/2] 총 ${total}개의 프로젝트 디렉토리를 발견했습니다. 처리를 시작합니다."
  echo

  local current=0
  local deleted=0

  # 최초 상태 진행률 바 출력
  draw_progress "$current" "$total" "$deleted"

  for dir in "${targets[@]}"; do
    current=$((current + 1))
    local deploy_path="${dir}/deploy"
    
    # 덮어쓰기 위해 \r 및 줄을 지운 뒤 개행하여 로그를 남김
    if [[ -d "${deploy_path}" ]]; then
      rm -rf "${deploy_path}"
      deleted=$((deleted + 1))
      printf "\r\033[K🗑️  [삭제완료] %s ('deploy' 삭제됨)\n" "${dir}"
    else
      printf "\r\033[K✅ [유지됨] %s ('deploy' 없음)\n" "${dir}"
    fi
    
    # 로그 출력으로 인해 줄이 내려갔으므로 가장 아래에 다시 진행률 바 렌더링
    draw_progress "$current" "$total" "$deleted"
  done

  # 작업 완료 후 진행률 바 아래로 줄 바꿈
  echo
  echo
  echo "================================================================================"
  echo "📊 [작업 결과 요약]"
  echo "================================================================================"
  printf " 🔹 탐색된 전체 프로젝트 디렉토리 개수 : %d 개\n" "$total"
  printf " 🔹 'deploy' 디렉토리 삭제 개수        : %d 개\n" "$deleted"
  echo "================================================================================"
}

TARGET_DIRECTORY=""

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

if [[ -z "${TARGET_DIRECTORY}" ]]; then
  die "-d 또는 --directory 옵션을 사용하여 디렉토리 경로를 입력해야 합니다."
fi

clean_deploy_dirs "${TARGET_DIRECTORY}"

exit 0
