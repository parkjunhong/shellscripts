#!/usr/bin/env bash

# 입력  파일
INPUT_FILE="$1"
MATCH_BADFILE="match-badfile-$(basename $INPUT_FILE)"

if [ ! -f "$INPUT_FILE" ];then
	# TODO: help 로 대체
	echo "잘못된 파일입니다. 파일=$INPUT_FILE"
	exit 0
fi

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

# 진행률 시각화 데이터 
_progress=($(dotprogress))

#
# @param $1 {number} 원본 데이터 위치
# @param $2 {string} 컬럼 이름
# @param $3 {number} badfile 데이터 위치
# @param $4 {string} 파일 경로
write-match(){
    printf "%10s : %-20s => %10s\n" $1 "$2" $3 >> $4.txt
}

_fmt_label="%-15s"
_fmt_input=" * * * $_fmt_label:"
_fmt_info=" + + + $_fmt_label:"
_fmt_result=" - - - $_fmt_label:"
# 입력 정보
printf "$_fmt_input %s\n" "Input File" "$INPUT_FILE"
printf "$_fmt_input %s\n" "Match File" "$MATCH_BADFILE"

_begin_date=$(date +"%Y/%m/%d %H:%M:%S")
_begin_ts=$(date +"%s")

echo 
_err_count=0

# 에러 메시지 매칭 정규식
REGEX="^Record [0-9]+: Rejected - Error on table [a-zA-Z0-9_]+, column [a-zA-Z0-9_]+\.$"
# sqlldr badfile 데이터 위치
_badfile_line=0
# 줄 번호
_ln=1
while read line
do
	if [[ "$line" =~ $REGEX ]];then
		((_badfile_line++))
		arr=( $line )
		data_pos=${arr[1]}
		column_name=${arr[9]}
		write-match ${data_pos//:/} ${column_name//./} $_badfile_line $MATCH_BADFILE
		
		((_err_count++))
	fi

	printf "\r\033[K + + + %-12s: %'d | %s" "Line.Reading" $_ln ${_progress[((${_ln}%${PROG_MOD}))]}
	((_ln++))
done < "$INPUT_FILE"

printf "\r\033[K$_fmt_info: %'d\n" "Completed" $_ln $_total_data_count
printf "$_fmt_info: %'d\n" "Error" $_err_count

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

