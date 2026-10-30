#!/usr/bin/env bash

# 'starts with'
[[ $STRING == z* ]]   # True if $STRING starts with an "z" (pattern matching).
[[ $STRING == "z*" ]] # True if $STRING is equal to z* (literal matching).

[ $STRING == z* ]     # File globbing and word splitting take place.
[ "$STRING" == "z*" ] # True if $STRING is equal to z* (literal matching).
