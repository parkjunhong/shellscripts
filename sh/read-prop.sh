#!/usr/bin/env bash

# $1 {string} absolute file path.
# $2 {string} prop_name
# $3 {any} default_value
prop(){
    _value=$(grep -v -e "^#" ${1} | grep -w "${2}" | cut -d"=" -f2-)

    if [ -z "$_value" ] && [ ! -z "$3" ]; then
        echo $3
    else
        echo $_value
    fi
}

PROP_FILE=$1
PROP=$2
PROP_VALUE=$(prop "$PROP_FILE" "$PROP")

echo "$PROP=$PROP_VALUE"

exit 0
