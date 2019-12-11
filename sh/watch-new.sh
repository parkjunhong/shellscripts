#!/bin/bash

help(){
    echo "[Usage]"
    echo "./watch-new.sh -n {interval} {command}"
    echo "-n|--interval: refresh interval. (unit: second, positive integer)"
    echo "command: command to be executed."
    echo
}

INTERVAL=1
CMD=""
while [ "$1" != "" ]; do
    case $1 in
        -n | --interval)
            shift
            INTERVAL=$1
            ;;
        -h | --help)
            help
            exit 0
            ;;
        *)
            if [ ! -z "$CMD" ];
            then
                CMD=$CMD" "
            fi
            CMD=$CMD""$1
            ;;
    esac
    shift
done

RE_POS_INTEGER='^[0-9]$'
if ! [[ $INTERVAL =~ $RE_POS_INTEGER ]];
then
    help
    exit 1
fi

# clear screen
clear

exec(){
    _date=$(date)
    echo "Every "$INTERVAL"s: $CMD ${_date:-0}"
    echo
    eval $CMD
}

while [ 1 ];
do
    exec
    sleep $INTERVAL
    clear
done
