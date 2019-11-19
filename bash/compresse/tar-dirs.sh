#!/bin/bash

####################################################################
# Compresses directories into individual file using 'tar' command'
# Author: Park Jun-Hong (parkjunhong77@gmail.com)
# License: MIT.
####################################################################

help(){
	echo "[Usage]"
	echo "./tar-dirs.sh -t {target-dir} -o {output-dir} -s {tarfile-suffix} -i {include-pattern} -x {exclude-pattern} -d -q"
	echo "-t|--target : target directory"
	echo "-o|--output : (optional) output directory. Default is equal to target."
	echo "-s|--suffix : (optional) a suffix of archived file."
	echo "-i|--include: (optional) filename patterns for inclusion. seprated by comma(,)."
	echo "-x|--exclude: (optional) filename patterns for exclusion. seprated by comma(,)."
	echo "-d|--dry-run: (optional) DO NOT archive only show processing logs."
	echo "-q|--quiet  : (optional) DO NOT processing log."
	echo
}

# 파라미터가 없는 경우 종료
if [ $# -lt 2 ];
then
	echo "Please, input a directory"
	help
	exit 2
fi

TARGET=""
OUTPUT=""
SUFFIX=""
DRY_RUN="false"
VERBOSE="true"
INCLUDE=""
EXCLUDE=""
## 파라미터 읽기
while [ "$1" != "" ]; do
	case $1 in
		-t | --target)
			shift
			TARGET=$1
    			;;
		-o | --output)
			shift
			OUTPUT=$1
			;;
		-s | --suffix)
			shift
			SUFFIX=$1
			;;
		-i | --include)
			shift
			INCLUDE=$1
			;;
		-x | --exclude)
			shift
			EXCLUDE=$1
			;;
		-d | --dry-run)
			DRY_RUN="true"
	  		;;
		-q | --quiet)
			VERBOSE="false"
	  		;;
		-h | --help)
			help
			exit 0
			;;
		*)
			help
			exit 2
			;;
	esac
	shift
done

# if $DRY_RUN is set, fix $VERBOSE to true.
if [ "$DRY_RUN" == "true" ];
then
	VERBOSE="true"
fi

# show logs according to $VERBOSE
print(){
	_logs=""
	if [ "$VERBOSE" == "true" ];
	then
		args=("$@")
		for i in "${args[@]}";
		do
			_logs=${logs}" "$i
		done
	fi
	
	if [ ! -z "$_logs" ];
	then
		echo $_logs
	fi
}

# @param $1 directory
# @param $2 if $1 does not exist and is not a file, create a new directory.
validateDir(){
	if [ ! -d $1 ];
	then
		if [ -f $1 ];
		then
			print "Oops!!! '$1' is a file."
		fi

		if [ "$2" == "true" ];
		then
			print "Create a output directory. directory=$1"
			mkdir -p $1
		elif [ "$DRY_RUN" != "true" ];
		then
			print "Oops!!! '$1' is not a directory."
			help
			exit 2
		fi
	fi
}

# 절대경로인지 확인
# @param $1 directory
#
# @return true or false
isAbsolutePath(){
	if [[ $1 == /* ]];
	then
		echo "true"
	else
		echo "false"
	fi
}


# if the directory's last char is /, omit.
# @param $1 directory
#
# @return directory 
omitFinalSlash(){
	_dir=$1
	if [[ $_dir == */ ]];
	then
		echo ${_dir:0:-1}
	else
		echo $_dir
	fi
}

# @param $1 directory to be validated
# @param $2 if $1 is empty, return this
#
# @return 
isEmptyThenDefault(){
	if [ -z $1 ];
	then
		echo $2
	else
		echo $1
	fi
}

# @param directory
# @param file
#
# @return a filepath
makePath(){
	_path=""
	args=("$@")
	for i in "${args[@]}";
	do
		if [ ! -z $i ];
		then
			if [ -z $_path ];
			then
				_path=$i
			else
				_path=$_path"/"$i
			fi
		fi
	done

	echo $_path
}

# validate a target directory
validateDir "$TARGET"

OUTPUT=$(isEmptyThenDefault "$OUTPUT" "$TARGET")

# validate a output directory
if [ "$DRY_RUN" == "true" ];
then
	validateDir $OUTPUT
else
	validateDir $OUTPUT true
fi

TARGET=$(omitFinalSlash "$TARGET")
OUTPUT=$(omitFinalSlash "$OUTPUT")

# curent directory
PWD=$(pwd)

# 압축파일 생성 디렉토리가 상대경로인 경우
# if [[ $OUTPUT != /* ]];
if [ "$TARGET" == "$OUTPUT" ];
then
	OUTPUT=""
else
	OUTPUT=$PWD/$OUTPUT
fi
	
cd $TARGET

CMD="eval ls -l | grep -E ^d"

# 압축 대상 지정 디렉토리 확인
if [ ! -z "$INCLUDE" ];
then
	CMD=$CMD" | grep -E \"${INCLUDE/,/|}\""
fi

# 압축 제외 디렉토리 확인
if [ ! -z "$EXCLUDE" ];
then
	CMD=$CMD" | grep -Ev \"${EXCLUDE/,/|}\""
fi

# 디렉토리명만 확보 
CMD=$CMD" | awk '{print \$9}'"

# 디렉토리 조회
DIRS=$($CMD)

for DIR in $DIRS
do
	FILE=$(makePath "$OUTPUT" "$DIR")
	if [ ! -z $SUFFIX ];
	then
		FILE=$FILE"-"$SUFFIX
	fi
	print "============================================================"
	print "$DIR is archiving..."
	print "tar -zcf $FILE.tar.gz $DIR"
	if [ "$DRY_RUN" != "true" ];
	then
		tar -zcf $FILE.tar.gz $DIR
	fi
	print "$DIR is archived!!!"
done

print "============================================================"

exit 0
