#!/usr/bin/env bash

GLOBAL_REMATCH=""
global_rematch() {
    local s=$1 regex=$2
    while [[ $s =~ $regex ]];
    do
        GLOBAL_REMATCH="$GLOBAL_REMATCH '${BASH_REMATCH[1]}'"
        s=${s#*"${BASH_REMATCH[1]}"}
    done
}

re="(\\\$\{[^\}]+\})"
str="/usr/lib/systemd/system/\${service.name}.service/\${profile}/profile.config"

global_rematch "$str" "$re"

echo $GLOBAL_REMATCH

exit 0
