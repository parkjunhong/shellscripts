#!/bin/bash

# =======================================
# @auther: parkjunhong77@gmail.com
# @since: 2020-01-2
# =======================================

help(){
	echo
	echo "Usage:"
	echo " redis-search <database> <redis commands and its arguments | built-in commands> [{options}]"
	echo
	echo "[Options]"
	echo " --key: Apply when use a built-in command. Print key<tab>value"
	echo
	echo "[Built-in]"
	echo " __get_all__: Retrieve all data using redis commands"
	echo "              e.g) redis-search 1 __get_all__ lrange 0 -1"
	echo " __get_one__: Retrieve one data using redis commands"
	echo "              e.g) redis-search 1 __get_one__ lrange 0 -1"
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

# ------- BEGIN: Common Functions -------------

# Assign a value to the variable
# $1 {string} variable name
# $2 {any} value
assign(){
    eval $1=\"$2\"
}

# Convert a string to upper/lower bidirectional.
# $1 {string} string value.
# $2 {number} (optional)
#             lower or upper. 
#             0: lower, 1: upper
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

# ------- END: Common Functions -------------
	
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
# $@: a message by a caller.
print_args(){
	echo "$@: ${__arguments__[@]}"
}

#
# Assign arguments to the variable
#
# $1  {string}: variable name
# $2~ {any}   : arguments
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
# Execute a 'redis command' with its arguments.
#
# $1 {string}: authorization
# $2 {number}: database
# $3 {string}: command
# $4~ {any}  : arguments
__redis__(){
	params=($@)
	read_args "${params[@]:3}"
	local args=(${__arguments__[@]})

	eval redis-cli -a $1 -n $2 $3 ${args[@]}
}

#
# Execute a 'redis-command' with its arguments and print to console.
#
# $1 {string}: authorization
# $2 {number}: database
# $3 {string}: command
# $4~ {any}  : arguments
__exec_general__(){
	params=($@)
	read_args "${params[@]:3}"
	local args=(${__arguments__[@]})

	if [ "$KEY" == 0 ];
	then
		__redis__ $1 $2 $3 ${args[@]}
	else
		echo "${args[0]}	"$(__redis__ $1 $2 $3 ${args[@]})
	fi
}

#
# Search all data.
#
# $1  {string}: authorization
# $2  {number}: database
# $3  {string}: command
# $4~ {any}   : arguments
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
		for key in "${scanning[@]:1}"
		do
			if [ "$KEY" == 0 ];
			then
				__redis__ $1 $2 $3 $key ${args[@]}
			else
				echo "$key	"$(__redis__ $1 $2 $3 $key ${args[@]})
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
# $1  {string}: authorization
# $2  {number}: database
# $3  {string}: command
# $4~ {any}   : arguments
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
		if [ -z "$key" ];
		then
			echo "Oops!!! No key!!!"
			return
		fi
		
		if [ "$KEY" == 0 ];
		then
			__redis__ $1 $2 $3 $key ${args[@]}
		else
			echo "${key}	$(__redis__ $1 $2 $3 $key ${args[@]})"
		fi
	fi
}


# read arguments.
read_args "${PARAMS[@]:2}"
args=(${__arguments__[@]})

AUTH="password"
case ${COMMAND} in
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

