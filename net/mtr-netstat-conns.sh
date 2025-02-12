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

CMD="netstat $OPTIONS"
if [ ! -z "$FILTERS" ]; then
    CMD="$CMD | $FILTERS"
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

#exit 0

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

