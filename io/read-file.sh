#!/bin/bash

# =============================================
# @author: parkjunhong77@gmail.com
# @since : 2020-02-02
# @title : 파일 읽기
# =============================================


# 읽을 파일
FILE=$1

# 라인 넘버
ln=0
while IFS= read -r line
do
  ((ln++))
  echo ${line}
done < "${FILE}"

exit 0
