#!/bin/bash

# $1 {string} variable name
# $2 {any} value
assign(){
    eval $1=\"$2\"
}

# Pattern: ${...}
GLOBAL_REMATCH=""
# $1 {string} string
# $2 {string} regular expression
global_rematch() {
	GLOBAL_REMATCH=""
	local str="$1"
	local regex="$2"
	
	while [[ $str =~ $regex ]];
	do
		if [ -z "$GLOBAL_REMATCH" ];
		then
			GLOBAL_REMATCH="${BASH_REMATCH[1]}"
		else
			GLOBAL_REMATCH="$GLOBAL_REMATCH ${BASH_REMATCH[1]}"
		fi
		local str=${str#*"${BASH_REMATCH[1]}"}
	done
}

## 설정파일 읽기
# $1 {string} file
# $2 {string} prop_name
# $3 {any} default_value
prop(){
	local property=""
	# 1. profile 에 기반한 설정부터 조회 
	if [ ! -z "$PROFILE" ];
	then
		local property=$(grep -v -e "^#" ${1} | grep -e "^${2}\.$PROFILE=" | cut -d"=" -f2-)
	fi
	
	# 2. profile에 기반한 설정이 없는 경우 기본 설정조회
	if [ -z "$property" ];
	then
		local property=$(grep -v -e "^#" ${1} | grep -e "^${2}=" | cut -d"=" -f2-)
		
		# 3. 기본설정이 없고 함수 호출시 기본값이 있는 경우
		if [ -z "$property" ] && [ ! -z "$3" ];
		then
			echo $3
		else
			echo $property
		fi
	else
		echo $property
	fi
}

REGEX_PROP_REF="\\\$\{([^\}]+)\}"
# $1 {string} absolute file path.
# $2 {string} prop_name
# $3 {any} default_value
read_prop(){
	local property=$(prop "$1" "$2" "$3")
	global_rematch "$property" "$REGEX_PROP_REF"
	
	if [ -z "$GLOBAL_REMATCH" ];
	then
		echo $property
	else
		local references=($(echo $GLOBAL_REMATCH))
		for ref in "${references[@]}";
		do
			local ref_value=$(read_prop "$1" "$ref")
			if [ ! -z "$ref_value" ];
			then
				local property=${property//\$\{$ref\}/$ref_value}
			fi
		done
		echo $property
	fi
}

# Replace a old string to a new string.
# $1 {string} file path
# $2 {string} old string
# $3 {string} new string
update_property(){
	echo
	echo "-------- ${FUNCNAME[0]} --------"
	echo $@

	# 데이터에 경로구분자(/)가 포함된 경우 변경
	local targetfile=$1
	local oldstr=$2
	local newstr=$3
	local newstr=${newstr//\//\\\/}
	# format of a variable in xxx.service file is ${variable_name}.
	eval "sed -i 's/\${$oldstr}/$newstr/g' $targetfile" 
}



# $1 {string} string
# $2 {string} variable
unwrap_quote(){
	global_rematch "$1" "^\"([^\"]+)\"$"
	if [ -z "$GLOBAL_REMATCH" ];
	then
		global_rematch "$1" "^'([^']+)'$"
	fi

	if [ ! -z "$GLOBAL_REMATCH" ];
	then
		assign "$2" "$GLOBAL_REMATCH"
	fi
}


# Replace a old string to a new string.
# $1 {string} file path
# $@:1 {any} properties
update_properties(){
	echo
	echo "-------- ${FUNCNAME[0]} --------"
	echo "arguments=$@"
	
	local targetfile="$1"
	local arguments=(${@})
	local prop_value=""
	
	printf "	%-30s = %s\n" "filename" "$targetfile"
	
	for prop in "${arguments[@]:1}";
	do
		unwrap_quote "$prop" "prop"

		local prop_value=$(read_prop "$CONFIG_FILE" "$prop")
		if [ ! -z "$prop_value" ];
		then
			printf "	%-30s = %s\n" "$prop" "$prop_value"
			update_property "$targetfile" "$prop" "$prop_value"	
		fi
	done
	
	echo "--------------------------------"
}

# check a file exists.
# $1 {string} filepath
# $2 {number} exit value
check_file_then_exit(){
	if [ ! -f "$1" ];
	then
		echo
		echo "[A file DOES NOT EXIST] file="$1
		
		exit $2
	fi
}

# check a directory exists.
# $1 {string} directory path
# $2 {number} exit value
check_dir_then_exit(){
	if [ ! -d "$1" ];
	then
		echo
		echo "[A directory DOES NOT EXIST] directory="$1
		
		exit $2
	fi
}

# $1 {string} full filepath
# $@:1 {any} properties
update_file(){
	echo
	echo "-------- ${FUNCNAME[0]} --------"
	echo "arguments=$@"

	local targetfile=$1
	
	if [ -f "$targetfile" ];
	then
		echo
		echo "[DETECTED] $targetfile"
		update_properties  $@
	fi
}

TARGET_FILE="crontab.cron"
CONFIG_FILE="service.properties"

CRON_PROPERTIES=$(read_prop "$CONFIG_FILE" "cron.configuration.properties")

echo
echo "cron.properties=$CRON_PROPERTIES"

update_file "$TARGET_FILE" $CRON_PROPERTIES

exit 0

