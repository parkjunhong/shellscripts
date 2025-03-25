#!/usr/bin/env bash

# 도움말 함수
help() {
  cat <<EOF
[사용법] $(basename "$0") [옵션]

디스크 사용량 정보를 출력합니다.

옵션:
  -f, --exclude-fs <문자열>     Filesystem 컬럼에서 제외할 문자열 (여러 번 사용 가능)
  -m, --exclude-mnt <문자열>    Mounted on 컬럼에서 제외할 문자열 (여러 번 사용 가능)
      --sort-key <fs|mnt>       정렬 기준. fs=Filesystem, mnt=Mounted on
      --sort-dir <asc|desc>     정렬 방향. asc=오름차순, desc=내림차순
  -h, --help                    도움말 출력

예시:
  $(basename "$0") -f tmpfs --sort-key fs --sort-dir desc
EOF
}

# 변수 초기화
declare -a exclude_fs_list=()
declare -a exclude_mnt_list=()
sort_key=""
sort_dir="asc"
max_fs_length=0

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--exclude-fs)
      exclude_fs_list+=("$2")
      shift 2
      ;;
    -m|--exclude-mnt)
      exclude_mnt_list+=("$2")
      shift 2
      ;;
    --sort-key)
      sort_key="$2"
      shift 2
      ;;
    --sort-dir)
      sort_dir="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "[오류] 알 수 없는 옵션: $1"
      print_help
      exit 1
      ;;
  esac
done

# 정렬 기준 필드 번호 설정
sort_field=""
case "$sort_key" in
  "" ) sort_field="" ;;
  fs ) sort_field="1" ;;
  mnt ) sort_field="6" ;;
  * )
    echo "[오류] 잘못된 정렬 기준입니다: $sort_key"
    echo "        허용 값: fs, mnt"
    exit 1
    ;;
esac

# 정렬 방향 설정
case "$sort_dir" in
  asc ) sort_option="" ;;
  desc ) sort_option="-r" ;;
  * )
    echo "[오류] 잘못된 정렬 방향입니다: $sort_dir"
    echo "        허용 값: asc, desc"
    exit 1
    ;;
esac

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
# 개별 출력
# 출력 + 정렬 필드 붙이기
df -h | awk -v max_fs_length="$max_fs_length" \
  -v fs_excludes="${exclude_fs_list[*]}" \
  -v mnt_excludes="${exclude_mnt_list[*]}" \
  -v sort_key="$sort_key" '
BEGIN {
  n_fs = split(fs_excludes, fslist, " ");
  n_mnt = split(mnt_excludes, mntlist, " ");
}
NR == 1 { next }
{
  for (i = 1; i <= n_fs; i++) {
    if (fslist[i] != "" && index($1, fslist[i]) > 0) next
  }
  for (j = 1; j <= n_mnt; j++) {
    if (mntlist[j] != "" && index($6, mntlist[j]) > 0) next
  }

  # 정렬용 키 앞에 붙이기
  if (sort_key == "fs") {
    printf "%s\t %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $1, $2, $3, $4, $5, $6;
  } else if (sort_key == "mnt") {
    printf "%s\t %-"max_fs_length"s %6s %6s %7s %6s %s\n", $6, $1, $2, $3, $4, $5, $6;
  } else {
    printf "_\t %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $2, $3, $4, $5, $6;
  }
}' | sort $sort_option -k1,1 | cut -f2-

echo "................................................................................"
# 전체 출력
df -h --total | awk -v max_fs_length="$max_fs_length" '/total/ {
  printf " %-"max_fs_length"s %6s %6s %7s %6s %s\n", $1, $2, $3, $4, $5, $6;
}'
echo "================================================================================"

exit 0
