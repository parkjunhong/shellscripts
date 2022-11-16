#!/usr/bin/env bash


usage(){
	echo
	if [ $# -gt 0 ];then
		echo
		echo "['${FUNCNAME[1]}' says] " $1
	fi
	echo
	echo "[Usage]"
	echo " A shell script that send files or directory using 'sshpass'"
	echo 
	echo "./scp-eash.sh -u <username> -i <passwd> -h <target-host> -p <target-port> -s <source> -d <destionation> [-h]"
	echo
	echo "[Option]"
	echo " -u | --username: username of target server."
	echo " -p | --passwd  : password for <username>"
	echo " -h | --host    : host of target server"
	echo " -p | --port    : ssh port of target server"
	echo " -s | --src     : source file(s) or directory to copy"
	echo " -d | --dest    : target directory."
	echo " -h | --help    : help message"
	echo
}

USER_NAME=""
PASSWD=""
HOST=""
PORT=""
SOURCE=""
DEST=""
## 파라미터 읽기
while [ "$1" != "" ]; do
	case $1 in
		-u | --username)
			shift
			USER_NAME="$1"
			;;
		-i | --passwd)
			shift
			PASSWD="$1"
			;;
		-h | --host)
			shift
			HOST="$1"
			;;
		-p | --port)
			shift
			PORT="$1"
			;;
		-s | --src)
			shift
			SOURCE="$1"
			;;
		-d | --dest)
			shift
			DEST="$1"
			;;
		-h | --help)	 
			usage "--help"
			exit 0
			;;
		*)
			usage "Invalid option. option: $1"
			exit 1
			;;
	esac
	shift
done


echo
echo "#1. Create a target directory if not exist"
sshpass -p ${PASSWD} ssh -p ${PORT} ${USER_NAME}@${HOST} mkdir -p ${DEST}

echo
echo "#2. Copy a directory to target."
echo " \$ scp -r -P ${PORT} ${SOURCE} ${USER_NAME}@${HOST}:${DEST}"
sshpash -p ${PASSWD} scp -r -P ${PORT} ${SOURCE} ${USER_NAME}@${HOST}:${DEST}

exit
