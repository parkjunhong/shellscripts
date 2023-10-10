#!/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : modify string in files.
# @license: Apache License 2.0
# @since  : 2023-08-08
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7 or higher
# @completion: <this-filename>.completion
#            1. insert 'source <path>/<this-filename>.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

# get a filename
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
    echo "$FILENAME -d <target-directory> -f <file> -o <old string> -n <new string> [-h|--help]"
    echo
    echo "Options:"
    echo " -d | --dir    : target directory"
	echo " -f | --file   : target file"
    echo " -o | --old-str: string to be delete"
    echo " -n | --new-str: string to be insert"
}

TARGET_DIR=""
TARGET_FILE=""
OLD_STR=""
NEW_STR=""

while [ ! -z "$1" ];
do
	case "$1" in
		-d | --dir)
			shift
			if [[ $1 == /* ]];then
				TARGET_DIR=$1
			else
				TARGET_DIR=$(pwd)/$1
			fi
			;;
		-f | --file)
			shift
			TARGET_FILE="$1"
			;;
		-o | --old-str)
			shift
			OLD_STR="$1"
			;;
		-n | --new-str)
			shift
			NEW_STR="$1"
			;;
		-h | --help)
			help "user help" $LINENO
			exit 0
			;;
	esac
	shift
done

if [ -z "$TARGET_DIR" ] || [ -z "$TARGET_FILE" ] || [ -z "$OLD_STR" ] || [ -z "$NEW_STR" ];then
	help "입력한 데이터가 올바르지 않습니다." $LINENO
	exit 1
fi


if [ ! -d "$TARGET_DIR" ];then
	help "입력한 경로가 올바르지 않습니다. TARGET_DIR=$TARGET_DIR" $LINENO
	exit 1
fi


#
# @param {$1} encrypted string
normalize(){
    str="$1"
    echo $str | sed -e 's/\//\\\//g'
}

cd "$TARGET_DIR"
TARGET_DIR=$(pwd)
CMD_FIND="find '$TARGET_DIR' -name '$TARGET_FILE' -type f"
CMD_OLD_FILES="$CMD_FIND | xargs grep -Hn '$OLD_STR'"
_OFCOUNT=$(eval "$CMD_OLD_FILES | wc -l")
if [  $_OFCOUNT -gt 0 ];then
	echo
	echo "* * * 이전 파일목록($_OFCOUNT)"
	eval $CMD_OLD_FILES

	echo
	read -p "* * * 발견된 파일에 대해서 변경을 하겠습니까? " confirm
	if [ ! -z "$confirm" ] && [ $(echo $confirm | tr [:lower:] [:upper:]) = "Y" ];then
		CMD="$CMD_FIND | xargs sed -i 's/$(normalize $OLD_STR)/$(normalize $NEW_STR)/g'"
		echo $CMD
		eval $CMD
		
		CMD_NEW_FILES="$CMD_FIND | xargs grep -Hn '$NEW_STR'"
		_NFCOUNT=$(eval "$CMD_NEW_FILES | wc -l")
		echo
		echo "* * * 변경 후 파일 정보($_NFCOUNT)"
		eval "$CMD_FIND | xargs grep -Hn '$NEW_STR'"
	fi
fi

echo
echo "* * * Bye ..."

exit 0


