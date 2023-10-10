#!/usr/bin/env bash
# TOOD
# - 대상 branch 설정
# - tag prefix 설정 (없는 경우 프로젝트명)
# - tag 타입 설정 (release, dev, ...)
# - tag 메시지 설정

FILENAME=$(basename -- $0)
TGT_DIR="."

at(){
	echo "($FILENAME:$1)"
}

if [ ! -z "$1" ] && [ ! -d "$1" ];then
	echo "! ! ! '$1' is not a valid directory. $(at $LINENO)"
	exit 1
fi

if [ ! -z "$1" ];then
	TGT_DIR="$1"
fi

if [ "$TGT_DIR" != "." ];then
	cd $TGT_DIR
fi
LEN_TGT=${#TGT_DIR}
CMD_DIR="find $TGT_DIR -maxdepth 1 -type d | sort "
PRJS=$(eval $CMD_DIR)

for _prj in ${PRJS[@]};
do
	if [ "$_prj" == "$TGT_DIR" ];then
		continue
	fi
	# target directory 로 시작하는 경로정보를 삭제
	_prj=${_prj:$LEN_TGT}

	# /xxx 패턴
	if [[ "$_prj" =~ /* ]];then
		_prj=${_prj:1}
	fi
	
	# go to 'project' directory
	cd "$_prj"
	# check 'git configuration' directory
	if [ ! -d ".git" ];then
		echo "! ! ! [NOT GIT PROJEcT] project=$_prj $(at $LINENO)"
	else
		_branch="devx"
		if [ ! -z "$(git rev-parse --verify $_branch 2>/dev/null)" ];then
			echo "'$_prj:$_branch' exists"
		elif [ ! -z "$(git rev-parse --verify remote/origin/$_branch 2>/dev/null)" ];then
			echo "pull 'remote/origin/$_branch'"
			echo "'$_prj:remote/origin/$_branch' exists"
		else
			echo "! ! ! [NOT EXIST] '$_prj:$_branch' $(at $LINENO)"
		fi
	fi
	
	cd ..
done

exit 0

