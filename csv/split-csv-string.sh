#!/usr/bin/env bash

# CSV 데이터 구분자
SEPARATOR="$1"
# CSV 문자열
STRING="$2"
# 문자열 길이
len=${#STRING}

#
# @param $1 {number} 컬럼 순서
# @param $2 {string} 컬럼 값 
write-column(){
	printf "%7s : >%s<\n" $1 "$2"
}

# 컬럼 순서
clmNum=1
# 캐릭터 버퍼
buf=""
# 현재 캐릭터
c=""
for (( i=0; i<len; i++ ));
do
	c="${STRING:$i:1}"
	if [ "$c" == "$SEPARATOR" ];then
		write-column $clmNum "$buf"
		((clmNum++))
		buf=""
	else
		buf="$buf$c"
	fi
done

# 마지막 데이터
write-column $clmNum "$buf"

exit 0

