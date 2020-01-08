#!/bin/bash

help(){
	echo
	echo "Usage:"
	echo " redis-search <database> <redis commands and its arguments | built-in commands> [{options}] "
	echo
	echo "[Options]"
	echo " --key: Apply when use a built-in command. Print key<tab>value."
	echo
	echo "[Built-in]"
	echo " __get_all__: Retrieve all data using redis commands"
	echo "              e.g) redis-search 1 __get_all__ lrange 0 -1"
	echo
	echo "[Arguments]"
	echo " - database | m: Database number"
	echo " - commands | m: Redis command"
	echo
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
		*)
			PARAMS[$idx]="$1"
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
reset_args(){
	__arguments__=()
}
print_args(){
	echo "$@: ${__arguments__[@]}"
}

# $1 ~ : arguments
read_args(){
	reset_args
	params=("$@")
	idx=0
	for i in "${params[@]}";
	do
		if [[ ${i} =~ "\"*" ]];
		then
			__arguments__[$idx]="${i}"
		else
			__arguments__[$idx]="\"${i}\""
		fi
		((idx++))
	done
}

# $1   : authorization
# $2   : database
# $3   : command
# $4 ~ : arguments
__exec_general__(){
	params=("$@")
	read_args "${params[@]:3}"
	
	eval redis-cli -a $1 -n $2 $3 ${__arguments__[@]}
}

# $1   : authorization
# $2   : database
# $3   : command
# $4 ~ : arguments
__get_all__(){
	reset_args
	params=("$@")

	if [ $# -gt 3 ];
	then
		read_args ${params[@]:3}
	fi

	index=0
	count=0
	while [ 1 ];
	do
		scanning=($(redis-cli -a $1 -n $2 scan $index | awk '{print $1}'))
		index=$scanning

		for key in "${scanning[@]:1}"
		do
			if [ "$KEY" == 0 ];
			then
				eval redis-cli -a $1 -n $2 $3 $key ${__arguments__[@]}
			else
				echo "$key	"$(eval redis-cli -a $1 -n $2 $3 $key ${__arguments__[@]})
			fi
			((count++))
		done
	
		break	
		if [ "$index" == 0 ];
		then
			break
		fi
	done
}

# read arguments.
read_args "${PARAMS[@]:2}"

AUTH="password"

case ${COMMAND} in
	__get_all__)
		__get_all__ ${AUTH} ${DATABASE} "${__arguments__[@]}"
		;;
	*)
		__exec_general__ ${AUTH} ${DATABASE} ${COMMAND} "${__arguments__[@]}"
		;;
esac

exit 0
