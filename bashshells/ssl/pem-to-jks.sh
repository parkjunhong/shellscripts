#!/bin/bash

echo
echo "=============================================="
echo "=== Convert PEM to JKS" 
echo "=== Author: fafanmama@naver.com, parkjunhong77@gmail.com"
echo "=== LICENSE: MIT"
echo "=== DATE: 2018.12.20"

usage(){
    echo
    echo ">>> CALLED BY [[ $1 ]]"
    echo
    echo "[Usage]"
    echo
    echo "./pem-to-jks -pi {pem-file} -pk {pem-key-file} -jks {jks-output}"
    echo
    echo "[Option]"
    echo " -pi  | -in           : PEM Certification file."
    echo " -pk  | -inkey        : PEM Certification Key file."
    echo " -jks | -destkeystore : JKS output name."
    echo " -h   | --help        : help messages"

}

# If no parameter.
if [ $1 -lt 1 ];
then
    usage "No Parameter."
    exit 1
fi

## Read parameters
while [ "$1" != "" ]; do
    case $1 in
    -pi | -in)
        shift
        PEM_IN=$1
        ;;
    -pk | -inkey)
        shift
        PEM_INKEY=$1
        ;;
    -jks | -destkeystore)
        shift
        JKS_OUTPUT=$1
        ;;
    -h | --help)
        usage "--help"
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
	pine "-pi" "$PEM_IN"
	pine "-pk" "$PEM_INKEY"
	pine "-jks" "$JKS_OUTPUT"
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
			usage "function 'validate not empty'. name: $1, value: $2"
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
		usage "function 'validate not file'. name: $1, value: $2"
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

# validate p12 output
P12_OUTPUT=$(uuidgen).p12
P12_PASSWD=$P12_OUTPUT

sleep 0.5

# validate jks output
echo 
echo " >>> validate 'jks output name'"
validate_name "JKS Output" $JKS_OUTPUT

# check file extension
EXT=$(echo "$JKS_OUTPUT" | rev | cut -d '.' -f1 | rev | tr '[:upper:]' '[:lower:]')

if [ "$EXT" != "jks" ];
then
	JKS_OUTPUT=$JKS_OUTPUT".jks"
fi

# check already exists
if [ -e $JKS_OUTPUT ];
then
	echo
	read -p " !!! '$JKS_OUTPUT' already EXISTs. DO REMOVE a '$JKS_OUTPUT' ??? (y/n) " answer

	if [ "$answer" != "${answer#[Y/y]}" ];
	then
		echo 
		echo " !!! rm -rf $JKS_OUTPUT"
		rm -rf $JKS_OUTPUT
	else
		echo
		echo "Check a value of a '-jks | --jks-output' option."
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

# read a password for 'jks'.
echo
read -p " !!! Insert a password for 'JKS' file: " JKS_PASSWD
echo " >>> validate 'jks password'"
validate_name "JKS Password" $JKS_PASSWD "allow"

clear_temp(){
	echo
	echo " !!! rm -rf $P12_OUTPUT"
	rm -rf $P12_OUTPUT
}

clear(){
	clear_temp
	echo " !!! rm -rf $JKS_OUTPUT"
	rm -rf $JKS_OUTPUT
}

echo
echo " >>> clear old files..."
clear

# exeucte command
# param $1: command
# param $2: additional parameter
# param $3: additional parameter's value
execute(){
	CMD=$1
	if [ ! -z $3 ];
	then
		CMD=$CMD" "$2$3
	fi
	echo " >>> $CMD"
	eval $CMD
}

# 1 'pem' to 'p12'
echo
{
	CMD="openssl pkcs12 -export -out $P12_OUTPUT -passout pass:$P12_PASSWD -in $PEM_IN -inkey $PEM_INKEY"
	execute "$CMD" "-passin pass:" "$PEM_PASSWD"
}||{
	clear
	exit 1
}

sleep 0.5

echo
echo " >>> check *.p12 file."
{
	ls -l $P12_OUTPUT
}||{
	echo
	echo " !!! FAIL to convert 'pem' to 'p12'"
	
	clear 
	exit 1
}

sleep 0.5

# 2. 'p12' to 'jks'
echo
{
	CMD="keytool -importkeystore -srckeystore $P12_OUTPUT -srcstoretype pkcs12 -srcstorepass $P12_PASSWD -destkeystore $JKS_OUTPUT -deststoretype jks"
	execute "$CMD" "-deststorepass " "$JKS_PASSWD"
}||{
	clear
	exit 1
}

echo
echo " >>> check *.jks file."
{
	ls -l $JKS_OUTPUT
}||{
	echo 
	echo " !!! FAIL to convert 'p12' to 'jks'"

	clear
	exit 1
}

sleep 0.5

# 3. check 'jks'
echo
{
	CMD="keytool -list -keystore $JKS_OUTPUT"
	execute "$CMD" "-storepass " "$JKS_PASSWD"
}||{
	clear
	exit 1
}

sleep 0.5

clear_temp

echo
echo " <<< Completed...."

exit 0
