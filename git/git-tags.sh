#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : build maven projects with user-custom 'profile' for build.
# @license: Apache License 2.0
# @since  : 2023-10-11
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7
# @completion: git-tags.completion
#            1. insert 'source <path>/git-tags.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================


# TOOD
# - LICENSE 추가

FILENAME=$(basename -- $0)
at(){
	echo "($FILENAME:$1)"
}


help(){
	if [ $# -eq 1 ];then
		echo
        echo "['${FUNCNAME[1]}' says] $1"
	elif [ $# -eq 2 ];then
        echo
        echo "['${FUNCNAME[1]}' says] $1 ($FILENAME:$2)"
    fi
    echo
    echo "[Usage]"
    echo "git-tags.sh <directory> -b <branch> [-m <tag message>] [-t <tag type>] [ --prefix <tag prefix>] [--suffix <tag suffix>] "
    echo
    echo "[Parameters]"
    echo " directory: directory that contains git projects."
    echo
	echo "[Options]"
	echo " -b | --branch : branchname"
	echo " -m | --message: tag message"
	echo " -t | --type   : tag type. default is 'release'"
	echo " --prefix      : tag name prefix. If empty, set a project directory as a prefix."
	echo " --suffix      : tag name suffix. "
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
				help "! ! ! [INVALID] '$1' is not a directory." $LINENO 
				exit 1
			fi
			DIR="$1"
			;;
	esac
	shift
done

if [ -z "$BRANCH" ];then
	help "! ! ! [INVALID] 'branch' MUST BE assigned." $LINENO
	exit 1
fi

if [ -z "$MSG" ];then
	read -p "! ! ! Message has not been set. Recommend setting a message for a tag. => " MSG
fi

if [ "$DIR" != "." ];then
	cd $DIR
fi

# @param $1 {string} content type
# @param $2 {string} content
set-content(){
	if [ $# -eq 2 ];then
		echo "$1 $2"
	else
		echo ""
	fi
}

# @param $1 {number} count
# @param $2 {string} character
write-ncopy(){
	local _MAX=$(($1 + 20))
	local _c=0
	while [ $_c -lt $_MAX ];
	do
		printf "%s" $2
		((_c++))
	done
	printf "\n"
}

# absolute path of directory 
DIR=$(pwd)
LEN_DIR=${#DIR}
CMD_DIR="find $DIR -maxdepth 1 -type d | sort "
# sub directories as projects
PRJS=$(eval $CMD_DIR)
DATE=$(date +%Y%m%d)
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
		#else
		#	echo "! ! ! [NOT EXIST] $_prj:$BRANCH $(at $LINENO)"
		fi

		if [ $_exist -eq 1 ];then
			_modified=0
			if [ "$_cur_branch" != "$BRANCH" ];then
				git checkout $BRANCH 1>/dev/null
				_modified=1
			fi
			echo
			_pb="$_prj -> $BRANCH"
			_len_pb=${#_pb}
			write-ncopy $_len_pb ">"
			echo "> > > > > $_prj -> $BRANCH > > > > >"
			echo
			# create <tag name>
			# tag name: <prefix>-<type>-<date>-<suffix>
			_tag_name=""
			#add <prefix>
			if [ -z "$PREFIX" ];then
				_tag_name="$_prj"
			else
				_tag_name=$PREFIX
			fi
			# add <type>
			_tag_name=$_tag_name"-"$TYPE
			# add <date>
			_tag_name=$_tag_name"-"$DATE
			# add <suffix>
			if [ ! -z "$SUFFIX" ];then
				_tag_name=$_tag_name$"-"$SUFFIX
			fi
			# check <tag name> exists
			# cmd: git tag --list | grep <tag name>
			if [ ! -z $(git tag --list | grep $_tag_name) ];then
				# if exists, delete <tag name>
				# cmd: git tag -d <tag name> for local
				git tag -d $_tag_name 2>/dev/null
				# cmd: git push origin -d <tag name> for remote
				git push origin -d $_tag_name 2>/dev/null
			fi

			if [ -z "$MSG" ];then
				MSG="tag for $BRANCH, $(date +'%Y-%m-%d %H:%M:%S')"
			fi
			# create a tag using <tag name>
			# cmd: git tag -a <tag name> -m <message>
			git tag -a "$_tag_name" -m "$MSG"

			# push a new tag using <tag name>
			# cmd: git push origin <tag name>
			git push origin $_tag_name

			if [ $_modified -eq 1 ];then
				git checkout $_cur_branch 1>/dev/null
			fi
			echo
			echo "< < < < < $_prj -> $BRANCH < < < < <"
			write-ncopy $_len_pb "<"
		fi
	#else
	#	echo "! ! ! [NOT GIT PRoJeCT] project=$_prj $(at $LINENO)"
	fi
	# go to upper directory
	cd ..
done

exit 0

