#!/usr/bin/env bash

#
# $1 {string}: a string to be trimmed.
# $return 'echo'
trim(){
	if [ $# -lt 1 ];
	then
		echo
		return 0
	fi
  
	local str=$1
	# trim from beginning
	while [[ $str == ' '* ]];
	do
		str="${str## }"
	done
	# trim from end
	while [[ $str == *' ' ]];
	do
		str="${str%% }"
	done
	
	echo "${str}"
}

STR=" HI! "
echo ">${STR}<"
STR=$(trim "${STR}")
echo ">${STR}<"

exit 0
