#!/usr/bin/env bash

help(){
    echo
    echo "[Usage]"
    echo " cp2downlaod.sh <file> <directory>"
    echo 
    echo "[Parameters]"
    echo "- file     : 복사할 파일."
    echo "- directory: $HOME/Downloads/에 생성할 디렉토리 이름."
    echo
}

FILE="$1"
DIR="$HOME/Downloads/$2"

if [ ! -f "$FILE" ];then
	echo
	echo "올바르지 않은 파일입니다."
	help
	exit 0
fi

if [ -f "$DIR" ];then
	echo
	echo "$DIR 이름에 해당하는 파일이 이미 존재합니다."
	ls -al $DIR
	echo "-----------------------------------------------------------------------"
	help
	exit 0
elif [ ! -d "$DIR" ];then
	mkdir -p "$DIR"
fi

cp -v "$FILE" "$DIR"

exit 0


