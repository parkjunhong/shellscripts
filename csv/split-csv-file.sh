#!/usr/bin/env bash

# CSV 데이터 구분자
SEPARATOR="$1"
# CSV 파일
INPUT_FILE="$2"
# 결과파일 
OUTPUT_ROOT_DIR="$3"

if [ ! -f "$INPUT_FILE" ];then
	# TODO: help 로 대체
	echo "잘못된 파일입니다. 파일=$INPUT_FILE"
	exit 0
fi

if [ -z "$OUTPUT_ROOT_DIR" ];then
	OUTPUT_ROOT_DIR="$(date +%Y%m%d%H%M%S)"
elif [ -f "$OUTPUT_ROOT_DIR" ];then
	# TODO: help로 대체
	echo "결과출력 디렉토리가 올바르지 않습니다. 디렉토리=$OUTPUT_ROOT_DIR"
	exit 0
fi

if [ ! -d "$OUTPUT_ROOT_DIR" ];then
	mkdir -p "$OUTPUT_ROOT_DIR" 2>/dev/null
fi

FILE_DIR="$OUTPUT_ROOT_DIR/$(basename $INPUT_FILE)-sp"
if [ -d $FILE_DIR ];then
	rm -rf $FILE_DIR
fi
# 디렉토리 생성
mkdir -p $FILE_DIR 2>/dev/null


# 진행률 시각화 관련 함수
PROG_MOD=30
dotprogress(){
    local idx=0
    prog=""
    while [ ${idx} -lt ${PROG_MOD} ];
    do
        prog=${prog}"."
        echo ${prog}
        ((idx++))
    done
}

##
# convert timestamp to {hours}h {minutes}m {seconds}h.
# @param $1 {number} timestamp
# @return 
timestamp-to-hms(){
    # 1234567890
    local _sec_r=$(($1%60)) # 'second' remainder
    local _min_q=$(($1/60)) # 'minutes' quotient
    local _min_r=$(($1/60%60)) # 'minutes' remainder
    local _hour_q=$(($1/60/60)) # 'hour' quotient

    printf "%'dh %sm %ss" $_hour_q $_min_r $_sec_r
}

#
# @param $1 {number} 컬럼 번호
# @param $2 {string} 컬럼 값 
# @param $3 {number} 줄 번호 
write-column(){
    printf "%7s : >%s<\n" $1 "$2" >> $FILE_DIR/$3.txt
}


# 전체 데이터 개수
_total_data_count=0
# 진행률 시각화 데이터 
_progress=($(dotprogress))

# @param $1 {number} line number
# @param $2 {string} CSV separator
# @param $3 {string} read string
write-line(){
	# 줄 번호
	local ln=$1
	# 데이터 구분자
	local sep="$2"
	# 문자열
	local string="$3"
	# 문자열 길이
	local len=${#string}
	# 컬럼 번호
	local clmnNum=1
	# 캐릭터 버퍼
	local buf=""
	# 현재 캐릭터
	local c=""
	for (( i=0; i<len; i++ ));
	do
		c="${string:$i:1}"
		if [ "$c" == "$sep" ];then
			write-column $clmnNum "$buf" $ln
			((clmnNum++))
			buf=""
		else
			buf="$buf$c"
		fi

		printf "\r\033[K + + + %-12s: %'d | %s" "Line.Reading" $_total_data_count ${_progress[((${_total_data_count}%${PROG_MOD}))]}
		((_total_data_count++))
	done

	# 마지막 데이터
	write-column $clmnNum "$buf" $ln
}

_fmt_label="%-15s"
_fmt_info=" * * * $_fmt_label:"
_fmt_result=" - - - $_fmt_label:"
# 입력 정보
printf "$_fmt_info %s\n" "Input File" "$INPUT_FILE"
printf "$_fmt_info %s\n" "File Separator" "$SEPARATOR"
printf "$_fmt_info %s\n" "Result Dir" "$FILE_DIR"

echo

_begin_date=$(date +"%Y/%m/%d %H:%M:%S")
_begin_ts=$(date +"%s")

# 줄 번호
_ln=1
while read line
do
	write-line $_ln "$SEPARATOR" "$line"
	((_ln++))
done < "$INPUT_FILE"

printf "\r\033[K + + + $_fmt_label: line=%'d, data=%'d\n" "Completed" $_ln $_total_data_count

_end_date=$(date +"%Y/%m/%d %H:%M:%S")
_end_ts=$(date +"%s") 

echo
printf "$_fmt_result %s\n" "Read.begin" "$_begin_date"
# Convert timestamp to hour/minite/second
# Referenced: https://stackoverflow.com/questions/29405432/how-to-convert-timestamp-to-hour-minutes-seconds-in-shell-script
_diff=$(($_end_ts-$_begin_ts))
printf "$_fmt_result %s\n" "Read.elapsed" "$(timestamp-to-hms $(($_end_ts-$_begin_ts)))"
printf "$_fmt_result %s\n" "Read.end" "$_end_date"


exit 0

