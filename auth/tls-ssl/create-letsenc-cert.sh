#!/bin/bash

# =============================================
# @author: parkjunhong77@gmail.com
# @since : 2020-03-31
# @title : Create a Let's Encrypt Certification.
# =============================================

# Check whether a user is a 'root' or not.
if (( $EUID != 0 )); then
    echo
    echo "You MUST run this script as a 'ROOT' or 'sudoers'".
    echo
    echo "Fail to nping to a target."

    exit 100
fi

usage(){
    if [ $# -gt 0 ];
    then
        echo
        echo "Caller: ${FUNCNAME[1]}, cause: $1"
    fi
    echo
    echo "./certbot-standalone.sh -ds <domains> -f <filepath>"
    echo
    echo "[Options]"
    echo " -ds | --domains: domains. Separated by comma(,)."
    echo " -f  | --file   : a file contains domains. Separated by new line."
    echo
}

DOMAINS=""
FILE=""
while [ "$1" != "" ]; do
    case $1 in
        -ds | --domains)
            shift
            DOMAINS=$1
            ;;
        -f | --file)
            shift
            if [ ! -f $1 ];
            then
                usage "Invalid a filepath. filepath=$1"
                exit 1
            fi
            FILE=$1
            ;;
        -h | --help)
            usage "--help"
            exit 0
            ;;
        *)
            usage "Unsupported argument. argument=$1"
            exit 1
            ;;
    esac
    shift
done

if [ -z ${DOMAINS} ] && [ -z ${FILE} ] ;
then
    usage "No arguments"
    exit 1
fi

# Simple Regular Expression for Domain Name
DN_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"

DOMAIN_ARR=()


# read from '-f' arguments, a file.
while IFS= read -r domain
do
    if [ ! -z ${domain} ];
    then
        DOMAIN_ARR+=("${domain}")
    fi
done < "${FILE}"

# read from '-ds' arguments
while IFS="," read -r domain
do
    if [ ! -z ${domain} ];
    then
        DOMAIN_ARR+=("${domain}")
    fi
done <<< "${DOMAINS}"

# @param $1 <string> a name of an array
create-set(){
    ar="\${$1[@]}"
    for v in $(eval "echo ${ar}");
    do
        echo "$v";
    done|sort|uniq|xargs
}

DOMAIN_ARR=($(create-set "DOMAIN_ARR"))

for domain in ${DOMAIN_ARR[@]}
do
    if [[ ! ${domain} =~ ${DN_REGEX} ]];then
        echo "[Invalid] ${domain}"
    else
        echo
        echo "=========================================================================="
        echo ">>>>>> Start '${domain}' Let's Encrypt Certificate"
        echo
        certbot certonly --standalone -d ${domain}
        echo
        echo "<<<<<< Finished ${domain}"
        echo "=========================================================================="
    fi
done

exit 0
