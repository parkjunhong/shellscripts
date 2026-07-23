#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : calculate a directory size.
# @license  : Apache License 2.0
# @since    : 2026-07-14
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/disk-size.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/disk-size.sh' into /etc/bashrc for all users.
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
  if [ ! -z "${1:-}" ];
  then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" $func
      idx=$((idx + 1))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME <directory> -s[a|d]r"
  echo ""
  echo "[옵션]"
  echo " -s: 정렬 (Sort)."
  echo "    + a: 오름차순 (asc)"
  echo "    + d: 내림차순 (desc)"
  echo " -r: 하위 디렉토리 반복 탐색 활성화 (Recursive)."
  echo " -h, --help: 이 도움말을 표시하고 종료합니다."
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

DIR=""
RECUR=0
SORT="N"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -*)
      if [[ "-" == "$1" ]]; then
        help "잘못된 옵션입니다. arg=$1" "$LINENO"
        exit 1
      fi
      
      opt="${1#-}"
      len=${#opt} 
      idx=0
      while [[ $idx -lt $len ]]; do
        case ${opt:${idx}:1} in 
          h)
            help "" ""
            exit 0
            ;;
          r)
            RECUR=1
            ;;
          s)
            if [[ $((idx + 1)) -lt $len ]]; then
              case ${opt:$((idx + 1)):1} in 
                a)
                  SORT="A"
                  idx=$((idx + 1))
                  ;;
                d)
                  SORT="D"
                  idx=$((idx + 1))
                  ;;
                *)
                  ;;
              esac
            fi
            ;;
          *)
            if [[ "$1" == "--help" ]]; then
              help "" ""
              exit 0
            fi
            ;;
        esac
        idx=$((idx + 1))
      done
      ;;
    *)
      DIR="$1"
      ;;
  esac
  shift
done

if [[ -z "${DIR}" ]]; then
  DIR="."
fi

if [[ ! -d "${DIR}" && ! -f "${DIR}" ]]; then
  help "유효하지 않은 디렉토리 또는 파일입니다. input=${DIR}" "$LINENO"
  exit 1
fi

TMP_DIR="/tmp"
TMP_FILE_PREFIX=".disk-size-tmp"
# 이전 임시파일 삭제 (권한 문제 방지를 위해 2>/dev/null 유지)
find "${TMP_DIR}" -maxdepth 1 -name "${TMP_FILE_PREFIX}*" -type f -mmin +1 -exec rm -f {} ';' 2>/dev/null || true

##
# 절대 경로를 반환합니다.
#
# @param $1 {string} 디렉토리 경로
#
# @return (echo: 절대 경로 문자열)
##
abspath(){
  if [[ -d "$1" ]]; then
    (cd "$1" && pwd)
  fi
}

##
# 디렉토리 경로 마지막의 슬래시(/)를 제거합니다.
#
# @param $1 {string} 디렉토리 경로
#
# @return (echo: 정제된 디렉토리 경로)
##
deltailslash(){
  if [[ "$1" == "/" ]]; then
    echo "$1"
  elif [[ -n "$1" && "$1" == */ ]]; then
    echo "${1:0:$((${#1}-1))}"
  else
    echo "$1"
  fi  
}

##
# 사람이 읽을 수 있는 크기를 바이트 단위의 숫자로 변환합니다.
#
# @param $1 {string} du 명령어로 추출된 크기 문자열
#
# @return (echo: 바이트 단위의 크기)
##
tonum(){
  local str
  str=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  
  if [[ -z "$str" ]]; then
    echo "0"
    return
  fi
  
  local len=${#str}
  local unit="${str: -1}"
  local val
  
  # 단위 포함 여부에 따라 안전하게 값 파싱
  if [[ "$unit" =~ [A-Z] ]]; then
    val="${str:0:$((len-1))}"
  else
    unit=""
    val="${str}"
  fi
  
  case ${unit} in
    K) echo "${val}" | awk '{printf "%.2f", $1 * 1024}' ;;
    M) echo "${val}" | awk '{printf "%.2f", $1 * 1024 * 1024}' ;;
    G) echo "${val}" | awk '{printf "%.2f", $1 * 1024 * 1024 * 1024}' ;;
    T) echo "${val}" | awk '{printf "%.2f", $1 * 1024 * 1024 * 1024 * 1024}' ;;
    P) echo "${val}" | awk '{printf "%.2f", $1 * 1024 * 1024 * 1024 * 1024 * 1024}' ;;
    *) echo "${val}" ;;
  esac
}

##
# 파일 크기를 검색하여 정렬하고 포맷팅하여 출력합니다.
#
# @param $1 {string} 탐색 대상 부모 디렉토리
# @param $@ {array} 하위 파일 및 디렉토리 목록
#
# @return (표준 출력으로 포맷팅된 결과 출력)
##
search(){
  local parent="$1"
  shift
  local subfiles=("$@")
  local RST_FORMAT="[%s] %6s %s\n"

  if [[ "${parent}" == "/" ]]; then
    parent=""
  fi  
  
  local __tmpfile__
  __tmpfile__=$(mktemp "${TMP_DIR}/${TMP_FILE_PREFIX}-XXXXXX")

  for file in "${subfiles[@]}"; do  
    local path="${parent}/${file}"
    
    local du_out
    if du_out=$(du -sh "$path" 2>/dev/null); then
      local raw_size="${du_out%%[[:space:]]*}"
      local raw_path="${path}"
      
      local sort_val
      sort_val=$(tonum "$raw_size")
      
      # 탭(\t)으로 구분하여 공백이 있는 파일명도 안전하게 정렬
      printf "%030.1f\t%s\t%s\n" "$sort_val" "$raw_size" "$raw_path" >> "${__tmpfile__}"
    fi
  done
  
  local __cmd__
  case ${SORT} in
    A) __cmd__="sort -n -t$'\t' -k1,1 \"${__tmpfile__}\"" ;;
    D) __cmd__="sort -nr -t$'\t' -k1,1 \"${__tmpfile__}\"" ;;
    N) __cmd__="cat \"${__tmpfile__}\"" ;;
    *)
      help "잘못된 정렬 타입입니다. value=${SORT}" "$LINENO"
      exit 1
      ;;
  esac

  eval "${__cmd__}" | while IFS=$'\t' read -r sort_val raw_size path_val; do
    if [[ -f "${path_val}" ]]; then
      printf "$RST_FORMAT" "f" "${raw_size}" "${path_val}"
    elif [[ -d "${path_val}" ]]; then
      printf "$RST_FORMAT" "d" "${raw_size}" "${path_val}"
    fi
  done

  rm -f "${__tmpfile__}"
}

DIR=$(deltailslash "${DIR}")

SUB_FILES=()
find_args=( "-mindepth" "1" )
# -r 옵션이 없으면 maxdepth를 1로 제한하여 1뎁스만 탐색
if [[ "$RECUR" -eq 0 ]]; then
  find_args+=( "-maxdepth" "1" )
fi

# 공백이 포함된 파일명과 재귀 탐색 결과를 온전히 배열로 수집
while IFS= read -r -d '' file; do
  rel_path="${file#${DIR}/}"
  SUB_FILES+=("${rel_path}")
done < <(find "${DIR}" "${find_args[@]}" -print0 2>/dev/null)

if [[ ${#SUB_FILES[@]} -gt 0 ]]; then
  search "${DIR}" "${SUB_FILES[@]}"
else
  echo "[INFO] 탐색할 대상 파일이나 디렉토리가 없습니다."
fi

exit 0
