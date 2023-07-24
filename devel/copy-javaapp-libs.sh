#!/bin/env bash

usage(){
	echo
	echo "Usage:"
	echo "tgw-copy-service-libs.sh --src <서비스 설치 디록토리> --dst <라이브러리 복사할 디렉토리> [-c]"
	echo
	echo "Parameters:"
	echo " --src | -s: 서비스가 설치된 디렉토리"
	echo " --dst | -d: 라이브러리를 복사할 디렉토리"
	echo
	echo "Options:"
	echo " --clr | -c: 이전 파일 삭제"
}

DIR_SRC=""
DIR_DST=""
CLEAR_DIR=""
DATE_DIR=$(date +%Y%m%d)
DIR_LIB=""
## 파라미터 읽기
while [ "$1" != "" ]; do
	case $1 in
		-c | --clr)
			CLEAR_DIR="1"
			;;
		-s | --src)
			shift
			DIR_SRC=$1
			;;
		-d | --dst)
			shift
			DIR_DST="$1"
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

#
# 디렉토리 인지 아닌지 확인
# @param $1 {string} directory.
# @param $2 {number} src or dst.
#                    0: src
#                    1: dst
#
# @return 
#        -1: 파일
#         0: 존재하지 않음.
#         1: 디렉토리
check-dir(){
	if [ -z "$1" ]; then
		echo "0"
	elif [ -f "$1" ];then
		echo "-1"
	else
		if [ "$2" = "0" ]; then
			if [ -d "$1" ];then
				echo "1"
			else
				echo "0"
			fi
		else
			_d="$1/$DATE_DIR"
			#if [ "$CLEAR_DIR" = "1" ];then
			#	rm -rf "$_d"
			#fi
			rm -rf "$_d"
			mkdir -p "$_d"
			D="$_d"
			echo "1"
		fi
	fi
}

# check a src  and a dst directories.
_check_dir=$(check-dir "$DIR_SRC" "0")
if [ "$_check_dir" != "1" ];then
	echo
	echo "서비스가 설치된 디렉토리가 올바르지 않습니다. 입력값=$DIR_SRC"
	usage
	exit 0
fi

_check_dir=$(check-dir "$DIR_DST" "1")
if [ "$_check_dir" != "1" ];then
	echo
	echo "라이브러리를 복사랄 디렉토리가 올바르지 않습니다. 입력값=$DIR_SRC"
	usage
	exit 0
fi

DIR_LIB="$DIR_DST/$DATE_DIR"

# 서비스가 설치된 디렉토리로 이동
cd "$DIR_SRC"

for _dir_svc in $(find -maxdepth 1 -type d -printf "%f\n" | grep -v "\.");
do
	_dir_lib="$DIR_LIB/$_dir_svc"
	_dir_src="$DIR_SRC/$_dir_svc"
	cd "$_dir_src"
	# ./lib/*.jar
	if [ -d "$_dir_src/lib" ];then
		mkdir -p "$_dir_lib"
		cp $_dir_src/lib/* $_dir_lib/
		echo "[복사완료] $_dir_src/lib/* -> $_dir_lib"
	# 'war' file
	elif [ -e *.war ];then
		_f="$DIR_SRC/$_dir_svc/"$(ls *.war)
		mkdir -p "$_dir_lib/tmp"
		cp $_f "$_dir_lib/tmp"
		cd "$_dir_lib/tmp"
		unzip -qq $_f -d .
		cp ./WEB-INF/lib/* ../
		cd ..
		rm -rf ./tmp
		echo "[복사완료] $_f:/WEB-INF/lib/* -> $_dir_lib"
	# executable 'jar' file
	elif [ -e *.jar ];then
		_f="$DIR_SRC/$_dir_svc/"$(ls *.jar)
		mkdir -p "$_dir_lib/tmp"
		cp $_f "$_dir_lib/tmp"
		cd "$_dir_lib/tmp"
		unzip -qq $_f -d .
		cp ./BOOT-INF/lib/* ../
		cd ..
		rm -rf ./tmp
		echo "[복사완료] $_f:/BOOT-INF/lib/* -> $_dir_lib"
	fi
done

exit 0






  
