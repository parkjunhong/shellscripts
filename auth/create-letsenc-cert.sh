#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : create Let's Encrypt certificates for multiple domains.
# @license  : Apache License 2.0
# @since    : 2020-03-31
# @desc     : support RHEL 7+/8+, Oracle Linux 7+/8+, Ubuntu 18.04+, CentOS 7+, macOS 12+
# @installation :
#   1. insert 'source <path>/create-letsenc-cert.sh' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/create-letsenc-cert.sh' into
#      /etc/bashrc for all users.
# =======================================

FILENAME="$(basename "$0")"

DOMAINS=""
FILE=""

# Simple Regular Expression for Domain Name
DN_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"

##
# 도움말 출력 / Print usage help
#
# @param $1 {string} 오류/원인 메시지 (없으면 빈 문자열) / cause message (empty if none)
# @param $2 {string} 라인 번호 (선택) / line number (optional)
#
# @return 항상 0, 단 호출 위치에서 exit 처리 / always 0, caller handles exit
##
help() {
  if [ ! -z "$1" ];
  then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}
    do
      printf "$formatr" "[""$idx""]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi
  echo
  echo "Usage:"
  echo "  $FILENAME -ds <domain1,domain2,...>"
  echo "  $FILENAME --domains <domain1,domain2,...>"
  echo "  $FILENAME -f <file>"
  echo "  $FILENAME --file <file>"
  echo "  $FILENAME -h | --help"
  echo
  echo "Description:"
  echo "  Issue Let's Encrypt certificates for multiple domains (single domain per certificate)."
  echo "  여러 개의 도메인에 대해, 각 도메인별로 단일 인증서를 발급합니다."
  echo "  ※ wildcard(예: *.example.com)를 발급하지 않습니다. (단일 도메인만 -d <domain>)"
  echo
  echo "Options:"
  echo "  -ds, --domains <domains>   Comma separated domain list (e.g. example.com,ymtech.co.kr)."
  echo "                             쉼표(,)로 구분된 도메인 목록 (예: example.com,ymtech.co.kr)."
  echo
  echo "  -f, --file <file>          File containing domain list, one per line."
  echo "                             한 줄에 한 도메인씩 포함된 파일 경로."
  echo
  echo "  -h, --help                 Show this help and exit."
  echo "                             이 도움말을 출력하고 종료합니다."
  echo
}

##
# 현재 사용자가 root 인지 검증 / Ensure current user is root
#
# @param (none)
#
# @return root 가 아니면 help() 호출 후 종료 / exit if not root
##
ensure_root() {
  if (( EUID != 0 ));
  then
    echo
    echo "You MUST run this script as 'root' or a 'sudoer'."
    echo "이 스크립트는 root 또는 sudo 권한으로 실행해야 합니다."
    help "not running as root" "$LINENO"
    exit 100
  fi
}

##
# 명령행 인자 파싱 / Parse command-line arguments
#
# @param $@ {string[]} 전체 인자 / all CLI arguments
#
# @return DOMAINS, FILE 전역 변수 설정 / set global DOMAINS, FILE
##
parse_args() {
  while [[ $# -gt 0 ]];
  do
    case "$1" in
      -ds|--domains)
        if [[ $# -lt 2 ]];
        then
          help "missing value for option '$1'" "$LINENO"
          exit 1
        fi
        DOMAINS="$2"
        shift 2
        ;;
      -f|--file)
        if [[ $# -lt 2 ]];
        then
          help "missing value for option '$1'" "$LINENO"
          exit 1
        fi
        if [[ ! -f "$2" ]];
        then
          help "invalid domain file path: $2" "$LINENO"
          exit 1
        fi
        FILE="$2"
        shift 2
        ;;
      -h|--help)
        help "" "$LINENO"
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        help "unsupported option: $1" "$LINENO"
        exit 1
        ;;
      *)
        help "unexpected positional argument: $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  if [[ -z "${DOMAINS}" && -z "${FILE}" ]];
  then
    help "no arguments (-ds|--domains or -f|--file) provided" "$LINENO"
    exit 1
  fi
}

##
# 파일에서 도메인 목록 읽기
# Read domain list from file
#
# @param $1 {string} 파일 경로 / file path
#
# @return 표준 출력으로 도메인 목록 출력 (공백/빈줄 제외) / echo domains (one per line)
##
read_domains_from_file() {
  local file="$1"
  while IFS= read -r domain;
  do
    if [[ -n "${domain}" ]];
    then
      echo "${domain}"
    fi
  done < "${file}"
}

##
# 쉼표 구분 문자열에서 도메인 목록 읽기
# Read domain list from comma-separated string
#
# @param $1 {string} 쉼표로 구분된 도메인 문자열 / comma-separated domain string
#
# @return 표준 출력으로 도메인 목록 출력 / echo domains (one per line)
##
read_domains_from_string() {
  local list="$1"
  local IFS=","
  read -r -a domains <<< "${list}"
  local d
  for d in "${domains[@]}";
  do
    if [[ -n "${d}" ]];
    then
      echo "${d}"
    fi
  done
}

##
# 배열 이름을 받아서 정렬 + 중복 제거된 목록을 출력
# Create sorted unique set from an array name
#
# @param $1 {string} 배열 이름 / array name (for indirect reference)
#
# @return 표준 출력으로 정렬+중복제거된 도메인 목록 / echo deduped domains (one per line)
##
create_set() {
  local arr_name="$1"
  local ar="\${${arr_name}[@]}"
  # eval 은 arr_name 에만 사용 / eval is used only for array indirection
  for v in $(eval "echo ${ar}");
  do
    echo "$v"
  done | sort | uniq
}

##
# 단일 도메인에 대해 certbot 실행 (standalone, 단일 도메인 인증서)
# Run certbot for a single domain (standalone, single-domain certificate)
#
# @param $1 {string} 루트 도메인 (예: example.com) / domain (e.g. example.com)
#
# @return certbot 종료 코드 / exit code of certbot
##
issue_certificate_for_domain() {
  local domain="$1"

  if [[ ! "${domain}" =~ ${DN_REGEX} ]];
  then
    echo "[Invalid] ${domain}"
    return 1
  fi

  echo
  echo "=========================================================================="
  echo ">>>>>> Start '${domain}' Let's Encrypt Certificate"
  echo
  echo "certbot certonly --standalone -d \"${domain}\""
  echo

  certbot certonly --standalone -d "${domain}"
  local rc=$?

  if [[ $rc -eq 0 ]];
  then
    echo
    echo "<<<<<< Finished '${domain}'"
  else
    echo
    echo "[ERROR] certbot failed for domain '${domain}' (exit code=${rc})"
  fi

  echo "=========================================================================="

  return $rc
}

##
# 메인 엔트리 포인트 / Main entry point
#1
# @param $@ {string[]} CLI arguments
#
# @return 스크립트 종료 코드 / script exit code
##
main() {
  ensure_root
  parse_args "$@"

  local domain_list=()

  # 파일에서 읽기 / read from file if provided
  if [[ -n "${FILE}" ]];
  then
    while IFS= read -r d;
    do
      domain_list+=("${d}")
    done < <(read_domains_from_file "${FILE}")
  else
    echo "[INFO] No file for domain list."
  fi

  # 문자열에서 읽기 / read from domains option if provided
  if [[ -n "${DOMAINS}" ]];
  then
    while IFS= read -r d;
    do
      domain_list+=("${d}")
    done < <(read_domains_from_string "${DOMAINS}")
  fi

  if [[ ${#domain_list[@]} -eq 0 ]];
  then
    help "no valid domains loaded" "$LINENO"
    exit 1
  fi

  # 중복 제거 / deduplicate
  local unique_domains=()
  while IFS= read -r d;
  do
    unique_domains+=("${d}")
  done < <(create_set "domain_list")

  local rc=0
  local d
  for d in "${unique_domains[@]}";
  do
    issue_certificate_for_domain "${d}" || rc=$?
  done

  exit "${rc}"
}

main "$@"
exit 0

