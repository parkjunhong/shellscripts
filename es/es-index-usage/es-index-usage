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
    echo "./es-index-usage.sh -i <ip> -p <port> -x <indices> [-ip <prefix>]"
    echo
    echo "Options:"
    echo " -i  | --ip          : IP address of Elasticsearch"
    echo " -p  | --port        : Port of Elasticsearch"
    echo " -x  | --indices     : Index list of Elasticsearch."
	echo "                       indices separated by comma(,)."
    echo " -ip | --index-prefix: prefix for all indices."
    echo " -h  | --help        : show help messages, like this."
}

ES_IP=""
ES_PORT=""
ES_INDICES=""
INDEX_PREFIX=""
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
			IFS=" " read -r -a ES_INDICES <<< "$(echo "$1" | sed 's/,/ /g')"
			;;
		-ip)
			shift
			INDEX_PREFIX="$1"
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
	local _total_shard=0
	local _total_docs=0
	local _index_count=0

	local _props=("store.size" "pri" "rep" "docs.count")
	_IFS="$IFS" IFS="," _qryprops="${_props[*]}" IFS="$_IFS"

	# store size, shard count(primary, replica), docs count
	while read -a _d
	do
		_v=${_d[0]}
		_unit=$( echo $_v | sed -e "s/[0-9.]//g" 2>/dev/null )
		_value=$( echo $_v | sed "s/$_unit//g" 2>/dev/null  )
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
		# shard.primary
		((_total_shard+=${_d[1]}))
		# shard.replica
		((_total_shard+=${_d[2]}))
		# docs.count
		((_total_docs+=${_d[3]}))
		# index count
		((_index_count++))
	done < <(curl --silent "http://$1:$2/_cat/indices?h=$_qryprops&index=$3")

	_total_storage=$( echo "scale=6; $_gb + $_mb/1000 + $_kb/1000/1000 + $_b/1000/1000/1000" | bc)
	echo $_index_count","$_total_shard","$_total_docs","$_total_storage
}

# index 이름 최대 길이
idx_len=16
for _idx in "${ES_INDICES[@]}";
do
    len=${#_idx}    
    idx_len=$(( idx_len > len ? idx_len : len))
done
_format_each="* * * %-${idx_len}s: %3s, %5s, %15s, %12s, %5s.%-6s gb"
_format_total="* * * %-${idx_len}s: %3s, %5s, %15s, %5s.%-6s tb"

echo "[[ of each/group index ]]"
total_idx=0
total_shard=0
total_docs=0
total_size=0

for _index in "${ES_INDICES[@]}";
do
	result=$( calc $ES_IP $ES_PORT "$INDEX_PREFIX$_index" )
	idx=$( echo "$result" | cut -d, -f1 )
	shard_count=$( echo "$result" | cut -d, -f2 )
	docs_count=$( echo "$result" | cut -d, -f3 )
	size=$( echo "$result" | cut -d, -f4 )

	if [ $shard_count -gt 0 ];then
		printf "$_format_each\n" "$_index" $(printf "%'d" $idx) $(printf "%'d" $shard_count) $(printf "%'d" $docs_count) $(printf "%'d" $(echo "scale=0; $docs_count/$shard_count"|bc)) "$( echo $size | cut -d. -f1 )" "$(echo $size | cut -d. -f2 )" 2>/dev/null
	else
		printf "$_format_each\n" $(echo $_index | sed 's/\\//g') 0 0 0 0 0
	fi

	((total_idx+=idx))
	((total_shard+=shard_count))
	((total_docs+=docs_count))
	total_size=$( echo "scale=6; $total_size + $size" | bc )
done

echo
echo "[[ of total indices ]]"
total_size=$( echo "scale=6; $total_size/1000" | bc )
printf "$_format_total\n" "total indices(*)" $(printf "%'d" $total_idx) $(printf "%'d" $total_shard) $(printf "%'d" $total_docs)  "$( echo $total_size | cut -d. -f1 )" "$(echo $total_size | cut -d. -f2 )"

exit 0
