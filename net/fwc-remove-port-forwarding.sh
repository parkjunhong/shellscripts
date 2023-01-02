#!/usr/bin/env bash


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
	echo "./fwc-remove-port-forwarding.sh -f <Source Port Info> -t <To Port value> -i <To IP> [-h|--help]"
	echo
	echo "Options:"
	echo " -f | --from  : Source Port Information. <port>:<protocol>. ex) 80:tcp"
	echo " -t | --help  : Destination Port value. ex) 8080"
	echo " -i | --ipaddr: Destination IP Address. if forward to local, can skip."
	echo " -h | --help  : Show hele messages."
}

FROM_PORT=""
FROM_PROTO=""
TO_PORT=""
TO_IP=""
while [ ! -z "$1" ];
do
	case "$1" in
		-f|--from)
			shift
			FROM_PORT=$(cut -d ':' -f1 <<< "$1")
			FROM_PROTO=$(cut -d ':' -f2 <<< "$1")
			;;
		-t|--to-port)
			shift
			TO_PORT="$1"
			;;
		-i|--to-ip)
			shift
			TO_IP="$1"
			;;
		-h | --help)
			help "show help message."
			exit 0
			;;
		*)
			;;
	esac
	shift
done

echo 
echo "from.port =$FROM_PORT"
echo "from.proto=$FROM_PROTO"
echo "to.port   =$TO_PORT"
echo "to.ip     =$TO_IP"

if [ -z "$FROM_PORT" ] || [ -z "$FROM_PROTO" ] || [ -z "$TO_PORT" ];
then
	help "포트 포워딩 정보가 올바르지 않습니다. 다시 한번 확인하시기 바랍니다."
	exit 1
fi

CMD="sudo firewall-cmd --remove-forward-port=port=$FROM_PORT:proto=$FROM_PROTO:toport=$TO_PORT"
if [ ! -z "$TO_IP" ];
then
	CMD=$CMD":toaddr=$TO_IP"
fi
CMD=$CMD" --permanent"
echo
echo $CMD
eval $CMD

echo 
echo "Reload firwall list..."
sudo firewall-cmd --reload

echo
echo "List firewalls"
sudo firewall-cmd --list-all

exit 0

