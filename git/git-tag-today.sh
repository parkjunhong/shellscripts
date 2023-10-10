#!/usr/bin/env bash
# TOOD
# - 대상 branch 설정
# - tag prefix 설정 (없는 경우 프로젝트명)
# - tag 타입 설정 (release, dev, ...)
# - tag 메시지 설정

FILENAME=$(basename -- $0)
at(){
	echo "($FILENAME:$1)"
}


help(){
    if [ $# -gt 0 ];
    then
        echo
        echo "['${FUNCNAME[1]}' says] " $1
    fi
    echo
    echo "[Usage]"
    echo "git-tag-today.sh <directory> -b <branch> [-m <tag message>] [-t <tag type>] [ --prefix <tag prefix>] [--suffix <tag suffix>] "
    echo
    echo "[Parameters]"
    echo " directory: directory that contains git projects."
    echo
	echo "[Options]"
	echo " -b | --branch : branchname"
	echo " -m | --message: tag message"
	echo " -t | --type   : tag type"
	echo " --prefix      : tag name prefix"
	echo " --suffix      : tag name suffix"
}

DIR="."
BRANCH=""
MSG=""
TYPE="release"
PREFIX=""
SUFFIX=""
while [ ! -z "$1" ];
do
	case "$1" in
		-b | --branch)
			shift
			BRANCH="$1"
			;;
		-m | --message)
			shift
			MSG="$1"
			;;
		-t | --type)
			shift
			TYPE="$1"
			;;
		--prefix)
			shift
			PREFIX="$1"
			;;
		--suffix)
			shift
			SUFFIX="$1"
			;;
		*)
			if [ ! -d "$1" ];then
				echo "! ! ! [INVALID] '$1' is not a directory. $(at $LINENO)" 
				exit 1
			fi
			DIR="$1"
			;;
	esac
	shift
done

if [ -z "$BRANCH" ];then
	echo "! ! ! [INVALID] 'branch' MUST BE assigned. $(at $LINENO)"
	exit 1
fi

if [ "$DIR" != "." ];then
	cd $DIR
fi

# absolute path of directory 
DIR=$(pwd)
LEN_DIR=${#DIR}
CMD_DIR="find $DIR -maxdepth 1 -type d | sort "
# sub directories as projects
PRJS=$(eval $CMD_DIR)

for _prj in ${PRJS[@]};
do
	if [ "$_prj" == "$DIR" ];then
		continue
	fi
	# target directory 로 시작하는 경로정보를 삭제
	_prj=${_prj:$LEN_DIR}

	# /xxx 패턴
	if [[ "$_prj" =~ /* ]];then
		_prj=${_prj:1}
	fi
	
	# go to 'project' directory
	cd "$_prj"
	# check 'git configuration' directory
	if [ -d ".git" ];then
		_cur_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
		_exist=0
		if [ ! -z "$(git rev-parse --verify $BRANCH 2>/dev/null)" ] || [ ! -z "$(git rev-parse --verify remotes/origin/$BRANCH 2>/dev/null)" ];then
			_exist=1
		else
			echo "! ! ! [NOT EXIST] $_prj:$BRANCH $(at $LINENO)"
		fi

		if [ $_exist -eq 1 ];then
			_modified=0
			if [ "$_cur_branch" != "$BRANCH" ];then
				git checkout $BRANCH 1>/dev/null
				_modified=1
			fi
			echo "* * * [EXIST] $_prj -> $BRANCH"
			echo "git tag -a <tag name> -m <tag message>"
			echo "git push origin <tag name>"

			if [ $_modified -eq 1 ];then
				git checkout $_cur_branch 1>/dev/null
			fi
		fi
	#else
	#	echo "! ! ! [NOT GIT PRoJeCT] project=$_prj $(at $LINENO)"
	fi
	# go to upper directory
	cd ..
done

exit 0

