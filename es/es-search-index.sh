#!/usr/bin/env bash

host=""
port=""
index=""
props="timestamp vip rootServer count avgCount totalCount"
gte=1718636400000
lt=1718724600000

# @param $1 {string} varaiable name
print_var(){
	local _cli="printf \"%-5s = %s\\n\" \"$1\" \"\$$1\""
	eval $_cli
}


dump_config(){
	printf " # # # Configurations # # #\n"
	vars=( "host" "port" "index" "gte" "lt" )
	for _var in ${vars[@]};
	do
		printf " > %s\n" "$(print_var "$_var")"
	done
}

# @param $1 {string} json data
elapsed(){
	echo "$1" | jq ".took"	
}

# @param $1 {string} json data
count(){
	echo "$1" | jq ".hits.total.value"
}

# @param $1 {string} json data
# @param $2 {string} properies. (빈칸으로 구분)
read-data(){
	local _props=( "$2" )
	local _jqprops=""
	for _p in ${_props[@]};
	do
		_jqprops="$_jqprops"",\\(._source.$_p)"		
	done

	while read _d;
	do
		echo "${_d:1:-1}"
	done < <(jq ".hits.hits[] | \"${_jqprops:1}\" " <<< "$1")
}

data=$(curl --silent -X GET "http://$host:$port/$index/_search" -H 'Content-Type: application/json' -d "{\"query\": {\"range\": {\"timestamp\": {\"gte\": $gte, \"lt\": $lt}}}, \"size\": 10}" )

#printf "%-10s = %'d\n" "elapsed" $(elapsed "$data")
#printf "%-10s = %'d\n" "count" $(count "$data")

if [ $(count "$data") -lt 1 ];then
	echo " no data ..."
	exit 0
fi 

read-data "$data" "$props"

exit 0
