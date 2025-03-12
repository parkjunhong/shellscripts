#!/usr/bin/env bash

OPTIONS="-napt"
FILTERS=""
SORTER="awk '{print \$4\"@\"\$5}'"
while [ ! -z "$1" ];do
    case "$1" in
        -[a-zA-Z]*)
            OPTIONS="$1"
            ;;
        --filter)
            shift
            FILTERS="$1"
            ;;
        --sort)
            shift
            case "$1" in
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
                echo "잘못된 정렬 기준입니다. [local|remote] 중에 1개를 선택하세요."
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
# - 주어진 문자열에서 작은/큰 따옴표 안의 파이프(|)는 무시하고,
#   따옴표 밖의 파이프만 구분자로 사용하여 배열 filters에 담음.
#
# @param $1 {string} 파싱 대상 문자열
#
# @return 없음. (전역 배열 filters 에 결과를 저장)
##
parse_line() {
  local str="$1"

  # 전역 배열 초기화
  filters=()

  local current=""
  local in_squote=0
  local in_dquote=0

  local len=${#str}
  local i char

  for ((i=0; i<len; i++)); do
    char="${str:i:1}"

    # 파이프 구분자인지 확인 (따옴표 밖일 때만)
    if [[ $in_squote -eq 0 && $in_dquote -eq 0 && "$char" == "|" ]]; then
      # 지금까지 누적된 current를 하나의 토큰으로 추가
      filters+=( "$current" )
      current=""
      continue
    fi

    # 작은따옴표 토글(큰따옴표 안이 아닐 때만)
    if [[ "$char" == "'" && $in_dquote -eq 0 ]]; then
      # 따옴표 상태 토글
      if [[ $in_squote -eq 0 ]]; then
        in_squote=1
      else
        in_squote=0
      fi
    # 큰따옴표 토글(작은따옴표 안이 아닐 때만)
    elif [[ "$char" == "\"" && $in_squote -eq 0 ]]; then
      if [[ $in_dquote -eq 0 ]]; then
        in_dquote=1
      else
        in_dquote=0
      fi
    fi

    # 현재 문자(따옴표 포함)를 current에 누적
    current+="$char"
  done

  # 마지막으로 누적된 문자열을 배열에 추가
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

# connection info
declare -A CONNS
# local & remote info
LOCAL_REMOTE=()

KEY_CMD="echo \$con | $SORTER"
while IFS= read con;
do
    key=$(eval $KEY_CMD)
    LOCAL_REMOTE+=( $key )
    CONNS["$key"]="$con"
done < <(eval $CMD)


# 출력 데이터 헤더
echo "  #   Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name"
echo "------------------------------------------------------------------------------------------------------"

# 배열 데이터를 정렬하는 방법
num=0
while IFS= read key;
do
    ((num++))
    printf "[%3s] %s\n" $(printf "%'d" $num ) "${CONNS[$key]}"
done < <(
            printf "%s\n" "${LOCAL_REMOTE[@]}" | awk -F '[@:]' '
            {
                split($1, src_ip, ".");
                split($3, dest_ip, ".");
                printf("%03d%03d%03d%03d:%05d@%03d%03d%03d%03d:%05d %s\n",
                    src_ip[1], src_ip[2], src_ip[3], src_ip[4], $2,
                    dest_ip[1], dest_ip[2], dest_ip[3], dest_ip[4], $4,
                    $0)
            }' | sort | cut -d' ' -f2
        )

exit 0


