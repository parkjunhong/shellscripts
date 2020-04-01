#!/bin/bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : analyse ping's verbose.
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
    if [[ ${line} == rtt* ]];
    then
      # read 'RTT'
      # e.g.: rtt min/avg/max/mdev = 5.664/6.396/8.721/0.908 ms
      IFS=" " read -a rtt_data <<< "${line}"
      IFS="/" read -a rtt_data <<< "${rtt_data[3]}"
      max_value=$(max ${max_value} ${rtt_data[2]})
      min_value=$(min ${min_value} ${rtt_data[0]})
      avg_sum_value=$(bc <<< "${rtt_data[1]} + ${avg_sum_value}")

      ((count++))
    elif [[ ${line} == *packets* ]];
    then
      # read 'LOSS'
      # e.g.: 10 packets transmitted, 10 received, 0% packet loss, time 1808ms
      IFS=" " read -a packets <<< "${line}"
      ((sent_sum_value+=${packets[0]}))
      ((lost_sum_value+=$((${packets[0]}-${packets[3]}))))
    fi
  done < $1

  # max|min|avg|lost

  printf "%s  %s  %s  %s\n" $(bc <<< "scale=3;${avg_sum_value}/${count}") ${min_value} ${max_value} $(bc <<< "scale=3;${lost_sum_value}/${sent_sum_value}*100")
}

while IFS= read -r filename
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

done <<< $(ls)

exit 0
      
