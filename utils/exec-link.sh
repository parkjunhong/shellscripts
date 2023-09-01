#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @since  : 2020-03-28
# @license: MIT
# =======================================

assert-empty(){
	if [ -z "$1" ];then
		echo "'$2' does not exist."
		exit 0
	fi
}

LN_ABS_PATH=$(command -v $1)
assert-empty "$LN_ABS_PATH" "$1"
LINK_PATH=$(readlink -f $LN_ABS_PATH)
assert-empty "$LINK_PATH" "$LN_ABS_PATH"
EXEC_DIR=$(dirname $LINK_PATH)
cd "$EXEC_DIR"

CMD="$LINK_PATH"
shift 
while [ ! -z "$1" ];do
	CMD="$CMD ""$1"""
	shift
done

eval $CMD

exit 0
