#!/bin/bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : analyse nping's verbose.
# @license: Apache License 2.0
# @since  : 2020-04-01
# =======================================

is-time(){
  if [[ $1 == *-time-* ]];
  then
    echo "true"
  else
    echo "false"
  fi
}

is-sole(){
  if [[ $1 == *-sole* ]];
  then
    echo "true"
  else
    echo "false"
  fi
}

# @param $1 {number} 
# @param $2 {number} 
max(){
  if [ $(echo $1'>'$2 | bc -l) -eq 1 ];
  then
    echo $1
  else
    echo $2
  fi
}

# @param $1 {number} 
# @param $2 {number} 
min(){
  if [ $(echo $1'>'$2 | bc -l) -eq 0 ];
  then
    echo $1
  else
    echo $2
  fi
}

# @param $1 {string} filename
exam-file(){
  # count of data
  local count=0
  local max_value=0
  local min_value=9999999999
  local avg_sum_value=0.0
  local sent_sum_value=0
  local lost_sum_value=0
  while IFS= read -r line
  do
    if [[ ${line} == Max* ]];
    then
      # read 'RTT'
      # e.g.: Max rtt: 6.730ms | Min rtt: 0.042ms | Avg rtt: 2.716ms
      IFS=" " read -a rtt_data <<< "${line}"
      max_value=$(max ${max_value} ${rtt_data[2]/ms/})
      min_value=$(min ${min_value} ${rtt_data[6]/ms/})
      avg_sum_value=$(bc <<< "${rtt_data[10]/ms/} + ${avg_sum_value}")

      ((count++))
    elif [[ ${line} == Raw* ]];
    then
      # read 'LOSS'
      # e.g.: Raw packets sent: 10 (280B) | Rcvd: 5 (230B) | Lost: 5 (50.00%)
      IFS=" " read -a packets <<< "${line}"
      ((sent_sum_value+=${packets[3]}))
      ((lost_sum_value+=${packets[11]}))
    fi
  done < $1

  # max|min|avg|lost
  printf "%s  %s  %s  %s  %s\n" $(bc <<< "scale=3;${avg_sum_value}/${count}") ${min_value} ${max_value} $(bc <<< "scale=3;${lost_sum_value}/${sent_sum_value}*100") ${count}
}

FILES=($(ls))
for filename in ${FILES[@]}
do
  if [[ ${filename} != *.log ]];
  then
    continue
  fi

  IFS="-" read -a arr <<< "${filename}"

  ICMPTIME=$(is-time ${filename})
  if [ $(is-sole ${filename}) == "true" ];
  then
    M_TYPE="단일"
  else
    M_TYPE="동시"
  fi

  printf "%s  %s  %s  %s  %s\n" ${arr[0]} ${arr[1]} ${M_TYPE} ${ICMPTIME} "$(exam-file ${filename})"
  
done

exit 0

      
