#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com fafanmama@naver.com
# @title  : Convert Let's Encrypt Certification PEM file to PKCS12 file.
# @license: Apache License 2.0
# @since  : 2018-12-20
# @desc   : support macOS 11.2.3, Ubuntu 18.04, CentOS 7 or higher
# @completion: pemtop12.completion
#			 1. insert 'source <path>/pemtop12.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#			 2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

# get a filename
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
    echo "./pem-to-p12 -pi {pem-file} -pk {pem-key-file} -pc {pem-chain-file} -out {pkcs12-output} -pwd {pkck12-password}"
    echo
    echo "[Option]"
    echo " -pi  : PEM Certification file."
    echo " -pk  : PEM Certification Key file."
	echo " -pc  : PEM Chain file."
    echo " -out : PKCS12 output name."
	echo " -pwd : PKCS12 password"
    echo " -h   | --help  : help messages"
}


# If no parameter.
if [ $# -lt 1 ];
then
    help "No Parameter." $LINENO
    exit 1
fi

## Read parameters
while [ "$1" != "" ]; do
    case $1 in
    -pi)
        shift
        PEM_IN="$1"
        ;;
    -pk)
        shift
        PEM_INKEY="$1"
        ;;
	-pc)
		shift
		PEM_CAFILE="$1"
		;;
    -out)
        shift
        P12_FILE="$1"
        ;;
    -pwd)
        shift
        P12_PWD="$1"
        ;;
    -h | --help)
        help
        exit 0
        ;;
    esac
    shift
done

# print if not empty
pine(){
	if [ ! -z $2 ];
	then
		echo " >>> $1: $2"
	fi
}

print_params(){
	pine "-pi (pem's certificate)" "$PEM_IN"
	pine "-pk (pem's private key)" "$PEM_INKEY"
	pine "-ca (pem's chain)" "$PEM_CAFILE"
	pine "-out (pkcs12's file)" "$P12_FILE"
	pine "-pwd (pkcs12's password)" "$P12_PWD"
}


# function: validate if $2 is not empty
# param $1: name
# param $2: value
# param $3: 'allow'.
validate_name(){
	if [ -z "$2" ];
	then
		if [ "$3" != "allow" ];
		then
			help "function 'validate not empty'. name: $1, value: $2" $LINENO
			exit 1
		fi
	else
		echo " !!! validated name. name: $1, value: $2"
	fi
}

# function: validate if $2 is not a file.
# param $1: name
# param $2: value
validate_file(){
	if [ ! -f "$2" ];
	then
		help "function 'validate not file'. name: $1, value: $2" $LINENO
		exit 1
	else
		echo " !!! validated file. name: $1, value: $2"
	fi
}



# validate_name certification & key
echo
echo " >>> validate 'certification.pem'"
validate_file "Certification" $PEM_IN

sleep 0.5

echo
echo " >>> validate 'certification key.pem'"
validate_file "Certification Key"  $PEM_INKEY

sleep 0.5

echo
echo " >>> validate 'chain file.pem'"
validate_file "Chain file"  $PEM_CAFILE

sleep 0.5

# check already exists
if [ -e $P12_FILE ];
then
	echo
	read -p " !!! '$P12_FILE' already EXISTs. DO REMOVE a '$P12_FILE' ??? (y/n) " answer

	if [ "$answer" != "${answer#[Y/y]}" ];
	then
		echo 
		echo " !!! rm -rf $P12_FILE"
		rm -rf $P12_FILE
	else
		echo
		echo "Check a value of a '-p12 | -pkcs12' option."
		echo
		print_params
		
		exit 1
	fi
fi

sleep 0.5

# read a password for 'pem'.
echo
read -p " !!! Insert a password for 'PEM' file: " PEM_PASSWD
echo " >>> validate 'certification password'"
validate_name "Certification Password" $PEM_PASSWD "allow"

sleep 0.5

# exeucte command
# param $1: command
# param $2: additional parameter
# param $3: additional parameter's value
execute(){
	CMD=$1
	if [ ! -z $3 ];
	then
		CMD=$CMD" "$2"\""$3"\""
	fi
	echo " >>> $CMD"
	eval $CMD
}

# look at parameters.
print_params

echo
read -p " !!! All parameters are right ???? (Y/N) " answer

if [ "$answer" != "${answer#[Y/y]}" ]; then
	help
	exit 1
fi

# 'pem' to 'p12'
echo
{
	CMD="openssl pkcs12 -export -out $P12_FILE -passout pass:$P12_PASSWD -in $PEM_IN -inkey $PEM_INKEY -CAfile "
	execute "$CMD" "-passin pass:" "$PEM_PASSWD"
}||{
	clear
	exit 1
}

sleep 0.5

echo
echo " >>> check *.p12 file."
{
	ls -l $P12_FILE
}||{
	echo
	echo " !!! FAIL to convert 'pem' to 'p12'"
	
	clear 
	exit 1
}

echo
echo " <<< Completed...."

exit 0
