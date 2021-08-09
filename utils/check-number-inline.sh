#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : check whether a value is number or not
# @license: Apache License 2.0
# @since  : 2021-04-21
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7
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
	echo "./build-mvn-package [-h|--help] [-d|--deploy] -p <profile> [-t|--test] [-u|--update]"
	echo
	echo "Options:"
	echo " -d | --deploy: deploy after build."
	echo " -h | --help: show help messages."
	echo " -p | --profile: Profile"
	echo " -t | --test: run Junit TestCase"
	echo " -u | --update: 'git pull' before build sources."
}

FILE=""
INDICE=()
while [ ! -z "$1" ];
do
	case "$1" in
		-f | --file)
			shift
			FILE="$1"
			;;
		-h | --help)
			help
			exit 0
			;;
		*)
			if [[ $1 =~ ^[0-9]+$ ]];then
				INDICE+=($1)
			fi		
			;;
	esac
	shift
done

# check file.
if [ ! -f "$FILE" ];then
	help "올바르지 않은 파일경로입니다. 입력=$FILE"  $LINENO
	exit 1
fi

# check indice.
if [ ${#INDICE[@]} -lt 1 ];then
	help "검증할 인덱스 정보가 존재하지 않습니다. indice=${INDICE[@]}" $LINENO
	exit 1
fi


PROG_MOD=100
dotprogress(){
  local idx=0
  prog=""
  while [ ${idx} -lt ${PROG_MOD} ];
  do
    prog=${prog}"."
    echo ${prog}
    ((idx++))
  done
}

##
#
# @param $1 {any} value to validate
validate-number(){
	if [ ! -z "$1" ] && [[ $1 =~ ^[0-9]+$ ]];then
		echo "true"
	else
		echo "false"
	fi
}


##
#
# @param $1 {string} filepath.
parse-file(){
	local _valid="true"
	local _errorfile="error-$1"
	local _linecount=1
	local _progress=($(dotprogress))

	printf "\n + %-10s: %s\n" "filepath" "$1"
	local _indice="${INDICE[@]}"
	printf " + %-10s: %s\n" "indice" "${_indice// /, }"
	printf " + %-10s: %s\n\n" "errorfile" "$_errorfile"
	
	printf "" > $_errorfile
	while IFS= read -r readline
	do
		IFS="," read -a linearr <<< "$readline"

		_valid="true"
		for _idx in ${INDICE[@]};
		do
			if [ $_idx -ge ${#linearr[@]} ];then
				continue
			fi
		
			_valid=$(validate-number ${linearr[$_idx]})
			if [ "$_valid" = "false" ];then
				printf "[%'10d]=%s\n" $_linecount "$readline" >> $_errorfile
				break
			fi
		done	

		printf "\r\033[K[%'10d] %s" ${_linecount} ${_progress[((${_linecount}%${PROG_MOD}))]}
		if [ $(expr $_linecount % $PROG_MOD) -eq $PROG_MOD ];then
			printf "\r\033[K[%'10d] %10s  = %s\n" ${_linecount}
		fi

		((_linecount++))
	done < "$1"
}

echo
echo "* * * begin to validate a file:'$FILE'"
parse-file "$FILE"
echo
echo "* * * finished !"

exit 0
