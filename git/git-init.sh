#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : push an existing folder to a remote git repository.
# @license: Apache License 2.0
# @since  : 2023-11-30
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7
# @completion: git-init_completion
#            1. insert 'source <path>/git-init_completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

FILENAME="$(basename $0)"

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
    echo "./git-init.sh [-h|--help] [-r|--repoisoty] <remote git repository> [-b|--branch] <remote git branch>"
    echo
    echo "Options:"
    echo " -b | --branch    : remote git branch."
    echo " -r | --repository: remote git repository."
    echo " -h | --help      : show this message."
}

REMOTE_GIT_REPO=""
REMOTE_BRANCH="master"
while [ ! -z "$1" ];
do
	case "$1" in
		-b | --branch)
			shift 
			REMOTE_BRANCH="$1"
			;;
		-r | --repository)
			shift
			REMOTE_GIT_REPO="$1"
			;;
		-h | --help)
			help 
			exit 0
			;;
		*)
			;;
	esac
	shift
done

if [ -z "$REMOTE_GIT_REPO" ] || [ -z "$REMOTE_BRANCH" ];
then
	help "git 저장소 또는 연동할 branch 이름을 확인하시기 바랍니다. git=$REMOTE_GIT_REPO, branch=$REMOTE_BRANCH" $LINENO
	exit 1
fi

# git init
git init

# git remote add origin <remote git server address>
git remote add origin $REMOTE_GIT_REPO

# git pull origin <remote branch>
git pull origin $REMOTE_BRANCH

# git add .
git add .

# git commit -m "<commit message>"
git commit -m "최초 작성."

# git push --set-upstream origin <remote branch>
git push --set-upstream origin $REMOTE_BRANCH 


exit 0
