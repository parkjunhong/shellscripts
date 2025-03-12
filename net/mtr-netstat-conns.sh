#!/usr/bin/env bash

#set -e

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

CMD="sudo netstat $OPTIONS | grep -v 'Active Internet connections' | grep -v 'Proto Recv-Q Send-Q'"
if [ ! -z "$FILTERS" ]; then
    IFS='|' read -ra filter_arr <<< "$FILTERS"
    for filter in "${filter_arr[@]}"; do
      CMD="$CMD | grep $(echo "$filter" | xargs)"
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

