#!/bin/bash

usage(){
    echo
    echo ">>> CALED BY [[ $1 ]]"
    echo
    echo "[Usage]"
    echo
    echo "./apply-properties.sh -c <properties file> -t <target template file> -v -l <logging file>"
    echo
    echo "[Options]"
    echo " -c, --config      : Properties configuration file "
    echo " -t, --template    : Template file"
    echo " -v, --verbose     : print log"
    echo " -l, --logging-file: loging file" 
    echo " -h, --help        : Help"
    echo
}

while [ "$1" != "" ];
do
	case $1 in
		-c | --config)
			shift
			CONFIG_FILE=$1
			;;
		-t | --template)
			shift
			TEMPLATE_FILE=$1
			;;
		-h | --help)
			usage "--help"
			exit 0
			;;
		*)
			usage "Invalid option. option: $1"
			exit 1
			;;
	esac
	shift
done

# validate configrations and template file
if [ -z "$CONFIG_FILE" ] ||  [ -z "$TEMPLATE_FILE" ];
then
    usage "Invalid parameters."
    exit 1
fi

# validate logging parameters 
if [ "$VERBOSE" == true ] && [ -z "$LOGGING_FILE" ];
then
    usage "Invalid logging parameters."
    exit 1
fi

# logging message.
logging(){
    if [ "$VERBOSE" == "true" ];
    then
        echo "[$1] $2" >> "$LOGGING_FILE"
    fi
}


# Pattern: ${...}
REGEX_PROP_REF="\\\$\{([^\}]+)\}"
GLOBAL_REMATCH=""

# $1 {string} string
# $2 {string} regular expression
global_rematch() {
	GLOBAL_REMATCH=""
	local str="$1" regex="$2"
	
	while [[ $str =~ $regex ]];
	do
		if [ -z "$GLOBAL_REMATCH" ];
		then
			GLOBAL_REMATCH="${BASH_REMATCH[1]}"
		else
			GLOBAL_REMATCH="$GLOBAL_REMATCH ${BASH_REMATCH[1]}"
		fi
		str=${str#*"${BASH_REMATCH[1]}"}
	done
}

# $1 {string} absolute file path.
# $2 {string} prop_name
# $3 {any} default_value
prop(){
	local property=$(grep -v -e "^#" ${1} | grep -E "^${2}=" | cut -d"=" -f2-)

	if [ -z "$property" ] && [ ! -z "$3" ]; then
		echo $3
	else
		echo $property
	fi
}

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
				property=${property//\$\{$ref\}/$ref_value}
			fi
		done
		echo $property
	fi
}

# $1 {string} service template file pathname
# $2 {string} config file pathname
# $3 {string} config name
apply_conf(){
	local property=$(read_prop "$2" "$3")
	echo "	$3 ---> $property"
	property=${property//\//\\\/}
	# format of a variable in xxx.service file is ${variable_name}.
	eval "sed -i 's/\${$3}/$property/g' $1"
}

# $1 {string} service template file pathname
# $2 {string} config file pathname
# $3 {array} array of config name
apply_confs(){
	local args=(${@})
	for conf in "${args[@]:2}";
	do
		apply_conf "$1" "$2" "$conf"
	done
}


config_comment=('comment.title' 'comment.service_name')
config_unit=('unit.description' 'unit.after')
config_service=('service.type' 'service.user' 'service.group')
config_command=('command.exec_start' 'command.exec_stop')
config_install=('install.wantedby')

echo
echo " ... started 'comment'"
apply_confs $TEMPLATE_FILE $CONFIG_FILE "${config_comment[@]}"
echo " ... completed"
echo 
echo " ... started 'unit'"
apply_confs $TEMPLATE_FILE $CONFIG_FILE "${config_unit[@]}"
echo " ... completed"
echo
echo " ... started 'service'"
apply_confs $TEMPLATE_FILE $CONFIG_FILE "${config_service[@]}"
echo " ... completed"
echo
echo " ... started 'command'"
apply_confs $TEMPLATE_FILE $CONFIG_FILE "${config_command[@]}"
echo " ... completed"
echo
echo " ... started 'install'"
apply_confs $TEMPLATE_FILE $CONFIG_FILE "${config_install[@]}"
echo " ... completed"

exit 0
