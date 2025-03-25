#!/usr/bin/env bash

# 도움말 함수
help() {
  cat <<EOF
[사용법] $0 [옵션]

디스크 사용량 정보를 출력합니다.

옵션:
  -e, --exclude <문자열>   제외할 파일시스템 이름 또는 경로 일부 (예: tmpfs, /dev/loop)
  -h, --help                도움말 출력

예시:
  $0 -e tmpfs
  $0 --exclude "/dev/loop"
EOF
}

# 초기화 
exclude=""

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--exclude)
      exclude="$2"
      shift 2
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      echo "[오류] 알 수 없는 옵션: $1"
      help
      exit 1
      ;;
  esac
done

echo "================================================================================"

# host 정보 수집
# hostname
hostname=$(hostnamectl 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Ss]tatic[[:space:]]*[Hh]ostname[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# osname
osname=$(hostnamectl 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Oo]perating[[:space:]]*[Ss]ystem[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# architecture
architecture=$(hostnamectl 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Aa]rchitecture[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

echo "[서버정보]"
printf "  %-20s: %s\n" "Hostname" "$hostname"
printf "  %-20s: %s\n" "Operation System" "$osname"
printf "  %-20s: %s\n" "Architecture" "$architecture"
echo "================================================================================"

# CPU 정보 수집
# sockets
sockets=$(lscpu 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Ss]ocket(s\{0,1\})[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
# cores per socket
cores_per_socket=$(lscpu 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Cc]ore(s\{0,1\})[[:space:]]*[Pp]er[[:space:]]*[Ss]ocket[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
# threads per core
threads_per_core=$(lscpu 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Tt]hread(s\{0,1\})[[:space:]]*[Pp]er[[:space:]]*[Cc]ore[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
# cpu(s)
cpus=$(lscpu 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Cc][Pp][Uu](s\{0,1\})[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
# model name
model_name=$(lscpu 2>/dev/null \
  | sed -n 's/^[[:space:]]*[Mm]odel[[:space:]]*[Nn]ame[[:space:]]*:[[:space:]]*\(.*\)/\1/ip' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

echo "[CPU 정보]"
printf "  %-20s: %4s\n" "Core" "$(($sockets*$cores_per_socket))"
printf "  %-20s: %4s\n" "Threads per Core" "$threads_per_core"
printf "  %-20s: %4s\n" "CPU" "$cpus"
printf "  %-20s: %s\n" "CPU Model" "$model_name"
echo "================================================================================"

# 메모리 정보 수집
total_mem=$(free -h | grep Mem | awk '{print $2}')
used_mem=$(free -h | grep Mem | awk '{print $3}')
free_mem=$(free -h | grep Mem | awk '{print $4}')
shared_mem=$(free -h | grep Mem | awk '{print $5}')
buff_cache_mem=$(free -h | grep Mem | awk '{print $6}')
available_mem=$(free -h | grep Mem | awk '{print $7}')

echo "[메모리 정보]"
printf "  %-20s: %5s\n" "Total" "$total_mem"
printf "  %-20s: %5s (%s)\n" "Usage" "$used_mem" "사용된 메모리"
printf "  %-20s: %5s (%s)\n" "Shared" "$shared_mem" "공유 메모리"
printf "  %-20s: %5s (%s)\n" "Free" "$free_mem" "남은 메모리"
printf "  %-20s: %5s (%s)\n" "Buffer/Cache" "$buff_cache_mem" "버퍼/캐시형태로 사용 중인 메모리"
printf "  %-20s: %5s (%s)\n" "Available" "$available_mem" "사용가능한 메모리"
echo "================================================================================"

# 디스크 정보 수집
echo "[디스크 정보]"
max_fs_length=$(df -h | awk 'NR>1 { if (length($1) > max) max = length($1) } END { print max }')
printf " %-${max_fs_length}s %6s %6s %7s %6s %s\n" "[Filesystem]" "[Size]" "[Used]" "[Avail]" "[Use%]" "[Mounted on]"
echo "--------------------------------------------------------------------------------"
#df -h | awk -v max_fs_length="$max_fs_length" 'NR>1 {
#  printf " %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $2, $3, $4, $5, $6;
#}' | sort -k 6
# 디스크 정보 출력 (exclude 포함시 제외)
df -h | awk -v max_fs_length="$max_fs_length" -v exclude="$exclude" '
NR==1 { next }
exclude != "" && index($0, exclude) > 0 { next }
{
  printf " %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $2, $3, $4, $5, $6;
}' | sort -k 6
echo "................................................................................"
df -h --total | awk -v max_fs_length="$max_fs_length" '/total/ {
  printf " %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $2, $3, $4, $5, $6;
}'
echo "================================================================================"

exit 0
