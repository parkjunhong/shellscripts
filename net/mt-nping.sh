#!/bin/bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : nping to multiple targets.
# @license: Apache License 2.0
# @since  : 2020-04-01
# =======================================

usage(){
	echo
	echo ">>> CALLED BY [[ $1 ]]"
	echo
	echo "[Usage]"
	echo
	echo " Script for 'nping' to multiple target."
	echo 
	echo "./mt-nping.sh -m <duration> --rate <pps> -c <packet count> <IP list file>"
	echo
	echo "[Arguments]"
	echo " IP list file: IP list separated by new line."
	echo 
    echo "[Option]"
	echo " -m    : 품칠측정 시간. (unit: second), '0' 인 경우 무제한 측정."
	echo " --rate: 초당 패킷 개수"
	echo " -c    : 1회 측정 패킷 개수"
	echo " -time : enable '--icmp-type time'"
}

# 파라미터가 없는 경우 종료
if [ "$#" -ne 7 ];
then
	usage "Invalid Paramters."
	exit 1
fi

REG_ONLY_NUM="^[[:digit:]]+$"

# 품질측정 시간
MD="-"
# 1회 품질측정시 패킷 개수
PPM="-"
# 1회 품질측정시 1초당 패킷 개수
PPS="-"
# --icmp-type time enable
ICMP_TYPE=""

while [ "$1" != "" ];
do
	case "$1" in
		-m)
			shift
			if [[ ! $1 =~ ${REG_ONLY_NUM} ]];
			then
				usage "Invalid duration. => $1"
				exit 1
			fi
			MD=$1
		;;
        -c)
			shift
			if [[ ! $1 =~ ${REG_ONLY_NUM} ]];
			then
				usage "Invalid duration. => $1"
				exit 1
			fi
			PPM=$1
		;;
		--rate)
		    shift
			if [[ ! $1 =~ ${REG_ONLY_NUM} ]];
			then
				usage "Invalid duration. => $1"
				exit 1
			fi
	   		PPS=$1
		;;
		-time)
		    ICMP_TYPE="-time"
		;;		
		*)
			if [ ! -f "$1" ];
			then
				usage "Invalid filepath. => $1"
				exit 1
			fi
			FILE=$1
		;; 
	esac
	shift
done


while IFS= read -r chgw_ip
do
	echo "./nping.sh -m ${MD} --rate ${PPS} -c ${PPM} ${ICMP_TYPE} ${chgw_ip} > nping-${chgw_ip}-m${MD}--rate${PPS}-c${PPM}-sole${ICMP_TYPE}-.log"
	./nping.sh -m ${MD} --rate ${PPS} -c ${PPM} ${ICMP_TYPE} ${chgw_ip} > nping-${chgw_ip}-m${MD}--rate${PPS}-c${PPM}-sole${ICMP_TYPE}-.log
done < "${FILE}"

echo 
echo " <<< DONE"
echo

exit 0
