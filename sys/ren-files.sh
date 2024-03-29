#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : rename filenames.
# @license: Apache License 2.0
# @since  : 2021-01-07
# @desc   : support Ubuntu 18.04, CentOS 7
# =======================================

CURDIR="$(pwd)"
FILENAME="$0"

usage(){
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
	echo "Change filenames using a regular expression (sed)"
	echo
	echo "[Usage]"
	echo "ren-files.sh -d <directory> -i <input regex> -o <output regex> -f"
	echo
	echo "[Parameters]"
	echo " -d: directory"
	echo " -i: 'sed' regex for input filename(s)."
	echo " -o: 'sed' regex for output filename(s)."
	echo " -f: (optional) rename forcely."
	echo
	echo "[Examples]"
	echo " before: a-b.txt, a-c.txt, b-c.txt"
	echo " [command] ren-files.sh -d . -i '(a)-(.+)' -o '\2-\1'"
	echo " after: b-a.txt, c-a.txt, b-c.txt"
	echo
}

dir="$CURDIR"
regex_input=""
regex_output=""
FORCE=0

while [ "$1" != "" ];
do
	case $1 in
		# directory
		-d)
			shift
			dir="$1"
			;;
		# delete forecely
		-f)
			FORCE=1
			;;
		# regex for target files
		-i)
			shift
			regex_input="$1"
			;;
		# regex for outpt files
		-o)
			shift
			regex_output="$1"
			;;
		*)
			;;
	esac
	shift
done

if [ ! -d "$dir" ];
then
	usage "illegal a directory. input=$dir"
	exit 1 
fi

if [ -z "$regex_input" ] || [ -z "$regex_output" ];
then
	usage "Illegal a regex input or output. input=$regex_input, output=$regex_output" ${LINENO}
	exit 1
fi

#
# create a new filename.
#
# @param $1 filename
# @param $2 input  pattern
# @param $3 output pattern
rename(){
	echo "$1" | sed -r "s#$2#$3#g"
}

# set a target directory.
targetdir=""
if [[ "$dir" == /* ]];
then
	targetdir="$dir"
else
	targetdir="$CURDIR/$dir"
fi

# set 'mv' command.
CMD="mv -v"
if [ $FORCE -eq 1 ];
then
	CMD="$CMD -f"
else
	CMD="$CMD -i"
fi


# rename filename(s).
for file in $(ls $targetdir);
do
	output=$(rename "$file" "$regex_input" "$regex_output")
	
	if [ "$file" != "$output" ];
	then
		srcfile="$targetdir/$file"
		newfile="$targetdir/$output"
		__exec__="$CMD $srcfile $newfile"

		if [ -d "$newfile" ];
		then
			echo "[error] '$newfile' is a directory."
		else
			if [ $FORCE -ne 1 ] && [ -f "$newfile" ];
			then
				printf "[warn] '$srcfile'\n  --> "
			fi
			eval "$__exec__"
		fi
	fi
done

exit 0

