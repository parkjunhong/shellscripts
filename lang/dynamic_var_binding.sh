#!/bin/bash

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

## check & enable cmd-options
# @param $1 {string}: a variable name of 'CMD-Option'
# @param $2 {any}   : a expected current value'
# @param $3 {any}   : a value if checking is passed.
# @param $4 {string}: error message
enable-cmd-option(){
  _v=\$$1
  _val=$(eval echo $_v)
  if [ -z "$_val" ];
  then
    echo
    echo " * * * '$_v' does not exist or is not assigned."
    eval $1=\"$2\"
    _val=$(eval echo $_v)
  fi  

  if [ "$_val" == "$2" ];
  then
    eval $1=\"$3\"
  else
    echo
    echo " * * * '$_v' has a unexpected value. value=$_val"
    help "$4"
    exit 1
  fi  
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
