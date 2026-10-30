#!/usr/bin/env bash

# 전달받은 파라미터의 3번째부터 처리 하는 예제

# $1 {string} service template file pathname
# $2 {string} config file pathname
# $3 {array} array of config name
apply_confs(){
    local args=(${@})
    for conf in "${args[@]:2}";
    do
    	echo "conf=$conf"
    done
}


# 중복된 값을 제거하는 
# @param $1 <string> a name of an array
# @return by 'echo' command
create-set(){
    ar="\${$1[@]}"
    for v in $(eval "echo ${ar}");
    do
        echo "$v";
    done|sort|uniq|xargs
}
