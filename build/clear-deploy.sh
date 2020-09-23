#!/bin/bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : clear a deployment.
# @license: Apache License 2.0
# @since  : 2020-09-15
# =======================================

help(){
    if [ $# -gt 0 ];
    then
        echo
        echo "['${FUNCNAME[1]}' says] " $1
    fi  
    echo
    echo "[Usage]"
    echo "clear-deploy.sh -d <deploy-dir> -l <enable list profiles> -p <project-dir> <profile>"
    echo
    echo "[Parameters]"
    echo " -d: deployment directory"
    echo " -l: enable list profiles"
    echo " -p: project directory"
    echo
}

PRJ_DIR=""
DEP_DIR="deploy"
LIST_FLAG="0"
PROFILE=""
while [ ! -z "$1" ];
do
	case "$1" in
		-d | --deploy-dir)
			shift
			DEP_DIR="$1"
			;;
		-l | --list)
			LIST_FLAG=1
			;;
		-p | --project)
			shift
			PRJ_DIR="$1"
			;;
		-h | --help)
			help
			exit 0
			;;
		*)
			PROFILE="$1"
			;;
	esac
	shift
done

if [[ "$PRJ_DIR" != /* ]];
then
	if [ -z "$PRJ_DIR" ];
	then
		PRJ_DIR="$PWD"
	else
		PRJ_DIR="$PWD/$PRJ_DIR"
	fi
fi

PRJ_DIR="$PRJ_DIR/$DEP_DIR"

list-profiles(){
	echo
	echo " *** list deployment dir."
	echo " > > > "
	ls -al $1
}

if [ $LIST_FLAG -eq 1 ];
then
	list-profiles "$PRJ_DIR"
	exit 0
fi

if [ -z "$PROFILE" ];
then
	list-profiles "$PRJ_DIR"
	echo
	help "Please, input a profile !!!"
	echo
	exit 1
fi

echo
echo "[before] ls -al $PRJ_DIR"
echo " > > > "
ls -al $PRJ_DIR

echo
echo "[clear] rm -rf $PRJ_DIR/$PROFILE"
echo " > > > "
rm -rfv $PRJ_DIR"/"$PROFILE

echo
echo "[after] ls -al $PRJ_DIR/"
echo " > > > "
ls -al $PRJ_DIR

exit 0

