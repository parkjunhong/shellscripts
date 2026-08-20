#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : install docker.
# @license : Apache License 2.0
# @since : 2026-08-20
# @desc : support Ubuntu 24.04 or higher
# @installation :
# 1. insert 'source <path>/<파일명>" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

help(){
  if [ ! -z "${1:-}" ]; then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack" ""
    local idx=1
    for func in "${FUNCNAME[@]:1}"
    do
      printf "$formatr" "["$idx"]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi
  echo
  # TODO: Usage 내용 작성
  echo "Usage: $FILENAME [OPTIONS]"
  echo "Options:"
  echo "  -u, --user <계정명>   Docker 그룹에 권한을 추가할 사용자 계정 (옵션)"
  echo "  -h, --help            도움말 출력"
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

##
# 실행 환경에 sudo 권한이 있는지 사전에 검증합니다.
#
# @param 없음
#
# @return 없음 (검증 실패 시 스크립트 즉시 종료)
##
check_sudo_privilege() {
  if ! sudo -n true 2>/dev/null; then
    sudo -v || {
      help "이 스크립트의 일부 기능은 sudo 권한이 필요합니다. sudo 권한을 확인해주세요." "$LINENO"
      exit 1
    }
  fi
}

##
# Ubuntu 24.04 이상 버전인지 운영체제를 검증합니다.
#
# @param 없음
#
# @return 없음 (검증 실패 시 스크립트 종료)
##
verify_os_version() {
  local os_id
  local os_version
  local major_version

  if [ ! -f /etc/os-release ]; then
    help "/etc/os-release 파일이 존재하지 않아 OS 정보를 확인할 수 없습니다." "$LINENO"
    exit 1
  fi

  os_id=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
  os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

  if [[ "$os_id" != "ubuntu" ]]; then
    help "지원되지 않는 운영체제입니다. (현재: $os_id, 요구사항: ubuntu)" "$LINENO"
    exit 1
  fi

  major_version=$(echo "$os_version" | cut -d. -f1)
  
  if [ "$major_version" -lt 24 ]; then
    help "Ubuntu 24.04 이상의 버전이 필요합니다. (현재 버전: $os_version)" "$LINENO"
    exit 1
  fi
}

##
# 입력된 사용자가 시스템에 실제로 존재하는지 검증합니다.
#
# @param $1 {string} 확인할 사용자 계정명
#
# @return 없음 (검증 실패 시 스크립트 종료)
##
verify_user_exists() {
  local target_user="$1"
  if ! id -u "$target_user" >/dev/null 2>&1; then
    help "시스템에 존재하지 않는 사용자 계정입니다: $target_user" "$LINENO"
    exit 1
  fi
}

##
# Docker 설치 전 충돌을 유발할 수 있는 구버전 패키지를 삭제합니다.
#
# @param 없음
#
# @return 상태 메시지 표준 출력
##
remove_old_packages() {
  local packages=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
  echo "[INFO] 구버전 패키지 충돌 방지 처리..."
  for pkg in "${packages[@]}"; do
    if dpkg -l | grep -qw "$pkg"; then
      sudo apt-get remove -y "$pkg" || true
    fi
  done
}

##
# Docker 공식 저장소 GPG 키를 추가하고 패키지를 설치합니다.
# 경로가 없는 경우 mkdir -p 와 같이 생성합니다.
#
# @param 없음
#
# @return 상태 메시지 표준 출력
##
install_docker() {
  echo "[INFO] 패키지 목록 업데이트 및 필수 도구 설치 중..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  echo "[INFO] GPG 키 디렉토리 생성 중..."
  sudo install -m 0755 -d /etc/apt/keyrings

  if [ -f /etc/apt/keyrings/docker.asc ]; then
    sudo rm -f /etc/apt/keyrings/docker.asc
  fi

  echo "[INFO] Docker GPG 키 등록 중..."
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "[INFO] APT 소스 리스트 추가 중..."
  local arch
  arch=$(dpkg --print-architecture)
  local codename
  codename=$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

  echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  echo "[INFO] Docker 패키지 설치 중..."
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

##
# 지정된 사용자를 docker 그룹에 할당합니다.
#
# @param $1 {string} docker 그룹에 추가할 사용자 계정명
#
# @return 상태 메시지 표준 출력
##
add_user_to_docker_group() {
  local user_name="$1"
  echo "[INFO] '$user_name' 계정을 docker 그룹에 추가합니다..."
  sudo usermod -aG docker "$user_name"
  echo "[WARN] 권한 적용을 위해 로그아웃 후 다시 로그인하시거나 'su - $user_name' 명령을 실행하세요."
}

##
# 스크립트의 메인 로직을 제어합니다.
#
# @param $@ {array} 쉘 스크립트 실행 인자
#
# @return 없음
##
main() {
  local target_user=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -u|--user)
        if [[ -z "${2:-}" || "$2" == -* ]]; then
          help "--user 파라미터는 계정명이 필요합니다." "$LINENO"
          exit 1
        fi
        target_user="$2"
        shift 2
        ;;
      -h|--help)
        help "" ""
        exit 0
        ;;
      *)
        help "알 수 없는 옵션: $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  check_sudo_privilege
  verify_os_version

  if [[ -n "$target_user" ]]; then
    verify_user_exists "$target_user"
  fi

  remove_old_packages
  install_docker

  if [[ -n "$target_user" ]]; then
    add_user_to_docker_group "$target_user"
  fi

  echo "[SUCCESS] Docker 설치 완료."
}

main "$@"
exit 0
