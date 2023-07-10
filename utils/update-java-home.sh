#!/usr/bin/env bash

JAVA_PATH=$(command -v java)
JAVA_PATH_LS=($(ls -l $JAVA_PATH))

FILE_MODE="${JAVA_PATH_LS[0]}"
while [[ $FILE_MODE == l* ]]
do
	JAVA_PATH="${JAVA_PATH_LS[-1]}"
	JAVA_PATH_LS=($(ls -l $JAVA_PATH))
	FILE_MODE="${JAVA_PATH_LS[0]}"
done

JAVA_PATH="${JAVA_PATH_LS[-1]}"
_JAVA_HOME_=${JAVA_PATH/\/jre\/bin\/java//}
_JAVA_HOME_=${_JAVA_HOME_/\/bin\/java//}

echo ${_JAVA_HOME_}

exit 0
