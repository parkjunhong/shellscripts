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

ES_IP=""
ES_PORT=""
ES_INDICES=""

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
	local _gb=0
	local _mb=0
	local _kb=0
	local _b=0

	# storage size	
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
			*)
		#		echo "raw=$_size, v=$_value, u=$_unit"
				;;
		esac
	done <<< "$( eval $_curl_size 2>/dev/null)"

	# primary shard count
	local _curl_shard_count="curl --silent 'http://$1:$2/_cat/indices?format=json&index=$3' | jq -r '.[][\"pri\",\"rep\"]'"
	_total_psc=0
	while IFS= read -r _count;
	do
		((_total_psc+=_count))
	done <<< "$( eval $_curl_shard_count 2>/dev/null)"

	# documents count
	local _curl_docs_count="curl --silent 'http://$1:$2/_cat/indices?format=json&index=$3' | jq -r '.[][\"docs.count\"]'"
	_total_docs=0
	while IFS= read -r _count;
	do
		((_total_docs+=_count))
	done <<< "$( eval $_curl_docs_count 2>/dev/null)"

	# index count
	local _curl_idx_size="curl --silent 'http://$1:$2/_cat/indices?format=json&index=$3' | jq 'length'"
	_total_storage=$( echo "scale=6; $_gb + $_mb/1000 + $_kb/1000/1000 + $_b/1000/1000/1000" | bc)
	echo $(eval $_curl_idx_size)","$_total_psc","$_total_docs","$_total_storage
}

# index 이름 최대 길이
idx_len=16
for _idx in ${ES_INDICES[@]};
do
    len=${#_idx}    
    idx_len=$(( idx_len > len ? idx_len : len))
done
_format="* * * %-${idx_len}s: %3s, %5s, %15s, %5s.%-6s gb"

echo "[[ of each/group index ]]"
total_idx=0
total_shard=0
total_docs=0
total_size=0
for _index in ${ES_INDICES[@]};
do
	result=$( calc $ES_IP $ES_PORT $_index )
	idx=$( echo "$result" | cut -d, -f1 )
	shard_count=$( echo "$result" | cut -d, -f2 )
	docs_count=$( echo "$result" | cut -d, -f3 )
	size=$( echo "$result" | cut -d, -f4 )

	printf "$_format\n" "$_index" $(printf "%'d" $idx) $(printf "%'d" $shard_count) $(printf "%'d" $docs_count) "$( echo $size | cut -d. -f1 )" "$(echo $size | cut -d. -f2 )"

	((total_idx+=idx))
	((total_shard+=shard_count))
	((total_docs+=docs_count))
	total_size=$( echo "scale=6; $total_size + $size" | bc )
done

echo
echo "[[ of total indices ]]"
total_size=$( echo "scale=6; $total_size/1000" | bc )
printf "$_format\n" "total indices(*)" $(printf "%'d" $total_idx) $(printf "%'d" $total_shard) $(printf "%'d" $total_docs)  "$( echo $total_size | cut -d. -f1 )" "$(echo $total_size | cut -d. -f2 )"

exit 0
