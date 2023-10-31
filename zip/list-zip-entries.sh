#!/usr/bin/env bash

DIR="$1"

if [ ! -d "$DIR" ];then
	echo
	echo "잘못된 디렉토리 정보입니다. 입력=$DIR"
	exit 0
fi

while IFS= read zipfile
do
	unzip -l $zipfile
done <<< "$(find $DIR -name *.zip)"

exit 0


