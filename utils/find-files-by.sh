#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : find files by pattern."
# @license: Apache License 2.0
# @since  : 2024-05-20
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7
# @completion: not supported."
# =======================================

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
    echo "./find-files-by.sh.sh [-d|--dir] <dir> [-p|--pattern] <pattern> [-h|--help]"
    echo
    echo "Options:"
    echo " -d | --dir     : a directory to search files."
    echo " -p | --pattern : file name pattern to to search."
    echo " -h | --help  : show help messages."
}

TARGET_DIR=""
FILE_PATTERN=""
VERBOSE=0

while [ ! -z "$1" ];
do
	case "$1" in
		-d | --dir)
			shift
			if [ -z "$1" ] || [ ! -d "$1" ];then
				help "Invalid a directory." $LINENO 
				exit 0
			fi
			TARGET_DIR="$1"
			;;
		-p | --pattern)
			shift
			FILE_PATTERN="$1"
			;;
		-v | --verbose)
			VERBOSE=1
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

if [ -z "$TARGET_DIR" ];then
	help "Invalid arguments. target.dir=$TARGET_DIR"
	exit 0
fi

if [ -z "$FILE_PATTERN" ];then
    FILE_PATTERN=""
else
    FILE_PATTERN="-name *$FILE_PATTERN*"
fi

pushd . 1>/dev/null

cd $TARGET_DIR
ROOT_PATH=$(pwd)

declare -A file_counts=()

_tmpfile="/tmp/find-files-by-$(uuidgen)"
touch $_tmpfile

while IFS= read _file;
do
    _dir=$(dirname $_file)
    _cnt=${file_counts[$_dir]}
    if [ -z "$_cnt" ];then
        file_counts[$_dir]=1
    else
        ((_cnt++))
        file_counts[$_dir]=$_cnt
    fi  
    if [ $VERBOSE -eq 1 ];then
        echo $_file >> $_tmpfile
    fi  
done < <(find $ROOT_PATH $FILE_PATTERN -type f | sort )

if [ ${#file_counts[@]} -lt 1 ];then
    echo "$ROOT_PATH 경로 아래에 '$FILE_PATTERN'과 매칭되는 파일이 존재하지 않습니다."
else
    for _d in "${!file_counts[@]}";
    do  
        printf "%-20s = %'d\n" $_d ${file_counts[$_dir]}
    done

	if [ $VERBOSE -eq 1 ];then
		echo
		echo "# files"
		printf "> %s\n" $(cat $_tmpfile | sort)
	fi
fi
rm -f $_tmpfile

popd 1>/dev/null

exit 0

