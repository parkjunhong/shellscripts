#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @since  : 2020-03-28
# @license: MIT
# =======================================



LN_ABS_PATH=$(command -v $1)
EXEC_DIR=$(dirname $(readlink -f $LN_ABS_PATH))
cd "$EXEC_DIR"

CMD="$LN_ABS_PATH"
shift 
while [ ! -z "$1" ];do
	CMD="$CMD ""$1"""
	shift
done

eval $CMD

exit 0
