#!/usr/bin/env bash

DIR="$1"

if [ ! -d "$DIR" ];then
	echo
	echo "잘못된 디렉토리 정보입니다. 입력=$DIR"
	exit 0
fi

# ZIP 파일 경로 변환
if [[ ! "$DIR" == /* ]];then
	DIR=$(pwd)"/$DIR"
fi

while IFS= read zipfile
do
	if [ ! -z "$zipfile" ]; then
		unzip -l $zipfile
	else 
		echo "No zip files in $DIR"
	fi
done <<< "$(find $DIR -name '*.zip' | sort)"

exit 0


