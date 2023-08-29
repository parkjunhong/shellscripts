#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : execute cat to edit a command only with the name of it.
# @license: Apache License 2.0
# @since  : 2021-03-21
# @description: To find commands automatically, run this command after download a this file.
#               cp cat-cli ~/bin/;complete -c -W "-h -v" cat-cli
# =======================================

CMD=""
VERBOSE=0

while [ "$1" != "" ];
do
	case $1 in
		-h | --help)
			echo
			echo "cat-cli.sh [-v] <command>"
			echo
			echo "[Options]"
			echo " -v : show a fullpath of a command."
			
			exit 0
			;;	
		-v)
			VERBOSE=1
			;;
		*)
			CMD=$1
			;;
	esac
	shift
done

RTV=0
# @param $1 {string}: command path
# @param $2 {number}: exit or not. 0: pass, 1:exit
check-empty-or-notfile(){
	if [ -z $1 ] || [ ! -f "$1" ];then
		echo
		echo "[ERROR] Invalid command path. command=$CMD, path=$1"
		RTV=1
		if [ $2 -eq 1 ];then
			exit 1
		fi
	else
		RTV=0
	fi
}

# check a target command
cmd_path=$(command -v $CMD)
check-empty-or-notfile "$cmd_path" 1


if [ $VERBOSE -eq 1 ];then
	echo "$CMD => $cmd_path"
	exit 0
fi

# check a editor command
editor=$(command -v cat)
check-empty-or-notfile "$editor" 0
if [ $RTV -ne 0 ];then
	editor=$(command -v vi)
	check-empty-or-notfile "$editor" 1
fi

$editor $cmd_path 

exit 0


