#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : 서비스별 고정 설정 기반 인증서 배포 래퍼 스크립트
# @license: Apache License 2.0
# @since  : 2025/11/27
# @desc   : support RHEL 7/8/9, Oracle Linux 7/8/9, Ubuntu 18.04/20.04/22.04 LTS,
#           macOS 11+ (with bash >= 4), CentOS 7
# @completion: send-certificate.completion
#            1. insert "source <path>/send-certificate.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================


# 안 보내기 (옵션으로 변경 가능)
NO_SEND=0
# 유형별 인증서 삭제하지 않기 (옵션으로 변경 가능)
NO_DELETE=0
# dry-run 여부
DRY_RUN=0

# 인증서 유형 목록 (참고용, 실제 검증은 send-certificate.sh 에서 수행)
TYPE=( "pem" "sslca" "pkcs12" "jks")

# WILDCARD 도메인 (예: mycompany.co.kr) - 고정값
WILDCARD_DOMAIN="mycompany.co.kr"

# 전송할 인증서 유형 리스트 (미지정 시 TYPE 전체 사용)
# 여기서는 단순히 옵션 문자열만 넘기고, 실제 검증은 send-certificate.sh 에 맡김
TARGET_CA_LIST=()

# SSH 개인키 경로 (고정값)
SSH_PRI_KEY="$HOME/.ssh/id_rsa.pem"

# PKCS12/JKS 비밀번호 (고정값)
P12_PWD="CHANGE_ME_P12_PASSWORD"

# 서비스 리스트 파일 경로 (고정값)
SERVICES_LIST="/opt/certs/service-list.txt"

# send-certificate.sh 위치 (필요에 맞게 수정)
CERT_SCRIPT="$(cd "$(dirname "$0")" && pwd)/send-certificate.sh"


print_usage() {
  echo
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  --no-send              실제로 파일을 전송하지 않음 (로그만 출력)"
  echo "  --no-delete            변환된 인증서 파일들을 삭제하지 않음"
  echo "  --dry-run              --no-send + --no-delete 와 동일"
  echo "  --target-ca|-tc TYPES  전송할 인증서 유형 지정 (comma separated: pem,sslca,pkcs12,jks)"
  echo "  -h, --help             이 도움말을 출력"
  echo
  echo "고정값:"
  echo "  WILDCARD_DOMAIN = ${WILDCARD_DOMAIN}"
  echo "  SSH_PRI_KEY     = ${SSH_PRI_KEY}"
  echo "  SERVICES_LIST   = ${SERVICES_LIST}"
  echo
}

# ----------------------------------------------------------------------
# 옵션 파싱
# ----------------------------------------------------------------------
TARGET_CA_OPT=""

while [ -n "$1" ]; do
  case "$1" in
    --no-send)
      NO_SEND=1
      ;;
    --no-delete)
      NO_DELETE=1
      ;;
    --dry-run)
      DRY_RUN=1
      NO_SEND=1
      NO_DELETE=1
      ;;
    --target-ca|-tc)
      shift
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--target-ca|-tc' 옵션에 대한 값이 없습니다."
        echo "     사용 예) $0 --target-ca pem,sslca,pkcs12,jks"
        echo
        exit 1
      fi
      TARGET_CA_OPT="$1"
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo
      echo " ❌❌❌ Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
  shift
done

# ----------------------------------------------------------------------
# send-certificate.sh 호출 인자 구성
# ----------------------------------------------------------------------
ARGS=()

# NO_SEND / NO_DELETE / DRY_RUN 처리
if [ $DRY_RUN -eq 1 ]; then
  ARGS+=("--dry-run")
else
  if [ $NO_SEND -eq 1 ]; then
    ARGS+=("--no-send")
  fi
  if [ $NO_DELETE -eq 1 ]; then
    ARGS+=("--no-delete")
  fi
fi

# target-ca 전달
if [ -n "$TARGET_CA_OPT" ]; then
  ARGS+=("--target-ca" "$TARGET_CA_OPT")
fi

# 고정값 전달: wildcard-domain, ssh-key, p12-pwd, service-files
ARGS+=("--wildcard-domain" "$WILDCARD_DOMAIN")
ARGS+=("--ssh-key" "$SSH_PRI_KEY")
ARGS+=("--p12-pwd" "$P12_PWD")
ARGS+=("--service-files" "$SERVICES_LIST")

# ----------------------------------------------------------------------
# 실제 실행
# ----------------------------------------------------------------------
echo
echo " ▶ 호출 스크립트 : $CERT_SCRIPT"
echo " ▶ 전달 인자     : ${ARGS[*]}"
echo

exec "$CERT_SCRIPT" "${ARGS[@]}"

exit 0
