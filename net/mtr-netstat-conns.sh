#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-07-27
# @desc     : support RHEL 7+, Oracle Linux 7+, Ubuntu 16.04+, RockyOS 8+, CentOS 7+
# @installation : 
#   1. insert 'source <path>/mtr-netstat-conns.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/mtr-netstat-conns.sh' into /etc/bashrc for all users.
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
  echo "사용법: ./$FILENAME [옵션]"
  echo ""
  echo "[옵션 (Options)]"
  echo "  -[문자열]     netstat 명령어에 전달할 옵션 지정 (기본값: -napt)"
  echo "  --filter      조회 결과 필터링 문자열 (파이프(|) 구분자로 다중 조건 지정 가능)"
  echo "                [사용 예시]"
  echo "                1) 단일 포트 및 상태 : --filter \"8080 | ESTABLISHED\""
  echo "                2) 정규식 다중 포트  : --filter \"-E ':80|:443' | ESTABLISHED\""
  echo "                3) 특정 조건 제외    : --filter \"-v TIME_WAIT | -v 127.0.0.1\""
  echo "                4) 프로세스 리슨 확인: --filter \"LISTEN | java\""
  echo "                5) 복합망 트래픽 추적: --filter \"192.168.1.50 | nginx | ESTABLISHED\""
  echo "  --sort        정렬 기준 및 방식 지정 (local, remote, pid)"
  echo "                - 오름차순(기본): local, local/a, remote/a, pid/a"
  echo "                - 내림차순      : local/d, remote/d, pid/d"
  echo "  -h, --help    이 도움말을 표시하고 종료합니다."
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  help "" ""
  exit 0
fi

OPTIONS="-napt"
FILTERS=""
SORTER="awk '{print \$4\"@\"\$5}'"
SORT_TYPE="local"
SORT_ORDER="a"

while [ ! -z "${1:-}" ]; do
  case "$1" in
    -[a-zA-Z]*)
      OPTIONS="$1"
      ;;
    --filter)
      shift
      FILTERS="${1:-}"
      ;;
    --sort)
      shift
      raw_sort="${1:-}"
      SORT_TYPE="${raw_sort%/*}"
      SORT_ORDER="${raw_sort#*/}"
      
      # '/'가 포함되지 않아 TYPE과 ORDER가 동일할 경우 기본값(a) 할당
      if [[ "$SORT_TYPE" == "$SORT_ORDER" ]]; then
        SORT_ORDER="a"
      fi

      case "$SORT_TYPE" in
        local)
          SORTER="awk '{print \$4\"@\"\$5}'"
          ;;
        remote)
          SORTER="awk '{print \$5\"@\"\$4}'"
          ;;
        pid)
          SORTER="awk '{print \$7\"@\"\$4}'"
          ;;
        *)
          echo "잘못된 정렬 기준입니다. [local|remote|pid] 중에 1개를 선택하세요."
          exit 1
          ;;
      esac
      
      case "$SORT_ORDER" in
        a|d) ;;
        *)
          echo "잘못된 정렬 방식입니다. [/a|/d] 중에 1개를 선택하세요."
          exit 1
          ;;
      esac
      ;;
    *)
      echo "모르는 입력...$1"
      ;;
  esac
  shift
done

##
# parse_line
# 주어진 문자열에서 작은/큰 따옴표 안의 파이프(|)는 무시하고,
# 따옴표 밖의 파이프만 구분자로 사용하여 배열 filters에 담습니다.
#
# @param $1 {string} 파이프(|)로 구분된 필터링 대상 문자열
#
# @return 없음 (전역 배열 filters 에 결과가 저장됨)
##
parse_line() {
  local str="$1"

  filters=()

  local current=""
  local in_squote=0
  local in_dquote=0

  local len=${#str}
  local i char

  for ((i=0; i<len; i++)); do
    char="${str:i:1}"

    if [[ $in_squote -eq 0 && $in_dquote -eq 0 && "$char" == "|" ]]; then
      filters+=( "$current" )
      current=""
      continue
    fi

    if [[ "$char" == "'" && $in_dquote -eq 0 ]]; then
      if [[ $in_squote -eq 0 ]]; then
        in_squote=1
      else
        in_squote=0
      fi
    elif [[ "$char" == "\"" && $in_squote -eq 0 ]]; then
      if [[ $in_dquote -eq 0 ]]; then
        in_dquote=1
      else
        in_dquote=0
      fi
    fi

    current+="$char"
  done

  if [[ -n "$current" ]]; then
    filters+=( "$current" )
  fi
}

CMD="sudo netstat $OPTIONS | grep -v 'Active Internet connections' | grep -v 'Proto Recv-Q Send-Q'"
if [ ! -z "$FILTERS" ]; then
  parse_line "$FILTERS"
  for filter in "${filters[@]}"; do
    CMD="$CMD | grep $(echo "$filter" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  done
fi

declare -A CONNS
LOCAL_REMOTE=()

KEY_CMD="echo \$con | $SORTER"

while IFS= read -r con; do
  if [[ -z "$con" ]]; then
    continue
  fi
  key=$(eval "$KEY_CMD" || true)
  if [[ -n "$key" ]]; then
    LOCAL_REMOTE+=( "$key" )
    CONNS["$key"]="$con"
  fi
done < <(eval "$CMD" || true)

echo "  #   Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name"
echo "------------------------------------------------------------------------------------------------------"

if [[ ${#LOCAL_REMOTE[@]} -eq 0 ]]; then
  echo "  (조회된 네트워크 연결 정보가 없습니다.)"
  exit 0
fi

# 정렬 방향에 따른 sort 명령어 동적 할당
SORT_CMD="sort"
if [[ "$SORT_ORDER" == "d" ]]; then
  SORT_CMD="sort -r"
fi

num=0
while IFS= read -r key; do
  if [[ -z "$key" ]]; then
    continue
  fi
  num=$((num + 1))
  printf "[%3s] %s\n" $(printf "%'d" "$num" ) "${CONNS[$key]:-}"
done < <(
  printf "%s\n" "${LOCAL_REMOTE[@]}" | awk -v stype="$SORT_TYPE" -F '[@:]' '
  {
    if (stype == "pid") {
      # PID 추출 및 숫자 강제 변환 후 7자리 패딩
      split($1, pid_arr, "/");
      pid_val = pid_arr[1];
      if (pid_val == "-" || pid_val == "") pid_val = 9999999;
      else pid_val = pid_val + 0;
      printf("%07d %s\n", pid_val, $0);
    } else {
      # IP 패딩 로직
      split($1, src_ip, ".");
      split($3, dest_ip, ".");
      printf("%03d%03d%03d%03d:%05d@%03d%03d%03d%03d:%05d %s\n",
        src_ip[1], src_ip[2], src_ip[3], src_ip[4], $2,
        dest_ip[1], dest_ip[2], dest_ip[3], dest_ip[4], $4,
        $0)
    }
  }' | eval "$SORT_CMD" | cut -d' ' -f2 || true
)

exit 0
