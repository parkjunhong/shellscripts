# GOGO

STRING="1-2-3-4"

# 'split'
DELIM="-"
INDEX="1"
cut -d'$DELIM' -f$INDEX <<< $STRING

# 'reverse'
echo $STRING | rev

# 'replace'
OLD="-"
NEW="+"
# first of $OLD
${STRING/$OLD/$NEW}
# all of $OLD
${STRING//$OLD/$NEW}


# 'starts with'
[[ $STRING == z* ]]   # True if $STRING starts with an "z" (pattern matching).
[[ $STRING == "z*" ]] # True if $STRING is equal to z* (literal matching).

[ $STRING == z* ]     # File globbing and word splitting take place.
[ "$STRING" == "z*" ] # True if $STRING is equal to z* (literal matching).


# dynamic variable binding
var1=""

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





[Advanced Bash-Scripting Guidet](http://tldp.org/LDP/abs/html/comparison-ops.html)