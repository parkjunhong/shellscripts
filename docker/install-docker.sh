#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-10-02
# @desc : support RHEL 7 or higher, Oracle Linux 7 or higher, Ubuntu 20.04 or higher, RockyOS 8 or higher, CentOS 7 or higher, Debian 11 or higher
# @installation : 
# 1. insert 'source <path>/install-docker.sh.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-docker.sh' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
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
    for func in "${FUNCNAME[@]:1}"
    do 
      printf "$formatr" "["$idx"]" "$func"
      ((idx++)) || true
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi 
  echo 
  echo "사용법 (Usage): ./$FILENAME [옵션]"
  echo ""
  echo "[설명]"
  echo "  패키지 관리 도구(APT, DNF, YUM)를 기반으로 Docker CE 및 관련 플러그인을 자동 감지하여 설치합니다."
  echo "  타사 저장소(PPA) 오류 격리, 패키지 락 대기 및 서비스 자동 등록을 지원합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --pkg-mgr <도구>   패키지 관리 도구 강제 지정 (선택 사항: 'apt', 'dnf', 'yum')"
  echo "  -h, --help         도움말을 출력하고 종료합니다."
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

# 전역 상태 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
MANUAL_PKG_MGR=""
DETECTED_PKG_MGR=""
SUDO_CMD=()

OS_ID=""
OS_ID_LIKE=""
OS_VERSION_ID=""
OS_CODENAME=""

##
# 정보성 로그 메시지를 출력합니다.
#
# @param $1 {string} 출력할 메시지
#
# @return (표준 출력 로그)
##
log_info() {
  printf 'ℹ️  [INFO] %s\n' "$*"
}

##
# 경고성 로그 메시지를 출력합니다.
#
# @param $1 {string} 출력할 경고 메시지
#
# @return (표준 출력 로그)
##
log_warn() {
  printf '⚠️  [WARN] %s\n' "$*"
}

##
# 작업 내용과 실행할 명령어를 표준 출력에 기록한 뒤 원자적으로 실행합니다.
#
# @param $1 {string} 작업 설명
# @param $@ {array} 실행할 명령어 및 인자
#
# @return (명령어 실행 결과 반환)
##
execute_cmd() {
  local desc="$1"
  shift
  printf '⚙️  [EXEC] %s\n' "$desc"
  printf '   -> %s\n' "$*"
  "$@"
}

##
# 스크립트 실행에 필요한 루트 권한 가용성을 사전 점검하고 sudo 자격 증명을 초기화합니다.
#
# @param 없음
#
# @return (전역 배열 SUDO_CMD 초기화)
##
ensure_privileges() {
  if (( EUID == 0 )); then
    SUDO_CMD=()
  else
    if ! command -v sudo >/dev/null 2>&1; then
      help "루트가 아닌 사용자 환경에서 실행하려면 sudo 명령어가 시스템에 설치되어 있어야 합니다." "$LINENO"
      exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
      echo "🔐 [AUTH] 시스템 패키지 설치 및 Docker 서비스 구성을 위해 sudo 인증이 필요합니다."
      sudo -v || {
        help "sudo 권한 획득에 실패했습니다." "$LINENO"
        exit 1
      }
    fi
    SUDO_CMD=(sudo)
  fi
}

##
# /etc/os-release 파일로부터 OS 식별자 및 메타데이터를 정규화하여 파싱합니다.
#
# @param 없음
#
# @return (전역 OS 메타데이터 변수 초기화)
##
load_os_metadata() {
  if [ ! -r /etc/os-release ]; then
    help "/etc/os-release 파일을 읽을 수 없습니다. 지원되지 않는 리눅스 환경입니다." "$LINENO"
    exit 1
  fi

  OS_ID="$(grep -E '^ID=' /etc/os-release | cut -d= -f2- | tr -d '"'"'" || true)"
  OS_ID_LIKE="$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2- | tr -d '"'"'" || true)"
  OS_VERSION_ID="$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2- | tr -d '"'"'" || true)"
  OS_CODENAME="$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2- | tr -d '"'"'" || true)"

  local ubuntu_codename=""
  ubuntu_codename="$(grep -E '^UBUNTU_CODENAME=' /etc/os-release | cut -d= -f2- | tr -d '"'"'" || true)"
  if [ -n "$ubuntu_codename" ]; then
    OS_CODENAME="$ubuntu_codename"
  fi

  log_info "운영체제 메타데이터 탐지: ID=${OS_ID}, ID_LIKE=${OS_ID_LIKE:-none}, VERSION_ID=${OS_VERSION_ID}"
}

##
# 시스템에 존재하는 패키지 관리 도구를 우선순위에 따라 자동 감지합니다.
#
# @param 없음
#
# @return {string} 감지된 패키지 관리자 이름 (apt, dnf, yum)
##
detect_package_manager() {
  if [ -n "$MANUAL_PKG_MGR" ]; then
    if ! command -v "$MANUAL_PKG_MGR" >/dev/null 2>&1; then
      help "수동 지정된 패키지 관리자('$MANUAL_PKG_MGR')를 시스템에서 찾을 수 없습니다." "$LINENO"
      exit 1
    fi
    echo "$MANUAL_PKG_MGR"
    return 0
  fi

  if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID_LIKE" == *"debian"* || "$OS_ID_LIKE" == *"ubuntu"* ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      echo "apt"
      return 0
    fi
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
    return 0
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
    return 0
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
    return 0
  fi

  help "지원 가능한 패키지 관리 도구(apt, dnf, yum)를 감지하지 못했습니다." "$LINENO"
  exit 1
}

##
# APT 패키지 관리자의 잠금(Lock)이 해제될 때까지 안전하게 대기합니다.
#
# @param 없음
#
# @return (잠금 해제 완료)
##
wait_for_apt_locks() {
  local max_retries=30
  local retry_count=0

  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    if (( retry_count >= max_retries )); then
      help "다른 프로세스가 APT/DPKG 잠금을 장시간 점유하고 있어 작업을 진행할 수 없습니다." "$LINENO"
      exit 1
    fi
    log_info "다른 패키지 관리 프로세스가 실행 중입니다. 잠금 해제를 대기합니다 ($((retry_count + 1))/${max_retries})..."
    sleep 2
    ((retry_count++)) || true
  done
}

##
# 타사 저장소 오류가 발생해도 중단되지 않도록 복원력을 갖춘 전체 APT 인덱스 업데이트를 실행합니다.
#
# @param 없음
#
# @return (업데이트 수행 완료)
##
resilient_apt_update() {
  wait_for_apt_locks
  printf '⚙️️  [EXEC] 패키지 목록을 업데이트합니다 (타사 저장소 장애 격리 적용)...\n'
  printf '   -> sudo apt-get update -y\n'

  local exit_code=0
  "${SUDO_CMD[@]}" apt-get update -y || exit_code=$?

  if (( exit_code != 0 )); then
    log_warn "일부 외부 PPA/타사 저장소에서 갱신 오류가 발생했습니다 (종료 코드: ${exit_code})."
    log_warn "무관한 타사 저장소 오류를 무시하고 필수 패키지 설치 파이프라인을 계속 진행합니다."
  else
    log_info "패키지 목록 업데이트가 정상적으로 완료되었습니다."
  fi
}

##
# Docker 전용 sources.list.d 파일만 지정하여 타사 저장소 에러와 완전히 격리된 인덱스 갱신을 수행합니다.
#
# @param 없음
#
# @return (Docker 전용 인덱스 갱신 완료)
##
isolated_docker_apt_update() {
  wait_for_apt_locks
  printf '⚙️  [EXEC] Docker 공식 저장소 전용 인덱스를 독립 갱신합니다 (타사 PPA 완전 격리)...\n'
  printf '   -> sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/docker.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"\n'

  local exit_code=0
  "${SUDO_CMD[@]}" apt-get update \
    -o Dir::Etc::sourcelist="sources.list.d/docker.list" \
    -o Dir::Etc::sourceparts="-" \
    -o APT::Get::List-Cleanup="0" || exit_code=$?

  if (( exit_code != 0 )); then
    log_warn "Docker 전용 인덱스 단독 갱신에 실패하여 전체 복원 업데이트로 재시도합니다."
    resilient_apt_update
  else
    log_info "Docker 공식 저장소 인덱스 갱신이 완료되었습니다."
  fi
}

##
# APT 패키지 관리 도구를 기반으로 Docker CE를 설치합니다 (Debian/Ubuntu 계열).
#
# @param 없음
#
# @return (Docker 패키지 설치 완료)
##
install_via_apt() {
  log_info "APT 패키지 관리 도구 기반 Docker 엔진 설치를 시작합니다."

  local repo_os="ubuntu"
  if [[ "$OS_ID" == "debian" || ( "$OS_ID_LIKE" == *"debian"* && "$OS_ID" != "ubuntu" ) ]]; then
    repo_os="debian"
  fi

  local codename="${OS_CODENAME}"
  if [ -z "$codename" ] && command -v lsb_release >/dev/null 2>&1; then
    codename="$(lsb_release -cs 2>/dev/null || true)"
  fi
  if [ -z "$codename" ]; then
    help "APT 저장소 등록에 필요한 배포판 코드명(Codename)을 감지할 수 없습니다." "$LINENO"
    exit 1
  fi

  # 1. 초기 시스템 패키지 목록 갱신 (타사 PPA 오류 격리)
  resilient_apt_update

  # 2. 필수 의존성 패키지 설치
  wait_for_apt_locks
  execute_cmd "필수 보안 및 네트워크 유틸리티를 설치합니다." \
    "${SUDO_CMD[@]}" apt-get install -y ca-certificates curl gnupg

  # 3. Docker 공식 GPG 키링 등록
  execute_cmd "GPG 키링 디렉터리를 생성합니다." \
    "${SUDO_CMD[@]}" install -m 0755 -d /etc/apt/keyrings

  printf '🔑 [INFO] Docker 공식 GPG 키를 다운로드하여 등록합니다 (OS: %s)...\n' "$repo_os"
  curl -fsSL "https://download.docker.com/linux/${repo_os}/gpg" | \
    "${SUDO_CMD[@]}" gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  "${SUDO_CMD[@]}" chmod a+r /etc/apt/keyrings/docker.gpg

  # 4. Docker 공식 저장소 등록
  local arch=""
  arch="$(dpkg --print-architecture)"
  printf '📦 [INFO] Docker 공식 APT 저장소를 구성합니다 (Arch: %s, Codename: %s)...\n' "$arch" "$codename"

  echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${repo_os} ${codename} stable" | \
    "${SUDO_CMD[@]}" tee /etc/apt/sources.list.d/docker.list >/dev/null

  # 5. Docker 저장소 전용 독립 갱신 (외부 PPA 404 장애 완전 격리)
  isolated_docker_apt_update

  # 6. Docker 엔진 패키지 설치
  wait_for_apt_locks
  execute_cmd "Docker CE 엔진 및 핵심 플러그인을 설치합니다." \
    "${SUDO_CMD[@]}" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

##
# DNF 또는 YUM 패키지 관리 도구를 기반으로 Docker CE를 설치합니다 (RHEL/Rocky/CentOS/Fedora 계열).
#
# @param $1 {string} 실행할 패키지 관리자 명령어 ('dnf' 또는 'yum')
#
# @return (Docker 패키지 설치 완료)
##
install_via_rpm_manager() {
  local mgr="$1"
  log_info "${mgr^^} 패키지 관리 도구 기반 Docker 엔진 설치를 시작합니다."

  local repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
  if [ "$OS_ID" == "fedora" ]; then
    repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
  fi

  if [ "$mgr" == "dnf" ]; then
    execute_cmd "dnf-plugins-core 패키지를 설치합니다." "${SUDO_CMD[@]}" dnf install -y dnf-plugins-core
    execute_cmd "Docker CE 공식 저장소를 추가합니다." "${SUDO_CMD[@]}" dnf config-manager --add-repo "$repo_url"
    execute_cmd "Docker CE 패키지를 설치합니다." \
      "${SUDO_CMD[@]}" dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    execute_cmd "yum-utils 패키지를 설치합니다." "${SUDO_CMD[@]}" yum install -y yum-utils
    execute_cmd "Docker CE 공식 저장소를 추가합니다." "${SUDO_CMD[@]}" yum-config-manager --add-repo "$repo_url"
    execute_cmd "Docker CE 패키지를 설치합니다." \
      "${SUDO_CMD[@]}" yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
}

##
# 실행 사용자를 docker 시스템 그룹에 등록하여 비-루트 권한 실행 환경을 구성합니다.
#
# @param 없음
#
# @return (그룹 구성 완료 상태 콘솔 출력)
##
configure_docker_group() {
  local target_user="${SUDO_USER:-$(id -un)}"

  if [ -z "$target_user" ] || [ "$target_user" == "root" ]; then
    log_info "현재 실행 계정이 루트(root)이므로 docker 그룹 추가 단계를 건너뜁니다."
    return 0
  fi

  log_info "사용자 '${target_user}'의 docker 그룹 권한 설정을 진행합니다."

  if ! getent group docker >/dev/null 2>&1; then
    execute_cmd "docker 시스템 그룹을 생성합니다." "${SUDO_CMD[@]}" groupadd docker
  fi

  if id -nG "$target_user" 2>/dev/null | grep -qw "docker"; then
    echo "ℹ️  [INFO] 사용자 '${target_user}'는 이미 docker 그룹에 속해 있습니다."
  else
    execute_cmd "사용자 '${target_user}'를 docker 그룹에 등록합니다." \
      "${SUDO_CMD[@]}" usermod -aG docker "$target_user"
    echo "✅ [SUCCESS] 사용자 '${target_user}'가 docker 그룹에 정상 등록되었습니다."
  fi

  echo ""
  echo "================================================================================"
  echo "💡 [사용자 권한 안내]"
  echo "   sudo 없이 docker 명령어를 바로 실행하려면 아래 방법 중 하나를 적용하십시오:"
  echo "   1) 현재 터미널 세션에 즉시 적용: newgrp docker"
  echo "   2) 현재 세션을 로그아웃한 후 다시 로그인"
  echo "================================================================================"
}

##
# 설치 완료 후 Docker 데몬을 활성화하고 바이너리 동작 무결성을 검증합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
verify_installation() {
  execute_cmd "Docker 서비스를 부팅 시 자동 시작하도록 활성화하고 구동합니다." \
    "${SUDO_CMD[@]}" systemctl enable --now docker

  if command -v docker >/dev/null 2>&1; then
    local docker_ver=""
    docker_ver="$(docker --version 2>/dev/null || true)"
    echo "================================================================================"
    echo "🎉 [SUCCESS] Docker 엔진이 성공적으로 설치 및 구동되었습니다!"
    echo "   - 바이너리 버전: $docker_ver"
    echo "   - 실행 패키지 도구: ${DETECTED_PKG_MGR}"
    echo "================================================================================"
  else
    help "Docker 설치 후 시스템에서 'docker' 바이너리를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 명령줄 인자 배열
#
# @return (없음)
##
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pkg-mgr)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--pkg-mgr 옵션에는 사용할 도구 이름('apt', 'dnf', 'yum')을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        case "$2" in
          apt|dnf|yum)
            MANUAL_PKG_MGR="$2"
            ;;
          *)
            help "지원하지 않는 패키지 관리자입니다 -> '$2' ('apt', 'dnf', 'yum' 중 선택)" "$LINENO"
            exit 1
            ;;
        esac
        shift 2
        ;;
      -h|--help)
        help "" ""
        exit 0
        ;;
      -*)
        help "지원하지 않는 옵션입니다 (단축 옵션은 지원하지 않습니다) -> $1" "$LINENO"
        exit 1
        ;;
      *)
        help "잘못된 파라미터가 입력되었습니다 -> $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  # 1. 권한 확인 및 OS 메타데이터 로드
  ensure_privileges
  load_os_metadata

  # 2. 패키지 관리 도구 판별
  DETECTED_PKG_MGR="$(detect_package_manager)"
  log_info "선택된 패키지 관리 도구: ${DETECTED_PKG_MGR}"

  # 3. 패키지 관리자 엔진별 설치 파이프라인 수행
  case "$DETECTED_PKG_MGR" in
    apt)
      install_via_apt
      ;;
    dnf|yum)
      install_via_rpm_manager "$DETECTED_PKG_MGR"
      ;;
    *)
      help "처리할 수 없는 패키지 관리자 분기입니다 -> '$DETECTED_PKG_MGR'" "$LINENO"
      exit 1
      ;;
  esac

  # 4. 서비스 기동 및 설치 검증
  verify_installation

  # 5. 사용자 docker 그룹 바인딩
  configure_docker_group
}

main "$@"
exit 0
