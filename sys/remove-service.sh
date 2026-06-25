#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : completely remove linux service.
# @license  : Apache License 2.0
# @since    : 2026-06-25
# @desc     : support Ubuntu 18+, RockyOS 9+, Oracle Linux 8+, RHEL 8+, CentOS 6+, CentOS Stream 9+
# @installation : 
#   1. insert 'source <path>/remove-service.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/remove-service.sh' into 
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
  if [ ! -z "${1:-}" ]; then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}; do  
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME [옵션] <서비스이름>"
  echo "예시: ./$FILENAME nginx"
  echo "옵션:"
  echo "  -h, --help    이 도움말을 표시하고 종료합니다."
}

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  help "[ERROR] $*" "$LINENO"
  exit 1
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

# 파라미터가 없는 경우 도움말 출력
if [[ "$#" -eq 0 ]]; then
  help "삭제할 서비스 이름을 입력해야 합니다." "$LINENO"
  exit 1
fi

SERVICE_NAME=""

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      help
      exit 0
      ;;
    -*)
      die "알 수 없는 옵션입니다: $1"
      ;;
    *)
      # 서비스 이름 추출 (.service 확장자가 입력되었다면 제거)
      SERVICE_NAME="${1%.service}"
      ;;
  esac
  shift
done

if [[ -z "${SERVICE_NAME}" ]]; then
  die "서비스 이름이 지정되지 않았습니다."
fi

##
# OS 정보 및 버전을 확인합니다. (CentOS 6 등 구버전 대응)
##
check_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-0}"
  elif [[ -r /etc/centos-release || -r /etc/redhat-release ]]; then
    # /etc/os-release가 없는 구형 RHEL/CentOS (예: CentOS 6)
    OS_ID="centos"
    # 릴리즈 파일에서 메이저 버전 숫자만 추출
    OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -n 1)
  else
    die "운영체제 정보를 확인할 수 없습니다."
  fi

  local major_ver="${OS_VERSION%%.*}"
  
  # OS 지원 여부 검증
  case "${OS_ID}" in
    ubuntu)
      if (( major_ver < 18 )); then die "Ubuntu 18 이상만 지원합니다."; fi
      ;;
    centos|rhel|ol)
      if (( major_ver < 6 )); then die "Enterprise Linux 6 이상만 지원합니다."; fi
      ;;
    rocky)
      if (( major_ver < 9 )); then die "Rocky Linux 9 이상만 지원합니다."; fi
      ;;
    *)
      die "지원하지 않는 OS입니다: ${OS_ID}"
      ;;
  esac

  log "OS 감지 완료: ${OS_ID} ${major_ver}"
}

##
# Systemd 기반 시스템에서 서비스를 완벽히 삭제합니다.
#
# @param $1 {string} 삭제할 서비스 이름
##
remove_systemd_service() {
  local svc="$1"
  local svc_file="${svc}.service"
  
  log "Systemd 서비스 [${svc_file}] 삭제 프로세스를 시작합니다."

  # 1. 서비스 중지 및 비활성화
  if systemctl is-active --quiet "${svc}"; then
    log "서비스를 중지합니다..."
    sudo systemctl stop "${svc}"
  fi

  if systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
    log "서비스 자동 시작을 비활성화합니다..."
    sudo systemctl disable "${svc}"
  fi

  # 2. 서비스 데몬 파일 및 관련 Drop-in 디렉토리 삭제
  local paths=(
    "/etc/systemd/system/${svc_file}"
    "/etc/systemd/system/${svc_file}.d"
    "/usr/lib/systemd/system/${svc_file}"
    "/lib/systemd/system/${svc_file}"
  )

  local removed=0
  for target_path in "${paths[@]}"; do
    if sudo test -e "${target_path}"; then
      log "삭제 중: ${target_path}"
      sudo rm -rf "${target_path}"
      removed=1
    fi
  done

  if [[ ${removed} -eq 0 ]]; then
    warn "시스템에서 [${svc_file}] 데몬 파일을 찾을 수 없습니다."
  fi

  # 3. 데몬 리로드 및 캐시 초기화
  log "Systemd 데몬을 재설정합니다..."
  sudo systemctl daemon-reload
  sudo systemctl reset-failed "${svc}" 2>/dev/null || true

  log "[${svc_file}] 삭제가 완료되었습니다."
}

##
# SysVinit 기반 시스템(CentOS 6 등)에서 서비스를 완벽히 삭제합니다.
#
# @param $1 {string} 삭제할 서비스 이름
##
remove_sysvinit_service() {
  local svc="$1"
  
  log "SysVinit 서비스 [${svc}] 삭제 프로세스를 시작합니다."

  if sudo service "${svc}" status >/dev/null 2>&1; then
    log "서비스를 중지합니다..."
    sudo service "${svc}" stop
  fi

  if chkconfig --list "${svc}" >/dev/null 2>&1; then
    log "chkconfig에서 서비스를 비활성화 및 삭제합니다..."
    sudo chkconfig "${svc}" off
    sudo chkconfig --del "${svc}"
  fi

  if sudo test -f "/etc/init.d/${svc}"; then
    log "삭제 중: /etc/init.d/${svc}"
    sudo rm -f "/etc/init.d/${svc}"
  else
    warn "시스템에서 [${svc}] 초기화 스크립트를 찾을 수 없습니다."
  fi

  log "[${svc}] 삭제가 완료되었습니다."
}

# ==========================================
# 메인 실행부
# ==========================================
check_os

# systemctl 명령어 존재 여부로 Systemd vs SysVinit 분기 처리
if command -v systemctl >/dev/null 2>&1; then
  remove_systemd_service "${SERVICE_NAME}"
else
  # systemctl이 없으면 SysVinit(CentOS 6 등)으로 간주
  if command -v chkconfig >/dev/null 2>&1; then
    remove_sysvinit_service "${SERVICE_NAME}"
  else
    die "이 시스템에서 지원하는 서비스 관리자(systemctl 또는 chkconfig)를 찾을 수 없습니다."
  fi
fi

exit 0
