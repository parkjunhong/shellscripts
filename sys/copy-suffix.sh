#!/bin/bash

#
# Show help message.
# $1 {string}: error message
help(){
	echo 
	echo "[ERROR] $1"
	echo 
	echo "Usage:"
	echo " cp-suffix <filename> [{option]}"
	echo
	echo "[Options]"
	echo " -d | --date : (optional) add current date string."
	echo "               e.g.) cp-suffix abc.txt -d -> abc.txt-20200114"
	echo " -t | --time : (optional) add current time string."
	echo "               e.g.) cp-suffix abc.txt -t -> abc.txt-20200114191212"
	echo "[Parameters]"
	echo " filename: absolute/relative filepath."
	echo
}

if [ $# -lt 1 ] || [ $# -gt 2 ];
then
	help "Invalid arguments count."
	exit 1
fi

FILENAME=""
FLAG="-d"
while [ "$1" != "" ];
do
	case $1 in
		-d | --date)
			FLAG="-d"
			;;
		-t | --time)
			FLAG="-t"
			;;
		*)
			if [ -f "$1" ];
			then
				FILENAME=$1
			fi
			;;
	esac
	shift
done

if [ -z "${FILENAME}" ];
then
	help "Invalid filename. file=${FILENAME}"
	exit 1
fi


case ${FLAG} in
    -d | --date)
		cp ${FILENAME} ${FILENAME}-$(date -dtoday '+%Y%m%d')
        ;;
    -t | --time)
		cp ${FILENAME} ${FILENAME}-$(date -dtoday '+%Y%m%d%H%M%S')
        ;;
    *)
		help "Invalid flag. flag=${FLAG}"
		exit 1
        ;;
esac

exit 0	
