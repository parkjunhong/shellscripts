#!/bin/bash

help(){
	if [ ! -z "$1" ];
	then
		echo
		echo " !!! Caller: ${FUNCNAME[1]}, cause: $1"
	fi
	
	echo
	echo "Usage:"
	echo "disk-size <directory> -s[a|d]r"
	echo
	echo "[Optons]"
	echo " -s: sort."
	echo "    + a: asc"
	echo "    + d: desc"
	echo " -r: Enable recursive search."
}

DIR=""
RECUR=0
SORT="N"
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
					h|-help)
						help
						exit 0
						;;
					r)
						RECUR=1
						;;
					s)
						case ${opt:((${idx}+1)):1} in 
							a)
								SORT="A"
								((idx++))
								;;
							d)
								SORT="D"
								((idx++))
								;;
							*)
								;;
						esac
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

#
# @param $1 {string} du result
# @return 'echo'
tonum(){
	local str=$(echo $1 | tr [:lower:] [:upper:])
	local val=${str:0:((${#str}-1))}
	local unit=${str:((${#str}-1)):1}
	
	# grater than or equal to a kilo
	case ${unit} in
		K)
			echo ${val} | awk '{print $1 * 1024}'
			;;
		M)
			echo ${val} | awk '{print $1 * 1024 * 1024}'
			;;
		G)
			echo ${val} | awk '{print $1 * 1024 * 1024 * 1024}'
			;;
		T)
			echo ${val} | awk '{print $1 * 1024 * 1024 * 1024 * 1024}'
			;;
		P)
			echo ${val} | awk '{print $1 * 1024 * 1024 * 1024 * 1024 * 1024}'
			;;
		*)
			echo ${str}
			;;
	esac
}
# 
# @param $1 {string} parent directory 
# @param $2 ~ 
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
	
	local __tmpfile__=$(pwd)"/.disk-size-tmp-$(date +%s)"
	printf "%s" "" > ${__tmpfile__}

	for file in ${subfiles[@]}
	do	
		path=${parent}/${file}
		IFS=" " read -a durst <<< $(du -sh ${path})
		printf "%030.1f=%s	%s\n" $(tonum ${durst[0]}) ${durst[0]} ${durst[1]} >> ${__tmpfile__}
	done
	
	local __cmd__=""
	case ${SORT} in
		A)
			__cmd__="cat ${__tmpfile__} | sort"
			;;
		D)
			__cmd__="cat ${__tmpfile__} | sort -r"
			;;
		N)
			__cmd__="cat ${__tmpfile__}"
			;;
		*)
			help "Invalid Sort Type. value=${SORT}"
			exit 1
			;;
	esac

	local path=""
	while IFS="=	" read -a durst
	do
		#echo "read: ${durst[@]}"
		path="${durst[2]}"
		if [ -f "${path}" ];
		then
			printf "$RST_FORMAT" "f" ${durst[1]} ${durst[2]}
		elif [ -d "${path}" ];
		then
			printf "$RST_FORMAT" "d" ${durst[1]} ${durst[2]}
		fi
	done <<< "$(eval ${__cmd__})"
	# "$(cat ${__tmpfile__} | sort)"

	rm -f ${__tmpfile__}
}

DIR=$(deltailslash ${DIR})
SUB_FILES=($(ls ${DIR}))

search ${DIR} ${SUB_FILES[@]}

exit 0

