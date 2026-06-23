#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : install temurin 25 jdk.
# @license  : Apache License 2.0
# @since    : 2026-06-23
# @desc     : support Ubuntu 24.04+, RockyOS 9+, RHEL 9+, CentOS Stream 9+
# @installation : 
#   1. insert 'source <path>/install-temurin-25-jdk.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-temurin-25-jdk.sh' into 
#      etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

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

# 에러 발생 시 도움말 함수 호출 트랩
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

# root 권한 확인
if [[ "${EUID}" -ne 0 ]]; then
  die "root 권한이 필요합니다. 예: sudo ./$FILENAME"
fi

# OS 릴리즈 파일 존재 여부 확인
if [[ ! -r /etc/os-release ]]; then
  die "/etc/os-release 파일을 찾을 수 없습니다."
fi

source /etc/os-release

##
# Ubuntu OS 환경에서 Temurin 25 JDK를 설치합니다.
#
# @param 없음
#
# @return (apt-get 설치 결과 출력)
##
install_ubuntu() {
  if ! dpkg --compare-versions "${VERSION_ID}" ge "24.04"; then
    die "Ubuntu 24.04 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "Ubuntu ${VERSION_ID} 환경에서 Temurin 25 JDK 설치를 시작합니다."
  apt-get update -y
  apt-get install -y wget apt-transport-https gnupg

  # Adoptium GPG 키 및 저장소 추가
  local keyring_path="/etc/apt/trusted.gpg.d/adoptium.gpg"
  wget -qO - "https://packages.adoptium.net/artifactory/api/gpg/key/public" | gpg --dearmor | tee "${keyring_path}" > /dev/null
  echo "deb https://packages.adoptium.net/artifactory/deb ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/adoptium.list

  apt-get update -y
  apt-get install -y temurin-25-jdk
}

##
# Enterprise Linux (RHEL, Rocky, CentOS) 환경에서 Temurin 25 JDK를 설치합니다.
#
# @param 없음
#
# @return (dnf 설치 결과 출력)
##
install_el() {
  local EL_MAJOR="${VERSION_ID%%.*}"

  if ! [[ "${EL_MAJOR}" =~ ^[0-9]+$ ]] || (( EL_MAJOR < 9 )); then
    die "Enterprise Linux 9 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "${PRETTY_NAME:-${ID} ${VERSION_ID}} 환경에서 Temurin 25 JDK 설치를 시작합니다."

  local repo_path="/etc/yum.repos.d/adoptium.repo"
  
  # 상위 디렉토리 존재 여부 확인 및 생성
  if [[ ! -d "$(dirname "${repo_path}")" ]]; then
    mkdir -p "$(dirname "${repo_path}")"
  fi

  # Adoptium 저장소 추가 (CentOS/RHEL/Rocky 모두 centos 경로 호환)
  cat <<EOF > "${repo_path}"
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/centos/${EL_MAJOR}/$(uname -m)
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

  dnf check-update || true
  dnf install -y temurin-25-jdk
}

# OS에 따른 설치 함수 분기
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

# 정상 설치 확인
if command -v java >/dev/null 2>&1; then
  log "Temurin 25 JDK 설치 완료: $(java -version 2>&1 | head -n 1)"
else
  die "설치 후 java 실행 파일을 찾지 못했습니다."
fi

exit 0
