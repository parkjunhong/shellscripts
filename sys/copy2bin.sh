#!/bin/bash

help(){
	echo "Usage:"
	echo
	echo "cp2bin [-u] <command>"
	echo
	echo "[Options]"
	echo " -u | o: copy to user bin directory"
	echo
	echo "[Arguments]"
	echo " command: a command to be copied to."
	echo
}

ARGUMENTS=()
USER_DIR=0
COMMAND=""
IDX=0
while [ "$1" != "" ];
do
	case $1 in
		-h | --help | "/h")
			help
			exit 0
			;;
		-u)
			USER_DIR=1
			;;
		*)	
			if [ "$IDX" == 0 ];
			then
				COMMAND="$1"
			fi
			((IDX++))
			;;
	esac
	shift
done

if [ -z "$COMMAND" ] || [ ! -f "$COMMAND" ];
then
	help 
	exit 1
fi

if [ "$USER_DIR" == 1 ];
then
	echo "cp $COMMAND $(echo ~)/bin/"
	eval cp $COMMAND $(echo ~)/bin/
else	
	# which : retreive /usr/* at first.
	# command -v: retrieve ${user.home} at first.
	location=$(which $COMMAND)	
	if [ -z $location ];
	then
		echo "sudo cp $COMMAND /usr/bin/"
		eval sudo cp $COMMAND /usr/bin/
	else
		echo "sudo cp $COMMAND $location"
		eval sudo cp $COMMAND $location
	fi
fi

exit 0
