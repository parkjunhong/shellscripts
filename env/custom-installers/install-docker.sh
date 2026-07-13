#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : install docker.
# @license  : Apache License 2.0
# @since    : 2026-07-13
# @desc     : support Ubuntu 20.04+, Rocky Linux 9+
# @installation : 
#   1. insert 'source <path>/install-docker.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-docker.sh' into 
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
  if [ ! -z "${1:-}" ];
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
  echo "사용법: ./$FILENAME [옵션]"
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

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

##
# 작업 내용과 실행할 명령어를 로그로 출력한 뒤 실행합니다.
#
# @param $1 {string} 작업 내용
# @param $@ {any} 실행할 명령어 및 인자 배열 (2번째 파라미터부터)
#
# @return (명령어 실행 결과)
##
execute() {
  local desc="$1"
  shift
  printf '[INFO] %s\n' "${desc}"
  printf '  > %s\n' "$*"
  "$@"
}

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

if [[ ! -r /etc/os-release ]]; then
  die "/etc/os-release 파일을 찾을 수 없습니다."
fi

source /etc/os-release

##
# Ubuntu OS 환경에서 Docker 엔진을 설치합니다.
#
# @param 없음
#
# @return (apt-get 패키지 설치 및 서비스 구동)
##
install_ubuntu() {
  local major_ver="${VERSION_ID%%.*}"
  if (( major_ver < 20 )); then
    die "Ubuntu 20.04 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "Ubuntu ${VERSION_ID} 환경에 Docker 설치를 시작합니다."
  
  execute "패키지 목록을 업데이트합니다." sudo apt-get update -y
  execute "필수 의존성 패키지를 설치합니다." sudo apt-get install -y ca-certificates curl gnupg

  execute "Docker 공식 GPG 키를 저장할 디렉토리를 생성합니다." sudo install -m 0755 -d /etc/apt/keyrings

  printf '[INFO] %s\n' "Docker 공식 GPG 키를 다운로드하여 등록합니다."
  printf '  > %s\n' "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  execute "GPG 키 파일의 권한을 변경합니다." sudo chmod a+r /etc/apt/keyrings/docker.gpg

  printf '[INFO] %s\n' "Docker 공식 저장소를 APT 소스 목록에 추가합니다."
  printf '  > %s\n' "echo \"deb ...\" | sudo tee /etc/apt/sources.list.d/docker.list"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    ${VERSION_CODENAME} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  execute "저장소 추가 후 패키지 목록을 다시 업데이트합니다." sudo apt-get update -y
  execute "Docker 엔진 및 관련 플러그인을 설치합니다." sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

##
# Rocky Linux 환경에서 Docker 엔진을 설치합니다.
#
# @param 없음
#
# @return (dnf 패키지 설치 및 서비스 구동)
##
install_rocky() {
  local major_ver="${VERSION_ID%%.*}"
  if (( major_ver < 9 )); then
    die "Rocky Linux 9 이상만 지원합니다. 현재 버전: ${VERSION_ID}"
  fi

  log "Rocky Linux ${VERSION_ID} 환경에 Docker 설치를 시작합니다."

  execute "dnf-plugins-core 패키지를 설치합니다." sudo dnf -y install dnf-plugins-core
  execute "Docker CE 공식 저장소를 추가합니다." sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  
  execute "Docker 엔진 및 관련 플러그인을 설치합니다." sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# OS에 따른 설치 함수 분기
case "${ID}" in
  ubuntu)
    install_ubuntu
    ;;
  rocky)
    install_rocky
    ;;
  *)
    die "지원하지 않는 OS입니다: ${PRETTY_NAME:-${ID}}"
    ;;
esac

# Docker 서비스 활성화 및 상태 확인
execute "Docker 서비스를 부팅 시 자동 시작하도록 활성화하고 시작합니다." sudo systemctl enable --now docker

if command -v docker >/dev/null 2>&1; then
  log "Docker 설치 및 구동 완료: $(docker --version)"
else
  die "설치 후 docker 실행 파일을 찾지 못했습니다."
fi

exit 0
