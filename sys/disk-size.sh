#!/bin/bash

# @author: parkjunhong77_gmail_com
# @license: MIT.
#

help(){
	if [ ! -z "$1" ];
	then
		echo
		echo " !!! Caller: ${FUNCNAME[1]}, cause: $1"
	fi
	
	echo
	echo "Usage:"
	echo "disk-size <directory> -r"
	echo
	echo "[Optons]"
	echo " -r: Enable recursive search."
}

DIR=""
RECUR=0
while [ "$1" != "" ];
do
	case $1 in
		-*)
			if [ "-" == "$1" ];
			then
				help "Invalid options. arg=$1"
				exit 1
			fi
			
			opt="$1"
			len=${#opt}	
			idx=0
			while [ $idx -lt $len ];
			do
				case ${opt:${idx}:1} in 
					r)
						RECUR=1
						;;
					*)
						;;
				esac
				((idx++))
			done
			;;
		*)
			DIR="$1"
			;;
	esac
	shift
done

if [ -z "${DIR}" ];
then
	DIR="."
fi

if [ ! -d ${DIR} ];
then
	help "!!! Invalid directory or file. input=${DIR}"
	exit 1
fi

# @param $1 {string} directory
abspath(){
	if [ -d $1 ];
	then
		cd $1
		dir=$(pwd)
		cd ..
		echo ${dir}
	fi
}

# @param $1 {string} directory
deltailslash(){
  if [ "$1" == "/" ];
  then
    echo $1
  elif [ ! -z "$1" ] && [[ "$1" == */ ]]; 
  then
    echo ${1:0:$((${#1}-1))}
  else
    echo $1
  fi  
}

# @param $1 list 
search(){
    local args=($@)
    local parent=${args[0]}
    local subfiles=${args[@]:1}
    local path=""
    RST_FORMAT="[%s] %6s %s\n"

    if [ "${parent}" == "/" ];
    then
        parent=""
    fi

    for file in ${subfiles[@]}
    do
        path=${parent}/${file}
        IFS=" " read -a durst <<< $(du -sh ${path})
        if [ -d "${path}" ];
        then
            printf "$RST_FORMAT" "d" ${durst[0]} ${durst[1]}
        elif [ -f "${path}" ];
        then
            printf "$RST_FORMAT" "f" ${durst[0]} ${durst[1]}
        fi
    done
}



DIR=$(deltailslash ${DIR})
SUB_FILES=($(ls ${DIR}))

search ${DIR} ${SUB_FILES[@]}

exit 0

