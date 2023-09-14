#!/usr/bin/env bash

help(){
	echo
	echo "[Usage]"
	echo " tar-zcf-deploy-profi.esh <profile> <build-name>"
	echo 
	echo "[Parameters]"
	echo "- profile: profile에 해당하는 폴더명"
	echo "- build-name: 압축파일명. 입력하지 않은 경우 상위 디렉토리명을 사용"
	echo
}

function remove_left_zero() {
	echo $1|sed -e "s/^0*//"
}

cur_dir=$(pwd)

if [[ $cur_dir != */deploy ]];then
	echo
	echo "Illegal directory. MUST BE end with '*/deploy'."
	help
	exit 0
fi

profile="$1"
profile=$(echo ${profile/\//})

if [ ! -d "$cur_dir/$profile" ];then
	echo
	echo "존재하지 않는 프로파일 입니다. 입력=$profile"
	help
	exit 0
fi

paths=($(echo $cur_dir | tr "/" " "))
if [ ${#paths[@]} -lt 2 ];then
	echo
	echo "Illegal directory. The length of directory MUST BE greater than 1."
	help
	exit 1
fi

if [ -z "$2" ];then
	build_name=${paths[-2]}
else
	build_name="$2"
fi
cur_date=$(date +%Y%m%d)
filename=$build_name"-"$profile"-"$cur_date

num="01"
list=($(ls $filename-*.tar.gz &2>/dev/null))
if [ ${#list[@]} -gt 0 ];then
	latestfile=${list[-1]}
	latestfile=$(echo ${latestfile/$filename-/})
	num=$(echo ${latestfile/.tar.gz/})
	num=$(remove_left_zero $num)
	((num++))
	if [ $num -lt 10 ];then
		num="0"$num
	fi
fi

tar -zcf $filename-$num.tar.gz $profile

exit 0
