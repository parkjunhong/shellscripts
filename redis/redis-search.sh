#!/bin/bash

help(){
	echo
	echo "Usage:"
	echo " redis-search <database> <redis commands and its arguments | built-in commands> [{options}]"
	echo
	echo "[Options]"
	echo " --key: Apply when use a built-in command. Print key<tab>value"
	echo
	echo "[Built-in]"
	echo " __filter_in__ : Retrieve data DO MATCH a Regular Expression."
	echo "                 e.g) redis-search 4 __filter_in__ 원주인프라팀 get"
	echo " __filter_out__: Retrieve data DO NOT MATCH a Regular Expression."
	echo "                 e.g) redis-search 4 __filter_out__ 원주인프라팀 get"
	echo " __get_all__   : Retrieve all data using redis commands"
	echo "                 e.g) redis-search 1 __get_all__ lrange 0 -1"
	echo " __get_one__	 : Retrieve one data using redis commands"
	echo "                 e.g) redis-search 1 __get_one__ lrange 0 -1"
	echo
	echo "[Arguments]"
	echo " - database | m: Database number"
	echo " - commands | m: Redis command"
	echo
}

redis_info(){
	echo "[Redis database]"
	echo " 1: DHCP 패킷 개수                                              | 2: IP 점유율"                                                     
	echo "   - Packet의 시간 / 분석된 패킷의 1분 통계 데이터              |   - Packet의 시간 / 분석된 IP 점유율의 1분 통계 데이터"                        
	echo "   - Strings (문자열) / Lists (자리수로 구분되는 데이터 리스트) |   - Strings (문자열) / Lists (자리수로 구분되는 데이터 리스트)"                 
	echo "   - Lpush / Lrange                                             |   - Lpush / Lrange"                                            
	echo " 3: IP별 Primary G/W IP 정보                                    | 4: Primary G/W IP 별 ENG팀명, NW_ID 연동 정보"                   
	echo "   - 할당가능한 IP / 속한 네트워크 Primary Gateway IP           |   - Primary Gateway IP / 연관 정보 (ENG 팀명, Network ID)"      
	echo "   - string (문자열) / string (문자열)                          |   - Strings (문자열) /  Strings                          "   
	echo "   - set / get                                                  |   - set / get                                            "
	echo " 5: IP별 IP 블록 G/W 정보                                       | 6: Ethernet 패킷 유입 유무"                   
	echo "   - 할당가능한 IP / 속한 IP 블록 G/W                           |   - IP 블록 ID / 연관 정보"                   
	echo "   - string (문자열) / string (문자열)                          |   - Strings (문자열) / Strings (문자열)"      
	echo "   - set / get                                                  |   - set / get"                          
	echo " 7: DHCP 주/예비 매핑 정보                                      | 8: Primary G/W에 속한 IP 블록 정보"                  
	echo "   - DHCP 서버 IP / DHCP 정보                                   |   - Primary G/W IP / 속한 IP 블록 목록 리스트"         
	echo "   - Strings (문자열) / Hashes                                  |   - string (문자열) / string (문자열)        "      
	echo "   - hmset / hgetall                                            |   - set / get                                "
	echo " 9: Secondary G/W IP가 속한 Primary G/W IP 제공                 | 11: NW_ID와 Primary G/W IP 정보"         
	echo "   - Secondary G/W IP / Primary G/W IP                          |   - NW ID / Primary G/W IP"           
	echo "   - string (문자열) / string (문자열)                          |   - string (문자열) / string (문자열)"      
	echo "   - set / get                                                  |   - set / get"                        
	echo " 12: IP별 서비스 타입"                                          
	echo "   - Client IP / 서비스 타입"                                   
	echo "   - string (문자열) / string (문자열)"                         
	echo "   - set / get"
}

KEY=0
PARAMS=()
idx=0
while [ "$1" != "" ];
do
	case $1 in
		--key)
			KEY=1
			;;
		-h | --help | "/h")
			help "--help"
			exit 0
			;;
		-d | --dbinfo)
			redis_info
			exit 0
			;;
		*)
			PARAMS[$idx]=$1
			((idx++))
			;;
	esac
	shift
done

if [ ${#PARAMS[@]} -lt 3 ];
then
	help "-lt 3"
	exit 0
fi

# ------- Common Functions -------------

# Assign a value to the variable
# @param $1 {string} variable name
# @param $2 {any} value
assign(){
    eval $1=\"$2\"
}

# Convert a string to upper/lower bidirectional.
# @param $1 {string} string value.
# @param $2 {number} (optional)
#                    lower or upper. 
#                    0: lower, 1: upper
convert_str(){
	if [ "$2" == "0" ];
	then
		echo "$1" | tr "[:upper:]" "[:lower:]"
	elif [ "$2" == "1" ];
	then
		echo "$1" | tr "[:lower:]" "[:upper:]"
	else
		echo "$1"
	fi
}
	
# 1. assign a database
DATABASE=0
if [[ $1 =~ [0-9]{,2} ]];
then
	DATABASE=${PARAMS[0]}
else
	help 
	exit 1
fi

# 2. assign a command.
COMMAND=${PARAMS[1]}

declare -a __arguments__

#
# Reset the global arguments variable, __arguments__
reset_args(){
	__arguments__=()
}

#
# Print the global arguments variable, __arguments__
#
# @param $@: a message by a caller.
print_args(){
	echo "$@: ${__arguments__[@]}"
}

#
# Assign arguments to the variable
#
# @param $1   {string}: variable name
# @param $2 ~ {any}   : arguments
read_args(){
	reset_args
	params=("$@")
	idx=0
	for i in "${params[@]}";
	do
		if [[ ${i} == \"* ]];
		then
			__arguments__[$idx]="${i}"
		else
			__arguments__[$idx]="\"${i}\""
		fi
		((idx++))
	done
}

#
# @param $1 {string}: string
# @return 'echo' a string unwrapped double quotes.
unwrap_quotes(){
	local str="$1"
	if [[ ${str} == \"* ]] || [[ ${str} == \'* ]];
	then
		str=${str:1}
	fi

	if [[ ${str} == *\" ]] || [[ ${str} == *\' ]];
	then
		local strlen=${#str}
		((strlen--))
		str=${str:0:${strlen}}
	fi

	echo ${str}
}

# Redis CLI commands that provide multiple result.
REDIS_CLI_MV=( "lrange" )

# 
# @param $1 {string}: Redis CLI command
# @return 'echo'. 0: single value, 1: multiple value
redis_cli_mv(){
	for cmd in ${REDIS_CLI_MV[@]}
	do
		# multiple value command
		if [ "${1}" == "${cmd}" ];
		then
			echo 1
			return
		fi
	done			
	# single value command
	echo 0
}
#
# Execute a 'redis command' with its arguments.
#
# @param $1   {string}: authorization
# @param $2   {number}: database
# @param $3   {string}: command
# @param $4 ~ {any}  : arguments
__redis__(){
	params=($@)
	read_args "${params[@]:3}"
	local args=(${__arguments__[@]})

	eval redis-cli -a $1 -n $2 $3 ${args[@]}
}

#
# Execute a 'redis-command' with its arguments and print to console.
#
# @param$1   {string}: authorization
# @param$2   {number}: database
# @param$3   {string}: command
# @param$4 ~ {any}  : arguments
__exec_general__(){
	params=($@)
	read_args "${params[@]:3}"
	local args=(${__arguments__[@]})

	if [ "${KEY}" == 0 ];
	then
		__redis__ $1 $2 $3 ${args[@]}
	else
		local key=$(unwrap_quotes ${args[0]})

		if [ $(redis_cli_mv "$3") -eq 1 ];
		then
			for result in $(__redis__ $1 $2 $3 ${args[@]})
			do
				echo ${key}"	"${result}
			done
		else
			echo ${key}"	"$(__redis__ $1 $2 $3 ${args[@]})
		fi
	fi
}

#
# Search all data.
#
# @param$1   {string}: authorization
# @param$2   {number}: database
# @param$3   {string}: command
# @param$4 ~ {any}   : arguments
__get_all__(){
	reset_args
	params=("$@")
	
	local args=()
	if [ $# -gt 3 ];
	then
		read_args ${params[@]:3}
		args=(${__arguments__[@]})
	fi

	index=0
	count=0
	while [ 1 ];
	do
		#scanning=($(redis-cli -a $1 -n $2 scan $index | awk '{print $1}'))
		scanning=($(echo $(__redis__ $1 $2 scan $index | more)))
		
		if [ -z "${scanning}" ] || [ ${#scanning[@]} -lt 2 ];
		then
			index=0
		else
			index=$scanning
		fi
	
		# Scan keys.
		local cmd=$(unwrap_quotes "$3")
		for key in "${scanning[@]:1}"
		do
			if [ "${KEY}" == 0 ];
			then
				__redis__ $1 $2 $3 ${key} ${args[@]}
			else
				if [ $(redis_cli_mv "${cmd}") -eq 1 ];
				then
					for result in $(__redis__ $1 $2 $3 ${key} ${args[@]})
					do
						echo ${key}"	"${result}
					done
				else
					echo ${key}"	"$(__redis__ $1 $2 $3 ${key} ${args[@]})
				fi
			fi
			((count++))
		done

		# Stop if index is equal to the init value (0).	
		if [ "$index" == 0 ];
		then
			break
		fi
	done
}
#
# Search one data.
#
# @param$1   {string}: authorization
# @param$2   {number}: database
# @param$3   {string}: command
# @param$4 ~ {any}   : arguments
__get_one__(){
	reset_args
	params=("$@")

	local args=()
	if [ $# -gt 3 ];
	then
		read_args ${params[@]:3}
		args=(${__arguments__[@]})
	fi

	index=0
	scanning=($(echo $(__redis__ $1 $2 scan $index | more)))
	res=$(convert_str "${scanning[@]}" 0)
	if [[ $res == err* ]];
	then
		echo "Oops!!! Returned \"${scanning[@]}\""
		return
	fi

	if [ ! -z "$scanning" ] && [ ${#scanning[@]} -gt 1 ];
	then
		key=${scanning[1]}
		if [ -z "${key}" ];
		then
			echo "Oops!!! No key!!!"
			return
		fi
	
		# scanning
		local cmd=$(unwrap_quotes "$3")	
		if [ "${KEY}" == 0 ];
		then
			__redis__ $1 $2 $3 ${key} ${args[@]}
		else
			if [ $(redis_cli_mv "${cmd}") -eq 1 ];
			then
				for result in $(__redis__ $1 $2 $3 ${key} ${args[@]})
				do
					echo ${key}"	"${result}	
				done
			else
				echo ${key}"	"$(__redis__ $1 $2 $3 ${key} ${args[@]})
			fi
		fi
	fi
}


# @param $1   : authorization
# @param $2   : database
# @param $3   : pattern
# @param $4   : matched or not
# @param $5   : command
# @param $6 ~ : arguments
_filter_(){
	reset_args
	local params=("$@")
	
	if [ $# -gt 5 ];
	then
		read_args ${params[@]:5}
	fi

	local regex=${3}
	regex=${regex//\"/}
	local index=0
	local count=0
	local value=""
	local filtered=0
	while [ 1 ];
	do
		scanning=($(echo $(__redis__ $1 $2 scan $index | more)))
		index=$scanning

		for key in "${scanning[@]:1}"
		do
			value=$(eval __redis__ $1 $2 $5 ${key} ${__arguments__[@]})
			
			if [[ ${value} =~ ${regex} ]] ;
			then
				#echo "${key}	${value}	matched"
				filtered=$(( 1 ^ ${4} ))								
			else
				#echo "${key}	${value}	notmatched"
				filtered=$(( 0 ^ ${4} ))								
			fi
			
			if [ ${filtered} == 0 ];
			then
				if [ "${KEY}" == 0 ];
				then
					__redis__ $1 $2 $5 ${key} ${__arguments__[@]}
				else
					while IFS=" " read -a result
					do
						echo ${key}"	"${result}
					done  <<< "${value}"
				fi
			fi
			((count++))
		done

		if [ "$index" == 0 ];
		then
			break
		fi
	done
}
# @param $1   : authorization
# @param $2   : database
# @param $3   : pattern
# @param $4   : command
# @param $5 ~ : arguments
__filter_in__(){
	reset_args
	local params=("$@")

	if [ $# -gt 4 ];
	then
		read_args ${params[@]:4}
	fi
	
	_filter_ "${1}" "${2}" "${3}" 1 "${4}" "${__arguments__[@]}" 
}

# @param $1   : authorization
# @param $2   : database
# @param $3   : pattern
# @param $4   : command
# @param $5 ~ : arguments
__filter_out__(){
	reset_args
	local params=("$@")

	if [ $# -gt 4 ];
	then
		read_args ${params[@]:4}
	fi
	
	_filter_ "${1}" "${2}" "${3}" 0 "${4}" "${__arguments__[@]}" 
}

# read arguments.
read_args "${PARAMS[@]:2}"
args=(${__arguments__[@]})

AUTH="ipasms2016"
case ${COMMAND} in
	__filter_in__)
		__filter_in__ ${AUTH} ${DATABASE} ${args[@]}
		;;
	__filter_out__)
		__filter_out__ ${AUTH} ${DATABASE} ${args[@]}
		;;
	__get_all__)
		__get_all__ ${AUTH} ${DATABASE} ${args[@]}
		;;
	__get_one__)
		__get_one__ ${AUTH} ${DATABASE} ${args[@]}
		;;
	*)
		__exec_general__ ${AUTH} ${DATABASE} ${COMMAND} ${args[@]}
		;;
esac

exit 0

