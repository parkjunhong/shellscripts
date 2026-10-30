#!/usr/bin/env bash

# 'split'
echo
echo "# 'split'"
echo "cut -d\"\$DELIM\" -f\$INDEX <<< \$STRING"
echo 
echo "[options]"
echo " - DELIM : 구분자"
echo " - INDEX : 얻고자하는 순서"
echo " - STRING: 문자열"

# example

STRING="a1-b2-c3-d4"
DELIM="-"
INDEX="1"

echo "string =$STRING"
echo "delim  =$DELIM"
echo "index  =$INDEX"

echo "cut -d\"$DELIM\" -f$INDEX <<< $STRING"
cut -d"$DELIM" -f$INDEX <<< $STRING

exit 0