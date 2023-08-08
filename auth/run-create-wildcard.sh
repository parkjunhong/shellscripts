#!/bin/env bash

#
# @param $1 {string} 삭제할 디렉토리
check-and-delete(){
    local dir="$1"
    if [[ $dir != /* ]]; then
        dir=$(pwd)"/$dir"
    fi  

    if [ ! -d $dir ];then
        echo
        echo "올바르지 않은 경로입니다. dir=$dir"
        exit 1
    fi  

    echo
    echo "'$dir' 경로를 삭제하기 전에 내용을 확인하기 바랍니다."
    echo
    ls -al $dir
    echo
    local confirm=""
    while [ -z $confirm ];
    do
        read -p "'$dir' 경로를  삭제하시겠습니까? (y/n) " confirm
        confirm=$(echo $confirm | tr [:lower:] [:upper:])
    done
    
    if [ "Y" = $confirm ];then
        rm -rfv $dir
    fi  
}

# archive 삭제
check-and-delete "archive"

# live 삭제
check-and-delete "live"

# renewal 삭제
check-and-delete "renewal"

# 새로운 인증서 발급
echo
echo "* * * 인증서 발급 * * *"
./create-wildcard.sh

# 인증서 배포
echo
echo "* * * 인증서 배포 * * *"
./send-certificate.sh


echo
echo "* * * 'ymtech.co.kr' wildcard 인증서 발급/배포 완료 * * *"
exit 0
