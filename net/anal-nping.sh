#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : analyse nping's verbose.
# @license: Apache License 2.0
# @since  : 2020-04-01
# =======================================


usage(){
  echo
  echo ">>> CALLED BY [[ $1 ]]"
  echo
  echo "[Usage]"
  echo
  echo "./anal-nping.sh <directory> -f <filename-format>"
  echo
  echo "[Arguments]"
  echo " - directory: 파일이 위치한 디렉토리. 기본값: ./"
  echo
  echo "[Option]"
  echo " -f: 로그파일명 포맷"
  echo 
}

# @param $1 {string} directory
del-tail-slash(){
  if [ "$1" == "/" ];
  then
    echo $1
  elif [ ! -z "$1" ] && [[ "$1" == */ ]];
  then
    echo ${1:0:$((${#1}-1))}
  else
    echo $1
  fi
}

DIRECTORY="./"
FILENAME_FORMAT="nping-*.log"

## 파라미터 읽기
{
while [ "$1" != "" ]; do
  case $1 in
    -f)
      shift
      FILENAME_FORMAT=$1
      ;;
    -h | --help)
      usage "--help"
      exit 0
      ;;
    *)
      if [ ! -d "$1" ];
      then
        usage "Invalid a directory. => $1"
        exit 1
      fi
      DIRECTORY=$(del-tail-slash "$1")
      ;;
  esac
  shift
done
}||{
  echo "Oops... "
  usage "CAN NOT Controll..."
  exit 1
}


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

FILES=($(ls ${DIRECTORY}))

for filename in ${FILES[@]}
do
  if [[ ${filename} != nping-*.log ]];
  then
    continue
  fi

  filepath="${DIRECTORY}/${filename}"
  IFS="-" read -a arr <<< "${filename}"

  ICMPTIME=$(is-time ${filename})
  if [ $(is-sole ${filename}) == "true" ];
  then
    M_TYPE="단일"
  else
    M_TYPE="동시"
  fi
  result_exam=$(exam-file "${filepath}")
  printf "%s  %s  %s  %s  %s  %s\n" ${arr[0]} ${arr[1]} ${M_TYPE} ${ICMPTIME} "${result_exam}"
done

exit 0


