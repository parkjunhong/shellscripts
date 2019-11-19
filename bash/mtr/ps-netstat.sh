#!/bin/bash

WORD=$1

if [ -z "$WORD" ];then
	echo "Input a word to be found."

    exit 1
fi

PS_NAME="["${WORD:0:1}"]"${WORD:1}

PROC_IDS=$(ps -aef | grep "$PS_NAME" | grep -v 'watch' | grep -v 'tail' | awk '{print $2}')

for PROC_ID in $PROC_IDS
do
	netstat -napt | grep $PROC_ID | grep -v 'grep' | grep -v 'tail' | grep [L]ISTEN
done

exit 0
