#!/usr/bin/env bash

# =======================================
# @auther: parkjunhong77@gmail.com
# @since: 2020-01-16
# =======================================

help(){
	echo
	if [ $# -gt 0 ];
	then
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
		echo "[ERROR] $@"
		echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
		echo
	fi

	echo "Usage:"
	echo " cp2bin.sh <command> [-u] [-f]"
	echo
	echo "[Arguments]"
	echo " command: a command to be copied to."
	echo
	echo "[Options]"
	echo " -f | o: Force to copy a command to a destination diectory."
	echo " -u | o: Copy to user bin directory"
	echo
}

ARGUMENTS=()
USER_DIR=0
ARG_COMMAND=""
IDX=0
while [ "$1" != "" ];
do
	case $1 in
		-h | --help | "/h")
			help
			exit 0
			;;
		-u)
			USER_DIR=1
			;;
		*)	
			if [ "$IDX" == 0 ];
			then
				ARG_COMMAND="$1"
			fi
			((IDX++))
			;;
	esac
	shift
done

if [ -z "${ARG_COMMAND}" ] || [ ! -f "${ARG_COMMAND}" ];
then
	help "Invalid a command path. path=${ARG_COMMAND}"
	exit 1
fi

IFS="/" read -ra CMD_AR <<< "${ARG_COMMAND}"
if [ ${#CMD_AR[@]} -gt 1 ];
then
	cmd="${CMD_AR[((${#CMD_AR[@]}-1))]}"
else
	cmd="${ARG_COMMAND}"
fi

# command -v: retrieve ${user.home} at first.i
#location=$(command -v ${cmd} 2> /dev/null)
# which : retreive /usr/* at first.
location=$(which ${cmd} 2> /dev/null) 

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
# $1 {string}: source
# $2 {string}: destination
# $3 {number}: user or not. 0: user, 1: suudo
cp_command(){
	local src="$1"
	local dest="$2"
	if [ "$#" -eq 3 ] && [ "$3" -eq 0 ];
	then
		local _sudo_="sudo"
	fi
	if [ -f ${dest} ];
  	then
    		echo
    		echo "${dest} is NOT a directory but a file."
    		exit 1
  	elif [ ! -d ${dest} ];
  	then
    		eval ${_sudo_} mkdir ${dest}
  	fi
	
	echo
	echo "${_sudo_} cp ${src} ${dest}/"
	eval ${_sudo_} cp ${src} ${dest}"/"
}

# check a location and decide a destination.
echo
if [ -z "${location}" ];
then
	echo " > '$(pwd)/${ARG_COMMAND}' does not exist!"

	if [ "${USER_DIR}" = "1" ];
	then
		DEST="$(echo ~)/bin/"
	else
		DEST="/usr/bin/"
	fi
else
	echo " > '$(pwd)/${ARG_COMMAND}' already exists at ${location}"
	# 1. Legacy:	${location}
	# 2. New   :	${SYS_DIR}
	if [ "${USER_DIR}" = "1" ];
	then
		sys_dir="$(echo ~)/bin"
	else
		sys_dir="/usr/bin"
	fi

	if [ "${location}" == "${sys_dir}/${cmd}" ];
	then
		echo
		read -p " > Copy a command to a destination anyway? (y|n) " answer
		if [ "y" != "$(echo ${answer} | tr [:upper:] [:lower:])" ];
		then
			echo
			echo " > Bye~"
			exit 0			
		fi
		DEST=$(find_ppath ${location})
	else
		echo
		echo " > Where do you want to copy a command to ?"
		echo " > 1. Legacy : ${location}"
		echo " > 2. Suggest: ${sys_dir}/${cmd}"
		echo
		read -p " > Select a destination.? (1|2, Others termiante the process.) " answer
		case ${answer} in
			1)
				#DEST="${location}"
				DEST=$(find_ppath ${location})
				;;
			2)
				DEST="${sys_dir}"
				;;
			*)
				exit 0
				;;
		esac
	fi
fi	

cp_command "${ARG_COMMAND}" "${DEST}" "${USER_DIR}" 

echo
echo " > Completed !!!"

exit 0
