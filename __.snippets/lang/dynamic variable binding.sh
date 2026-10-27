#!/usr/bin/env bash

# dynamic variable binding
var1=""

# $1 {string} variable name
# $2 {any} value
assign(){
    _v=\$$1
    echo "assign()._v=$_v"
    _val=$(eval echo $_v)
    if [ -z "$_val" ];
    then
        echo "not assigned"
    else
        echo "$_v.current=$_val"
    fi

    echo "eval $1=\"$2\""
    eval $1=\"$2\"
}

echo
assign var1 hi
echo "var1=$var1"

echo
assign var1 "nice to meet u"
echo "var1=$var1"

echo
assign var1 "me, too"
echo "var1=$var1"