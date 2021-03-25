#!/usr/bin/env bash

help(){
	if [ ! -z "$1" ];then
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
	echo "[Usage]"
	echo "handle-svc-automation -f <service properties file> --no-reg --no-start"
	echo
	echo "[Parameters]"
	echo " -f        : service property filepath"
	echo " --no-reg  : disable service registration"
	echo " --no-start: disable auto start"
	echo
}

FILE=""
REG="Y"
START="Y"
while [ ! -z "$1" ];
do
	case "$1" in
		-f | --file)
			shift
			file="$1"
			if [[ "$1" == /* ]];
			then
				FILE="$file"
			else
				FILE="$PWD/$file"
			fi
			
			if [ ! -f $FILE ];
			then
				echo
				help "Invalid a file. file=$FILE" $LINENO
				exit 1
			fi
			;;
		--no-reg)
			REG="N"
			;;
		--no-start)
			START="N"
			;;
		-h | --help)
			help
			exit 0
			;;
		*)
			echo
			help "지원하지 않는 속성입니다. arg=$1" $LINENO
			exit 1
			;;
	esac
	shift
done

echo "sed -i s/service.registration=.*/service.registration=$REG/g $FILE"
sed -i s/service.registration=.*/service.registration=$REG/g $FILE
echo
echo "sed -i s/service.autostart=.*/service.autoastart=$START/g $FILE"
sed -i s/service.autostart=.*/service.autostart=$START/g $FILE

echo

exit 0	
