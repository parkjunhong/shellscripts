#!/usr/bin/env bash

#
# Show help message.
# $1 {string}: error message
help(){
	echo 
	echo "$1"
	echo 
	echo "Usage:"
	echo " cp-suffix [-d|-t] [-e]  <filename> -s <suffix> -o <outputdir>"
	echo
	echo "[Parameters]"
	echo " filename     : absolute/relative filepath."
	echo " -o | --output: Output directory."
	echo " -s | --suffix: user define suffix."
	echo "                If set this, ignore [-d|-t] option."
	echo
	echo "[Options]"
	echo " -d | --date: (optional) Add current 'date' string."
	echo "               e.g.) cp-suffix abc.txt -d -> abc-20200114.txt"
	echo " -e | --ext : (optional) Add a suffix to end of a filename."
	echo "              e.g.) cpsuffix  abc.txt -e -d -> abc.txt-20200114"
	echo " -t | --time: (optional) Add current 'time' string."
	echo "               e.g.) cp-suffix abc.txt -t -> abc-20200114191212.txt"
	echo
}

if [ $# -lt 1 ] || [ $# -gt 7 ];
then
	help "[ERROR] Invalid arguments count."
	exit 1
fi

ARG_FILEPATH=""
ARG_FLAG="-d"
ARG_EXT=0
ARG_OUTPUT=""
ARG_SUFFIX=""
while [ "$1" != "" ];
do
	case $1 in
		-h | --help | "/h" | "/help")
			help
			exit 0
			;;
		-d | --date)
			ARG_FLAG="-d"
			;;
		-e | --ext)
			ARG_EXT=1
			;;
		-o | --output)
			shift
			if [ -f "$1" ];
			then
				help "[Error] Your output directory is not a directory, but actually a file. value='$1'"
				exit 1
			fi
			
			if [ ! -d "$1" ];
			then
				echo
				echo "[WARN] Does not exist your output directory. value=$1"
				read -p "[WARN] Create a new output directory? (y/n) " answer

				if [ "y" == "$(echo ${answer} | tr [:upper:] [:lower:])" ];
				then
					mkdir "$1"
					echo
					echo "[INFO] Created a new output directory. directory=$1"
				else
					echo
					echo "Bye~"
					exit 0
				fi
			fi

			if [[ $1 == */ ]];
			then
				tmp="$1"
				ARG_OUTPUT=${tmp:0:((${#tmp}-1))}
			else
				ARG_OUTPUT="$1"
			fi
			;;
		-s | --suffix)
			shift
			ARG_SUFFIX="$1"
			;;
		-t | --time)
			ARG_FLAG="-t"
			;;
		*)
			if [ -f "$1" ];
			then
				ARG_FILEPATH=$1
			fi
			;;
	esac
	shift
done

if [ -z "${ARG_FILEPATH}" ];
then
	help "[ERROR] Invalid filename. file=${ARG_FILEPATH}"
	exit 1
fi

PATH_DELIM="/"
#
# find a parent path of a filepath.
# @param $1 {string}: filepath.
find_ppath(){
	local args="$@"
	local is_root=0
	if [[ $1 == ${PATH_DELIM}* ]];
	then
		is_root=1
		args="${args:1}"
	fi
	
	# split filepath.
	IFS="${PATH_DELIM}" read -ra fpa <<< "${args}"
	
	if [ ${#fpa[@]} -gt 1 ];
	then
		local pos=$((${#fpa[@]}-1))
		local ppath=""		
		# check that a path is absolute.
		[[ ${is_root} = 1 ]] && ppath=${PATH_DELIM}
		local pathar=(${fpa[@]:0:${pos}})
		for path in "${fpa[@]:0:${pos}}"
		do
			if [ -z ${path} ];
			then
				continue
			fi

			if [ "${ppath}" == "${PATH_DELIM}" ];
			then
				ppath=${ppath}${path}
			elif [ ! -z ${ppath} ];
			then
				ppath=${ppath}${PATH_DELIM}${path}
			# CONFIRM: ${ppath} is empty
			else
				ppath=${path}
			fi
		done
		
		echo "${ppath}"
	else
		if [ ${is_root} == 0 ];
		then
			echo "."
		else
			echo "${PATH_DELIM}"
		fi
	fi
}

#
# find a filename
#
# @param $1 {string}: absolute/relatvie filepath
#
find_filename(){
	local args="$@"
	# split filepath.
	IFS="${PATH_DELIM}" read -ra fpa <<< "${args}"
	if [ ${#fpa[@]} -gt 1 ];
	then
		local pos=$((${#fpa[@]}-1))
		echo "${fpa[${pos}]}"
	else
		echo "$@" 
	fi
}

#
# fine a name of a file.
# @param $1 {string}: filename
#
fine_name_ne(){
	local args="$@"
	local filename=$(find_filename ${args})
	# split filename.
	IFS="." read -ra fna <<< "${filename}"
	if [ ${#fna[@]} -gt 1 ];
	then
		local pos=$((${#fna[@]}-1))
		echo "${fna[@]:0:${pos}}"
	else
		echo "${args[@]}"
	fi
}

#
# Find a extension of a filename.
# @param $1 {string}: filename
# 
find_ext(){
	local args="$@"
	local filename=$(find_filename ${args})
	# split filename.
	IFS="." read -ra fna <<< "${filename}"
	if [ ${#fna[@]} -gt 1 ];
	then
		local pos=$((${#fna[@]}-1))
		echo "${fna[${pos}]}"
	else
		echo
	fi
}

#
# Add a suffix before a extension
#
# @param $1 {string}: filepath
# @param $2 {string}: suffix 
# @param $3 {string}: otuput directory
suffix_before(){
	local filepath="$1"
	local suffix="$2"
	local outputdir="$3"

	local name="$(fine_name_ne ${filepath})"
	local ext="$(find_ext ${filepath})"

	if [ -z "${outputdir}" ];
	then
		outputdir="$(find_ppath ${filepath})"
	fi

	echo "cp \"${filepath}\" \"${outputdir}${PATH_DELIM}${name}-${suffix}.${ext}\""
	eval cp "${filepath}" "${outputdir}${PATH_DELIM}${name}-${suffix}.${ext}"
}

#
# Add a suffix after a extension
#
# @param $1 {string}: filepath
# @param $2 {tsring}: suffix
# @param $3 {string}: otuput directory
suffix_after(){
	local filepath="$1"
	local suffix="$2"
	local outputdir="$3"

	local name="$(fine_name_ne ${filepath})"
	local ext="$(find_ext ${filepath})"

	if [ -z "${outputdir}" ];
	then
		outputdir="$(find_ppath ${filepath})"
	fi

	echo "cp \"${filepath}\" \"${outputdir}${PATH_DELIM}${name}.${ext}-${suffix}\""
	eval cp "${filepath}" "${outputdir}${PATH_DELIM}${name}.${ext}-${suffix}"
}


# check 'suffix flag'.
if [ -z "${ARG_SUFFIX}" ];
then
	case ${ARG_FLAG} in
    	-d | --date)
			SUFFIX=$(date -d'today' '+%Y%m%d')
	        ;;
    	-t | --time)
			SUFFIX=$(date -d'today' '+%Y%m%d%H24%M%S')
	        ;;
    	*)
			help "[ERROR] Invalid flag. flag=${ARG_FLAG}"
			exit 1
    	    ;;
	esac
else
	SUFFIX="${ARG_SUFFIX}"
fi

# check 'user extension'.
if [ "${ARG_EXT}" -eq 1 ];
then
	suffix_after "${ARG_FILEPATH}" "${SUFFIX}" "${ARG_OUTPUT}"
else
	# file extension
	FILE_EXT="$(find_ext ${ARG_FILEPATH})"
	
	if [ -z "${FILE_EXT}" ];
	then
		suffix_after "${ARG_FILEPATH}" "${SUFFIX}" "${ARG_OUTPUT}"
	else
		suffix_before "${ARG_FILEPATH}" "${SUFFIX}" "${ARG_OUTPUT}" 
	fi
fi

exit 0

