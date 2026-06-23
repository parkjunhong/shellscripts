#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : install htop.
# @license  : Apache License 2.0
# @since    : 2026-06-23
# @desc     : support Ubuntu 24.04+, Rocky Linux 9+, RHEL 9+, CentOS Stream 9+
# @installation : 
#   1. insert 'source <path>/install-htop.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-htop.sh' into 
#      etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

readonly EPEL_BASE_URL="[https://dl.fedoraproject.org/pub/epel](https://dl.fedoraproject.org/pub/epel)"
FILENAME=$(basename "$0")

##
# 스크립트 사용 방법 및 오류 원인을 출력합니다.
#
# @param $1 {string} (오류 발생 시 원인 메시지)
# @param $2 {string} (오류 발생 라인)
#
# @return (도움말 내용 출력)
##
help(){
  if [ ! -z "$1" ];
  then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: sudo ./$FILENAME [옵션]"
  echo "옵션:"
  echo "  -h, --help    이 도움말을 표시하고 종료합니다."
}

##
# 정보성 로그를 출력합니다.
#
# @param $1 {string} (출력할 메시지)
#
# @return (표준 출력으로 로그 출력)
##
log() {
  printf '[INFO] %s\n' "$*"
}

##
# 경고성 로그를 출력합니다.
#
# @param $1 {string} (출력할 메시지)
#
# @return (표준 에러로 경고 출력)
##
warn() {
  printf '[WARN] %s\n' "$*" >&2
}

##
# 에러 메시지를 출력하고 스크립트를 종료합니다.
#
# @param $1 {string} (출력할 메시지)
#
# @return (표준 에러로 출력 후 exit 1)
##
die() {
  help "[ERROR] $*" "$LINENO"
  exit 1
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

# 도움말 옵션 처리
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    *)
      die "알 수 없는 옵션입니다: $1"
      ;;
  esac
  shift
done

if [[ "${EUID}" -ne 0 ]]; then
  die "root 권한이 필요합니다. 예: sudo ./$FILENAME"
fi

if [[ ! -r /etc/os-release ]]; then
  die "/etc/os-release 파일을 찾을 수 없습니다."
fi

source /etc/os-release

##
# Ubuntu OS 환경에서 htop을 설치합니다.
#
# @param 없음
#
# @return (apt-get 설치 결과 출력)
##
install_ubuntu() {
  if ! dpkg --compare-versions "${VERSION_ID}" ge "24.04"; then
    die "Ubuntu 24.04 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "Ubuntu ${VERSION_ID} 감지"
  apt-get update -y

  if ! apt-cache show htop >/dev/null 2>&1; then
    log "universe 저장소를 활성화합니다."
    apt-get install -y software-properties-common
    add-apt-repository -y universe
    apt-get update -y
  fi

  apt-get install -y htop
}

##
# Enterprise Linux 환경에서 EPEL 저장소를 설치합니다.
#
# @param 없음
#
# @return (dnf 설치 결과 출력)
##
install_epel_release() {
  local epel_rpm_url="${EPEL_BASE_URL}/epel-release-latest-${EL_MAJOR}.noarch.rpm"

  if rpm -q epel-release >/dev/null 2>&1; then
    log "EPEL이 이미 설치되어 있습니다."
    return
  fi

  log "EPEL ${EL_MAJOR} 저장소를 설치합니다."

  if [[ "${ID}" != "rhel" ]] && dnf -y install epel-release; then
    return
  fi

  dnf -y install "${epel_rpm_url}"
}

##
# RHEL, Rocky, CentOS Stream 환경에서 htop을 설치합니다.
#
# @param 없음
#
# @return (dnf 설치 결과 출력)
##
install_el() {
  EL_MAJOR="${VERSION_ID%%.*}"

  if ! [[ "${EL_MAJOR}" =~ ^[0-9]+$ ]] || (( EL_MAJOR < 9 )); then
    die "Enterprise Linux 9 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "${PRETTY_NAME:-${ID} ${VERSION_ID}} 감지"

  case "${ID}" in
    rocky|centos)
      log "CRB 저장소를 활성화합니다."
      dnf -y install dnf-plugins-core
      dnf config-manager --set-enabled crb
      ;;
    rhel)
      if ! command -v subscription-manager >/dev/null 2>&1; then
        die "RHEL에서는 subscription-manager가 필요합니다."
      fi

      if ! subscription-manager identity >/dev/null 2>&1; then
        die "RHEL 시스템이 등록되지 않았습니다. 등록 후 다시 실행하세요."
      fi

      log "CodeReady Builder 저장소를 활성화합니다."
      subscription-manager repos \
        --enable "codeready-builder-for-rhel-${EL_MAJOR}-$(arch)-rpms"
      ;;
    *)
      die "지원하지 않는 Enterprise Linux 배포판입니다: ${ID}"
      ;;
  esac

  install_epel_release

  if [[ "${ID}" == "centos" ]] && ! rpm -q epel-next-release >/dev/null 2>&1; then
    log "CentOS Stream용 EPEL Next 설치를 시도합니다."
    dnf -y install epel-next-release || \
      warn "epel-next-release를 설치하지 못했습니다. htop 설치를 계속 시도합니다."
  fi

  dnf -y --refresh install htop
}

case "${ID}" in
  ubuntu)
    install_ubuntu
    ;;
  rocky|rhel|centos)
    install_el
    ;;
  *)
    die "지원하지 않는 OS입니다: ${PRETTY_NAME:-${ID}}"
    ;;
esac

if command -v htop >/dev/null 2>&1; then
  log "htop 설치 완료: $(htop --version | head -n 1)"
else
  die "설치 후 htop 실행 파일을 찾지 못했습니다."
fi

exit 0
