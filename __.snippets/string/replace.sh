#!/usr/bin/env bash

# 'replace' strings.
echo "=== Replace strings ==="
echo
# first of $OLD
echo "> First of: \${STRING/\$OLD/\$NEW}"
# all of $OLD
echo "> All of  : \${STRING//\$OLD/\$NEW}"

# example
STRING="1+2+3+4"

OLD="+"
NEW="/"

echo
echo "string=$STRING"
echo "old   =$OLD"
echo "new   =$NEW"

# first of $OLD
FIRST=${STRING/$OLD/$NEW}
# all of $OLD
ALL=${STRING//$OLD/$NEW}

echo
echo "FIRST=$FIRST"
echo "ALL  =$ALL"

exit 0