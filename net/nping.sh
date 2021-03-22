#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : execute nping many times.
# @license: Apache License 2.0
# @since  : 2020-04-01
# =======================================

NOTICE_BEGIN="Network Quality Measurement BEGIN"
NOTICE_DONE="Network Quality Measurement DONE"

usage(){
	echo
	echo ">>> CALLED BY [[ $1 ]]"
	echo
	echo "[Usage]"
	echo
	echo "./nping.sh -m <measurement-duration> --rate <package-per-second> -c <packet-per-measurement> -time <target-ip>"
	echo
	echo "[Option]"
	echo " -m    : 품칠측정 시간. (unit: second), '0' 인 경우 무제한 측정."
	echo " --rate: 초당 패킷 개수"
	echo " -c    : 1회 측정 패킷 개수"
	echo " -time : enable '--icmp-type time'"
	echo 
}

# 파라미터가 없는 경우 종료
if [ "$1" == "" ];
then
	usage "No Paramters."
			
	exit 1
fi

# 품질측정 시간
MD="-"
# 1회 품질측정시 패킷 개수
PPM="-"
# 1회 품질측정시 1초당 패킷 개수
PPS="-"
# 품질측정 대상
IP="-"
# --icmp-type time enable
ICMP_TYPE=""

## 파라미터 읽기
{
while [ "$1" != "" ]; do
	case $1 in
		-m | --measurement-period )
			shift
			MD=$1
    	;;
		-c | --packet-per-measurement )
			shift
			PPM=$1
    	;;    		
		--rate | --packet-per-second )
			shift
			PPS=$1
    	;;
#		-ip | --target-ip)
#			shift
#			IP=$1
#		;;
		-time)
			ICMP_TYPE="--icmp-type time"
		;;
		-h | --help)     
			usage "--help"
			exit 0
			;;
		*)
			IP=$1
#			usage "Invalid option. option: $1"
#			exit 1
			;;
	esac
	shift
done
}||{ 
	echo "Oops... "
	usage "CAN NOT Controll..."
	exit 1
}

# 품질측정 숫자형 데이터 검증
PARAMETERS=("$MD" "$PPM" "$PPS")
for param in ${PARAMETERS[@]}; do
	if [[ ! "$param" =~ ^[[:digit:]]+$ ]]; then
		usage "'$param' is Not A Number."
		exit 1
	fi
done

# 품질측정 대상 IP 검증 
IPv4_REGEX="^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$"
DN_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"
if [[ ! $IP =~ $IPv4_REGEX ]]; then
	if [[ ! $IP =~ $DN_REGEX ]]; then
		usage "Invalid a target ip. IP=$IP"
		exit 1
	fi
fi

# 품질측정 파라미터 정보
echo
echo $NOTICE_BEGIN
echo
echo "[Configuration] - begin" 
echo " - 품질측정 기간            : $MD"
echo " - 1번 측정시 패킷개수      : $PPM"
echo " - 1번 측정시 초당 패킷 개수: $PPS"
echo " - 측정 대상                : $IP"
echo " - --icmp-type              : ${ICMP_TYPE}"
echo " - 명령어                   : nping --icmp ${ICMP_TYPE} --rate $PPS -c $PPM $IP -q"
echo "[Configuration] - end"
echo

# 품질측정 시작
let CURTIME=$(date -d "now" +%s)
let ENDTIME=$CURTIME+$MD

while [ "$MD" -eq "0" ] || [  "$CURTIME" -lt "$ENDTIME" ]; do
    NPING_PRIV=$(ls -al $(which nping) | awk '{print $1}')

    if (( $EUID == 0 )) || [ "rws" == "${NPING_PRIV:1:3}" ];
    then
	nping --icmp ${ICMP_TYPE} --rate $PPS -c $PPM $IP -q
        CURTIME=$(date -d "now" +%s)
    else
        echo "[ERROR] Invalid 'nping' privileges. "$(ls -al $(which nping))
        sleep 5
    fi
done

echo
echo $NOTICE_DONE
echo

exit 0
