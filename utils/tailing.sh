#!/usr/bin/env bash
 
# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : tail files after they appears.
# @license: Apache License 2.0
# @since  : 2023-08-11
# @desc   : support macOS 11.2.3, Ubuntu 20.04, CentOS 7 or higher
# @completion: <this-filename>.completion
#            1. insert 'source <path>/<this-filename>.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

# get a filename
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
    echo "$FILENAME -n <init-line-count> -f <target> [-h|--help]"
    echo
    echo "Options:"
    echo " -n : initial line count to show"
    echo " -f : target file or representation of target"
}

INIT_LINE=""
TARGET_FILE=""
while [ ! -z "$1" ];
do
    case "$1" in
        -n)
            shift
            if [[ $1 =~ ^[0-9]+$ ]];then
                INIT_LINE="$1"
            fi
            ;;
        -f)
            shift
            TARGET_FILE="$1"
            ;;
		-h | --help)
			help "User Request" $LINENUMBER
			exit 0
			;;
        *)
            ;;
    esac
    shift
done

if [ -z "$TARGET_FILE" ];then
    echo
    help "* * * Input target or representation for target. !!! " $LINENUMBER
    exit 1
fi

CMD="tail"
if [ ! -z "$INIT_LINE" ];then
    CMD=$CMD" -n $INIT_LINE"
fi

CMD=$CMD" -f $TARGET_FILE"

_file_count=$(ls $TARGET_FILE 2>/dev/null | wc -l)
_retry=0
while [ $_file_count -lt 1 ];
do
    sleep 1
    ((_retry++))
    printf "\r\033[K * * * [%'d retry] Searching result for %s." ${_retry}
    _file_count=$(ls $TARGET_FILE 2>/dev/null | wc -l)
done

eval $CMD

exit 0

