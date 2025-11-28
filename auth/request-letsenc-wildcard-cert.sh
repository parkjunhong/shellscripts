#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : issue Let's Encrypt wildcard certificate.
# @license  : Apache License 2.0
# @since    : 2025-11-28
# @desc     : support RHEL 7+/8+, Oracle Linux 7+/8+, Ubuntu 18.04+, CentOS 7+, macOS 12+
# @installation :
#   1. insert 'source <path>/issue-letsencrypt.sh' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/issue-letsencrypt.sh' into
#      /etc/bashrc for all users.
# =======================================

FILENAME="$(basename "$0")"

# 전역 변수 / Global variables
ROOT_DOMAIN=""
EMAIL=""
LETSENC_ROOT=""

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
  echo "  $FILENAME --root-domain <domain> --email <email>"
  echo "  $FILENAME -d <domain> -e <email>"
  echo "  $FILENAME -h | --help"
  echo
  echo "Description:"
  echo "  Issue or renew Let's Encrypt wildcard certificate using certbot (manual DNS challenge)."
  echo "  certbot(수동 DNS 인증)을 이용해 Let's Encrypt 와일드카드 인증서를 발급/갱신하는 스크립트입니다."
  echo
  echo "Required options:"
  echo "  -d, --root-domain <domain>  Root domain (e.g. example.com)"
  echo "                              루트 도메인 (예: example.com)"
  echo
  echo "  -e, --email <email>         Contact email for Let's Encrypt (e.g. user@example.com)"
  echo "                              Let's Encrypt 계정용 이메일 주소 (예: user@example.com)"
  echo
  echo "Optional options:"
  echo "  -h, --help                  Show this help and exit."
  echo "                              이 도움말을 출력하고 종료합니다."
  echo
  echo "Environment:"
  echo "  LETSENC_INSTDIR             certbot config directory (e.g. /etc/letsencrypt)."
  echo "                              certbot 설정 디렉토리 (예: /etc/letsencrypt)."
  echo
}

##
# LETSENC_INSTDIR 환경변수 검증 및 LETSENC_ROOT 설정
# Validate LETSENC_INSTDIR environment variable and set LETSENC_ROOT
#
# @param (none)
#
# @return 정상인 경우 0, 잘못된 경우 help() 호출 후 종료 / 0 on success, exit on error
##
validate_env() {
  LETSENC_ROOT="${LETSENC_INSTDIR:-}"

  if [[ -z "${LETSENC_ROOT}" || ! -d "${LETSENC_ROOT}" ]];
  then
    echo
    echo "Let's Encrypt 도구가 설치된 경로가 존재하지 않습니다."
    echo "Let's Encrypt tools directory does not exist."
    echo "echo \"\$LETSENC_INSTDIR\"=${LETSENC_ROOT}"
    help "invalid LETSENC_INSTDIR: directory not found" "$LINENO"
    exit 1
  fi
}

##
# 명령행 인자 파싱 / Parse command-line arguments
#
# @param $@ {string[]} 전체 인자 / all CLI arguments
#
# @return ROOT_DOMAIN, EMAIL 전역 변수 설정 / set global ROOT_DOMAIN, EMAIL
##
parse_args() {
  while [[ $# -gt 0 ]];
  do
    case "$1" in
      -d|--root-domain)
        if [[ $# -lt 2 ]];
        then
          help "missing value for option '$1'" "$LINENO"
          exit 1
        fi
        ROOT_DOMAIN="$2"
        shift 2
        ;;
      -e|--email)
        if [[ $# -lt 2 ]];
        then
          help "missing value for option '$1'" "$LINENO"
          exit 1
        fi
        EMAIL="$2"
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
        help "unknown option: $1" "$LINENO"
        exit 1
        ;;
      *)
        # 현재 스크립트에서는 위치 인자를 사용하지 않음 / no positional args in this script
        help "unexpected positional argument: $1" "$LINENO"
        exit 1
        ;;
    esac
  done
}

# @param $1 {string} 삭제할 디렉토리
check_and_delete(){
  local dir="$LETSENC_ROOT/$1"

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

##
# 기존에 생성되었던 파일이 존재하는 경우 삭제합니다.
##
delete_old_files(){
  # archive 삭제
  check_and_delete "archive"

  # live 삭제
  check_and_delete "live"

  # renewal 삭제
  check_and_delete "renewal"
}

##
# certbot을 이용해 와일드카드 인증서 발급/갱신
# Issue or renew wildcard certificate via certbot (manual DNS challenge)
#
# @param (none) ROOT_DOMAIN, EMAIL, LETSENC_ROOT 전역 변수 사용
#               uses global ROOT_DOMAIN, EMAIL, LETSENC_ROOT
#
# @return certbot 종료 코드 / exit code of certbot
##
issue_certificate() {
  local root_domain="$ROOT_DOMAIN"
  local email="$EMAIL"
  local wc_domain="*.$root_domain"

  echo
  echo "* * * Issue Let's Encrypt wildcard certificate * * *"
  echo "sudo certbot certonly --manual --preferred-challenges=dns \\"
  echo "  --email \"$email\" \\"
  echo "  --server https://acme-v02.api.letsencrypt.org/directory \\"
  echo "  --agree-tos -d \"$root_domain\" -d \"$wc_domain\" --config-dir \"$LETSENC_ROOT\""

  sudo certbot certonly --manual --preferred-challenges=dns \
    --email "$email" \
    --server "https://acme-v02.api.letsencrypt.org/directory" \
    --agree-tos \
    -d "$root_domain" \
    -d "$wc_domain" \
    --config-dir "$LETSENC_ROOT"

  local rc=$?
  if [[ $rc -eq 0 ]];
  then
    echo
    echo "* * * '${root_domain}' wildcard certificate has been issued/renewed successfully. * * *"
    echo "* * * '${root_domain}' 와일드카드 인증서 발급/갱신을 완료했습니다. * * *"
  else
    help "certbot failed with exit code $rc" "$LINENO"
    exit "$rc"
  fi
}

##
# 메인 엔트리 포인트 / Main entry point
#
# @param $@ {string[]} CLI arguments
#
# @return 스크립트 종료 코드 / script exit code
##
main() {
  parse_args "$@"

  if [[ -z "${ROOT_DOMAIN}" ]];
  then
    help "root domain is required (-d|--root-domain)" "$LINENO"
    exit 1
  fi

  if [[ -z "${EMAIL}" ]];
  then
    help "email is required (-e|--email)" "$LINENO"
    exit 1
  fi

  validate_env
  delete_old_files
  issue_certificate
}

main "$@"
exit 0

