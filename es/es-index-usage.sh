#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : search total usage size of indices.
# @license: Apache License 2.0
# @since  : 2023-10-25
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7
# @completion: es-index-usages_completion
#            1. insert 'source <path>/es-index-usage_completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# @requirement: 'jq' for parsing elasticsearch response.
# =======================================
FILENAME=$(basename $0)

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
    echo "Usage:"
    echo "./es-index-usage.sh -i <ip> -p <port> -x <indices>"
    echo
    echo "Options:"
    echo " -i | --ip     : IP address of Elasticsearch"
    echo " -p | --port   : Port of Elasticsearch"
    echo " -x | --indices: Index list of Elasticsearch."
    echo "                 indices separated by comma(,)."
    echo " -h | --help   : show help messages, like this."
}

ES_DATA_UNITS=( b kb mb gb tb )

ES_IP=""
ES_PORT=""
ES_INDICES=""
ES_IDX_PREFIX=""
ES_DATA_UNIT="gb"
ES_DATA_UNIT_T="tb"

while [ ! -z "$1" ];
do
    case "$1" in
        -h | --help)
            help
            exit 0
            ;;
        -i | --ip)
            shift
            ES_IP="$1"
            ;;
        -p | --port)
            shift
            ES_PORT="$1"
            ;;
        -x | --indices)
            shift
            ES_INDICES=( $(echo $1 | sed 's/,/ /g') )
            ;;
        -u | --unit)
            shift
            case "$1" in
                b)
                    ES_DATA_UNIT="$1"
                    ES_DATA_UNIT_T="kb"
                    ;;
                kb)
                    ES_DATA_UNIT="$1"
                    ES_DATA_UNIT_T="mb"
                    ;;
                mb)
                    ES_DATA_UNIT="$1"
                    ES_DATA_UNIT_T="gb"
                    ;;
                gb)
                    ES_DATA_UNIT="$1"
                    ES_DATA_UNIT_T="tb"
                    ;;
                *)
                    ES_DATA_UNIT="gb"
                    ES_DATA_UNIT_T="tb"
                    ;;
            esac
            ;;
        -ip | --index-prefix)
            shift
            ES_IDX_PREFIX="$1"
            ;;
        *)
            ;;
    esac
    shift
done

if [ -z $ES_IP ] || [ -z $ES_PORT ] || [ -z $ES_INDICES ];then
    help "입력값이 잘못되었습니다." $LINENO

    echo "es_ip     : $ES_IP"
    echo "es_port   : $ES_PORT"
    echo "es_indices: $ES_INDICES"

    exit 0
fi

# @param $1 {string} es ip
# @param $2 {num} es port
# @param $3 {string} index name
function calc(){
    local _tb=0
    local _gb=0
    local _mb=0
    local _kb=0
    local _b=0

    # index 크기
    local _curl_size="curl --silent 'http://$1:$2/_cat/indices?format=json&index=$3' | jq -r '.[][\"store.size\"]'"
    while IFS= read -r _size;
    do
        _unit=$( echo $_size | sed -e "s/[0-9.]//g" 2>/dev/null )
        _value=$( echo $_size | sed "s/$_unit//g" 2>/dev/null  )
        case "$_unit" in
            b)
                _b=$( echo "scale=2; $_b + $_value" | bc )
                ;;
            kb)
                _kb=$( echo "scale=2; $_kb + $_value" | bc )
                ;;
            mb)
                _mb=$( echo "scale=2; $_mb + $_value" | bc )
                ;;
            gb)
                _gb=$( echo "scale=2; $_gb + $_value" | bc )
                ;;
            tb)
                _tb=$( echo "scale=2; $_tb + $_value" | bc )
                ;;
            *)
                ;;
        esac
    done <<< "$( eval $_curl_size)"

    # index 크기 계산
    local _tb_n=0
    local _gb_n=0
    local _mb_n=0
    local _kb_n=0
    local _b_n=0

    case "$ES_DATA_UNIT" in
        b)
            _b_n=1
            _kb_n=1000
            _mb_n=1000000
            _gb_n=1000000000
            _tb_n=1000000000000
            ;;
        kb)
            _b_n=0.001
            _kb_n=1
            _mb_n=1000
            _gb_n=1000000
            _tb_n=1000000000
            ;;
        mb)
            _b_n=0.000001
            _kb_n=0.001
            _mb_n=1
            _gb_n=1000
            _tb_n=1000000
            ;;
        gb)
            _b_n=0.000000001
            _kb_n=0.000001
            _mb_n=0.001
            _gb_n=1
            _tb_n=1000
            ;;
        tb)
            _b_n=0.000000000001
            _kb_n=0.000000001
            _mb_n=0.000001
            _gb_n=0.001
            _tb_n=1
        ;;
    esac

    _sum=$( echo "scale=6; $_tb*$_tb_n + $_gb*$_gb_n + $_mb*$_mb_n + $_kb*$_kb_n + $_b*$_b_n" | bc)

    # index 개수
    local _curl_idx_size="curl --silent 'http://$1:$2/_cat/indices?format=json&index=$3' | jq 'length'"

    echo $_sum","$( eval $_curl_idx_size )
}

echo "[[ each index of ]]"

index_len=0
for _index in ${ES_INDICES[@]};
do
    _index="$ES_IDX_PREFIX$_index"
    if [ ${#_index} -gt $index_len ];then
        index_len=${#_index}
    fi
done

total_idx=0
total_size=0
for _index in ${ES_INDICES[@]};
do
    _index="$ES_IDX_PREFIX$_index"
    result=$( calc $ES_IP $ES_PORT "$_index" )
    size=$( echo "$result" | cut -d, -f1 )
    idx=$( echo "$result" | cut -d, -f2 )

    printf "* * * %-${index_len}s: index=%5s, size=%9s.%-12s $ES_DATA_UNIT\n" "$_index" "$idx" "$( echo $size | cut -d. -f1 )" "$(echo $size | cut -d. -f2 )"

    ((total_idx+=idx))
    total_size=$( echo "scale=6; $total_size + $size" | bc )
done

echo
echo "[[ total indices of ]]"
total_size=$( echo "scale=6; $total_size/1000" | bc )
printf "* * * %-${index_len}s: index=%5s, size=%9s.%-12s $ES_DATA_UNIT_T\n" "total indices" "$total_idx" "$( echo $total_size | cut -d. -f1 )" "$(echo $total_size | cut -d. -f2 )"

exit 0

