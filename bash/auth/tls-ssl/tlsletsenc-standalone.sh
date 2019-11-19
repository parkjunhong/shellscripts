#!/bin/bash

# Check whether a user is a 'root' or not.
if (( $EUID != 0 )); then
        echo
        echo "You MUST run this script as a 'ROOT' or 'sudoers'".
        echo
        echo "Fail to nping to a target."

        exit 100
fi

usage(){
	echo
	echo "./certbot-standalone.sh -ds {domains}"
	echo 
	echo "[Options]"
	echo " -ds | --domains: domains. Separated by comma(,)."
	echo	
}

DOMAINS=""
while [ "$1" != "" ]; do
    case $1 in
        -ds | --domains )
            shift
            DOMAINS=$1
            ;;
        -h | --help)
            usage "--help"
            exit 0
            ;;
        *)
			usage "Unsupported argument."
			exit 1
            ;;
    esac
    shift
done

if [ -z $DOMAINS ];then
	usage "No arguments"
	exit 1
fi 

# Simple Regular Expression for Domain Name
DN_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"

DOMAIN_ARR=$(echo $DOMAINS | tr "," "\n")

for domain in $DOMAIN_ARR
do
    if [[ ! $domain =~ $DN_REGEX ]];then
		echo "[Invalid] $domain"
	else
	    echo
		echo "=========================================================================="
		echo ">>>>>> Start '$domain' Let's Encrypt Certificate"
		echo
		certbot certonly --standalone -d $domain
		echo
		echo "=========================================================================="
		echo "<<<<<< Finished $domain"
	fi
done

exit 0

	
