#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-09-08
# @desc : support RHEL 8+, Oracle Linux 8+, Ubuntu 20.04+, RockyOS 8+, CentOS 8+
# @installation : 
# 1. insert 'source <path>/setup-compose-service.sh.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
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
  echo "  임의의 Docker Compose 기반 서비스를 Systemd O/S 서비스로 등록하고"
  echo "  사용자 실행 경로(\$HOME/bin) 심볼릭 링크 및 시스템 Bash Completion 등록/해제를 지원하는"
  echo "  제어 스크립트(ctl.sh)를 생성합니다."
  echo "  SELinux 활성화 환경(Rocky Linux, RHEL 등)에 대응하여 파일 소유권을 root:root 로 잠그고 보안 컨텍스트를 부여합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --docker-compose-dir <경로>    docker-compose.yml 파일이 위치한 디렉터리 경로 (필수)"
  echo "  --service <서비스명>           등록할 서비스 이름 (영문, 숫자, 하이픈, 언더바, 필수)"
  echo "  --version <버전>               서비스 버전 (선택 사항, 지정 시 파일명에 결합)"
  echo "  --output-dir <경로>            결과물 파일들을 저장할 디렉터리 (기본값: --docker-compose-dir)"
  echo "  --help                         도움말을 출력하고 종료합니다."
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

# 전역 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
DOCKER_COMPOSE_DIR=""
SERVICE_NAME=""
SERVICE_VERSION=""
OUTPUT_DIR=""

ABS_COMPOSE_DIR=""
ABS_OUTPUT_DIR=""
COMPOSE_FILE_NAME="docker-compose.yml"
SERVICE_FULL_NAME=""
CURRENT_DATE="2026-09-08"

##
# 입력받은 Docker Compose 디렉터리의 유효성 및 설정 파일 존재 여부를 검증합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
validate_compose_dir() {
  if [ -z "$DOCKER_COMPOSE_DIR" ]; then
    help "--docker-compose-dir 옵션은 필수 항목입니다." "$LINENO"
    exit 1
  fi

  if [ ! -d "$DOCKER_COMPOSE_DIR" ]; then
    help "지정한 Docker Compose 디렉터리가 존재하지 않습니다 -> '$DOCKER_COMPOSE_DIR'" "$LINENO"
    exit 1
  fi

  ABS_COMPOSE_DIR="$(readlink -f "$DOCKER_COMPOSE_DIR")"

  if [ -f "$ABS_COMPOSE_DIR/docker-compose.yml" ]; then
    COMPOSE_FILE_NAME="docker-compose.yml"
  elif [ -f "$ABS_COMPOSE_DIR/docker-compose.yaml" ]; then
    COMPOSE_FILE_NAME="docker-compose.yaml"
  else
    help "해당 디렉터리에 docker-compose.yml 또는 docker-compose.yaml 파일이 존재하지 않습니다 -> '$ABS_COMPOSE_DIR'" "$LINENO"
    exit 1
  fi
}

##
# 입력받은 서비스 이름 및 버전 문자열의 유효성을 검증하고 전체 서비스명을 확정합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
validate_service_identifiers() {
  if [ -z "$SERVICE_NAME" ]; then
    help "--service 옵션은 필수 항목입니다." "$LINENO"
    exit 1
  fi

  if [[ ! "$SERVICE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    help "서비스 이름에는 영문, 숫자, 하이픈(-), 밑줄(_)만 사용할 수 있습니다 -> '$SERVICE_NAME'" "$LINENO"
    exit 1
  fi

  if [ -n "$SERVICE_VERSION" ]; then
    if [[ ! "$SERVICE_VERSION" =~ ^[a-zA-Z0-9._-]+$ ]]; then
      help "버전 문자열에는 영문, 숫자, 마침표(.), 밑줄(_), 하이픈(-)만 사용할 수 있습니다 -> '$SERVICE_VERSION'" "$LINENO"
      exit 1
    fi
    SERVICE_FULL_NAME="${SERVICE_NAME}-${SERVICE_VERSION}"
  else
    SERVICE_FULL_NAME="${SERVICE_NAME}"
  fi
}

##
# 동일한 이름의 Systemd 서비스가 이미 시스템에 존재하는지 검증하여 충돌을 방지합니다.
#
# @param $1 {string} 확인할 Systemd 유닛 이름
#
# @return (이미 존재할 경우 에러 출력 후 exit 1)
##
verify_service_collision() {
  local target_unit="$1"
  local systemd_path="/etc/systemd/system/${target_unit}"

  if [ -f "$systemd_path" ]; then
    help "해당 서비스 파일이 이미 시스템에 존재합니다 -> '$systemd_path'. 기존 서비스를 먼저 중지 및 제거하십시오." "$LINENO"
    exit 1
  fi

  if command -v systemctl >/dev/null 2>&1; then
    local unit_state=""
    unit_state="$(systemctl is-active "$target_unit" 2>/dev/null || true)"
    if [[ "$unit_state" == "active" || "$unit_state" == "activating" ]]; then
      help "동일한 이름의 서비스('$target_unit')가 현재 활성화(active) 상태로 구동 중입니다." "$LINENO"
      exit 1
    fi
  fi
}

##
# 출력 디렉터리의 존재 여부를 확인하고 미존재 시 생성하며 쓰기 권한을 확인합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
resolve_output_dir() {
  local target="${OUTPUT_DIR:-$ABS_COMPOSE_DIR}"

  if [ ! -d "$target" ]; then
    echo "📁 [INFO] 출력 디렉터리를 생성합니다 -> $target" >&2
    if ! mkdir -p "$target" 2>/dev/null; then
      if command -v sudo >/dev/null 2>&1; then
        echo "🔐 [AUTH] 출력 디렉터리 생성을 위해 sudo 권한을 요청합니다 -> $target" >&2
        sudo mkdir -p "$target" || {
          help "출력 디렉터리 생성에 실패했습니다 -> '$target'" "$LINENO"
          exit 1
        }
      else
        help "출력 디렉터리 생성 권한이 없으며 sudo 명령어를 찾을 수 없습니다 -> '$target'" "$LINENO"
        exit 1
      fi
    fi
  fi

  ABS_OUTPUT_DIR="$(readlink -f "$target")"

  if [ ! -w "$ABS_OUTPUT_DIR" ]; then
    if ! sudo -n true 2>/dev/null && command -v sudo >/dev/null 2>&1; then
      echo "🔐 [AUTH] 출력 디렉터리 파일 작성을 위해 sudo 인증이 필요합니다 -> $ABS_OUTPUT_DIR" >&2
      sudo -v || {
        help "출력 디렉터리에 쓰기 권한이 없으며 sudo 인증에 실패했습니다 -> '$ABS_OUTPUT_DIR'" "$LINENO"
        exit 1
      }
    fi
  fi
}

##
# 임시 파일을 대상 경로로 원자적으로 이동하고 소유권을 root:root 로 설정하며 SELinux 레이블을 정상화합니다.
#
# @param $1 {string} 원본 임시 파일 경로
# @param $2 {string} 최종 대상 파일 경로
# @param $3 {string} 권한 모드 (예: 755 또는 644)
# @param $4 {string} 파일 용도 구분 ('script', 'service', 'completion')
#
# @return (파일 저장, 소유권 변경 및 SELinux 컨텍스트 적용 완료)
##
atomic_install_file() {
  local src_file="$1"
  local dest_file="$2"
  local mode="$3"
  local file_type="$4"

  local sudo_cmd=()
  if (( EUID != 0 )); then
    sudo_cmd=(sudo)
  fi

  "${sudo_cmd[@]}" mv -f "$src_file" "$dest_file"
  "${sudo_cmd[@]}" chown root:root "$dest_file"
  "${sudo_cmd[@]}" chmod "$mode" "$dest_file"

  if command -v restorecon >/dev/null 2>&1; then
    "${sudo_cmd[@]}" restorecon -vF "$dest_file" >/dev/null 2>&1 || true
  fi

  if [[ "$file_type" == "script" ]] && command -v chcon >/dev/null 2>&1; then
    "${sudo_cmd[@]}" chcon -t bin_t "$dest_file" >/dev/null 2>&1 || true
  elif [[ "$file_type" == "service" ]] && command -v chcon >/dev/null 2>&1; then
    "${sudo_cmd[@]}" chcon -t systemd_unit_file_t "$dest_file" >/dev/null 2>&1 || true
  fi
}

##
# 서비스 제어 스크립트(${service_full_name}-ctl.sh)를 생성합니다.
#
# @param $1 {string} 생성 대상 파일 경로
# @param $2 {string} Compose 디렉터리 절대 경로
# @param $3 {string} Compose 파일명
# @param $4 {string} 서비스 풀네임
# @param $5 {string} Service 유닛 파일 절대 경로
# @param $6 {string} Completion 파일 절대 경로
# @param $7 {string} 생성될 제어 스크립트 파일명
#
# @return (제어 스크립트 생성 완료)
##
generate_ctl_script() {
  local ctl_path="$1"
  local compose_dir="$2"
  local compose_file="$3"
  local full_name="$4"
  local service_path="$5"
  local completion_path="$6"
  local ctl_filename="$7"

  local tmp_ctl=""
  tmp_ctl="$(mktemp "${TMPDIR:-/tmp}/${full_name}-ctl.XXXXXX")"

  # 갱신된 지식 파일의 @installation 규격을 동적으로 치환하여 헤더 생성
  cat << HEADER_EOF > "$tmp_ctl"
#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : ${CURRENT_DATE}
# @desc : support RHEL 8+, Oracle Linux 8+, Ubuntu 20.04+, RockyOS 8+, CentOS 8+
# @installation : 
# 1. insert 'source <path>/${ctl_filename}" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/${ctl_filename}' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=\$(basename "\$0")

help(){
  if [ ! -z "\${1:-}" ];
  then
    local indent=10
    local formatl=" - %-"\$indent"s: %s\n"
    local formatr=" - %"\$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "\$formatl" "filename" "\$FILENAME"
    printf "\$formatl" "line" "\${2:-}"
    printf "\$formatl" "callstack"
    local idx=1
    for func in "\${FUNCNAME[@]:1}"
    do
      printf "\$formatr" "["\$idx"]" "\$func"
      ((idx++)) || true
    done
    printf "\$formatl" "cause" "\$1"
    echo "================================================================================"
  fi
  echo
  echo "사용법: ./\$FILENAME <start | stop | restart | status | enable | disable> [서비스명] [옵션]"
  echo ""
  echo "[동작 (Actions)]"
  echo "  start [서비스]    : Compose 전체 또는 지정한 서비스를 기동합니다 (up -d)."
  echo "  stop [서비스]     : Compose 전체(down) 또는 지정한 개별 서비스(stop)를 중지합니다."
  echo "  restart [서비스]  : Compose 전체 또는 지정한 서비스를 재시작합니다 (stop 후 start)."
  echo "  status [서비스]   : Compose 컨테이너 상태 및 Systemd 서비스 상태를 조회합니다."
  echo "  enable            : Systemd 서비스 등록, \$HOME/bin 심볼릭 링크 생성, Bash Completion 시스템 등록을 수행합니다."
  echo "  disable           : Systemd 서비스 비활성화, \$HOME/bin 심볼릭 링크 삭제, Bash Completion 시스템 등록 해제를 수행합니다."
  echo ""
  echo "[옵션]"
  echo "  --help            이 도움말을 출력하고 종료합니다."
}

trap 'help "명령 실행 중 오류가 발생했습니다." "\$LINENO"' ERR

ACTION="\${1:-}"
TARGET_CONTAINER="\${2:-}"

if [[ "\$ACTION" == "-h" || "\$ACTION" == "--help" ]]; then
  help "" ""
  exit 0
fi

HEADER_EOF

  cat << VARS_EOF >> "$tmp_ctl"
COMPOSE_DIR="${compose_dir}"
COMPOSE_FILE="${compose_file}"
SERVICE_FULL_NAME="${full_name}"
SERVICE_SOURCE_PATH="${service_path}"
COMPLETION_SOURCE_PATH="${completion_path}"
CTL_SCRIPT_PATH="${ctl_path}"
CTL_SCRIPT_NAME="$(basename "${ctl_path}")"
SYSTEMD_SERVICE_NAME="${full_name}.service"
SYSTEMD_TARGET_PATH="/etc/systemd/system/\${SYSTEMD_SERVICE_NAME}"

VARS_EOF

  cat << 'BODY_EOF' >> "$tmp_ctl"
DOCKER_CMD=()
COMPOSE_BASE_CMD=()

##
# 시스템의 Docker 및 Compose 엔진 가용성을 점검하고 실행 배열을 초기화합니다.
#
# @param 없음
#
# @return (전역 배열 DOCKER_CMD 및 COMPOSE_BASE_CMD 초기화)
##
ensure_docker_compose() {
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:${PATH:-}"

  if ! command -v docker >/dev/null 2>&1; then
    help "시스템에서 'docker' 바이너리를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi

  if docker info >/dev/null 2>&1; then
    DOCKER_CMD=(docker)
  else
    if (( EUID == 0 )); then
      help "Docker 데몬이 구동 중이지 않거나 소켓 응답이 없습니다." "$LINENO"
      exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
      help "Docker 소켓 접근을 위해 sudo 권한이 필요하나 sudo 명령어가 없습니다." "$LINENO"
      exit 1
    fi
    DOCKER_CMD=(sudo docker)
  fi

  if "${DOCKER_CMD[@]}" compose version >/dev/null 2>&1; then
    COMPOSE_BASE_CMD=("${DOCKER_CMD[@]}" compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    if (( EUID == 0 )); then
      COMPOSE_BASE_CMD=(docker-compose)
    else
      COMPOSE_BASE_CMD=(sudo docker-compose)
    fi
  else
    help "Docker Compose(v1 또는 v2 플러그인)를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi
}

##
# 프로젝트 환경 설정 파일(.env) 존재 여부에 따라 compose 명령을 실행합니다.
#
# @param $@ {string} Compose 서브 커맨드 인자
#
# @return (Compose 명령어 실행)
##
run_compose() {
  local compose_args=("-f" "$COMPOSE_DIR/$COMPOSE_FILE")
  if [ -f "$COMPOSE_DIR/.env" ]; then
    compose_args+=("--env-file" "$COMPOSE_DIR/.env")
  fi

  (
    cd "$COMPOSE_DIR"
    "${COMPOSE_BASE_CMD[@]}" "${compose_args[@]}" "$@"
  )
}

##
# Compose 파일에 정의된 유효한 서비스 목록을 조회합니다.
#
# @param 없음
#
# @return {string} 줄바꿈으로 구분된 서비스명 목록
##
get_defined_services() {
  local svc_list=""
  svc_list="$(run_compose config --services 2>/dev/null || true)"
  if [ -z "$svc_list" ]; then
    svc_list="$(awk '/^services:/{flag=1; next} /^[^ ]/{flag=0} flag && /^  [a-zA-Z0-9_-]+:/{gsub(/:/, "", $1); print $1}' "$COMPOSE_DIR/$COMPOSE_FILE" 2>/dev/null || true)"
  fi
  echo "$svc_list"
}

##
# 지정된 개별 서비스명이 docker-compose.yml 에 존재하는지 검증합니다.
#
# @param $1 {string} 검증할 서비스명
#
# @return (존재하지 않을 경우 에러 출력 후 exit 1)
##
validate_target_service() {
  local target="$1"
  if [ -n "$target" ]; then
    local valid_services=""
    valid_services="$(get_defined_services)"
    if ! grep -Fxq "$target" <<< "$valid_services"; then
      help "지정한 서비스('$target')가 docker-compose.yml 파일에 정의되어 있지 않습니다. (정의된 서비스: $(echo "$valid_services" | tr '\n' ' '))" "$LINENO"
      exit 1
    fi
  fi
}

##
# 서비스를 기동하기 전 설정 파일 및 환경변수의 무결성을 검증합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
preflight_check() {
  echo "🔍 [PRE-FLIGHT] Docker Compose 설정 파일 무결성 검증 중..."
  if ! run_compose config >/dev/null; then
    help "Docker Compose 설정 파일($COMPOSE_DIR/$COMPOSE_FILE) 구문 또는 환경변수 검증에 실패했습니다." "$LINENO"
    exit 1
  fi
  echo "✅ [PRE-FLIGHT] 설정 파일 무결성 검증 완료."
}

##
# 서비스를 기동합니다.
#
# @param $1 {string} 대상 컨테이너 서비스명 (빈 값일 경우 전체 기동)
#
# @return (기동 결과 출력)
##
service_start() {
  local target_svc="${1:-}"
  preflight_check

  if [ -n "$target_svc" ]; then
    echo "🚀 [START] Compose 서비스 '$target_svc' 기동 중 (docker compose up -d $target_svc)..."
    run_compose up -d "$target_svc"
    echo "✅ [SUCCESS] Compose 서비스 '$target_svc' 가 정상 기동되었습니다."
  else
    echo "🚀 [START] 전체 Compose 서비스 기동 중 (docker compose up -d)..."
    run_compose up -d --remove-orphans
    echo "✅ [SUCCESS] 전체 Compose 서비스가 백그라운드에서 정상 기동되었습니다."
  fi
}

##
# 서비스를 중지합니다.
#
# @param $1 {string} 대상 컨테이너 서비스명 (빈 값일 경우 전체 down)
#
# @return (중지 결과 출력)
##
service_stop() {
  local target_svc="${1:-}"

  if [ -n "$target_svc" ]; then
    echo "🛑 [STOP] Compose 서비스 '$target_svc' 중지 중 (docker compose stop $target_svc)..."
    run_compose stop "$target_svc"
    echo "✅ [SUCCESS] Compose 서비스 '$target_svc' 가 안전하게 중지되었습니다."
  else
    echo "🛑 [STOP] 전체 Compose 서비스 종료 및 정리 중 (docker compose down)..."
    run_compose down --timeout 30 --remove-orphans
    echo "✅ [SUCCESS] 전체 Compose 서비스가 안전하게 중지 및 정리되었습니다."
  fi
}

##
# 서비스를 재시작합니다.
#
# @param $1 {string} 대상 컨테이너 서비스명 (빈 값일 경우 전체 재시작)
#
# @return (재시작 결과 출력)
##
service_restart() {
  local target_svc="${1:-}"

  if [ -n "$target_svc" ]; then
    echo "🔄 [RESTART] Compose 서비스 '$target_svc' 재시작 중..."
    service_stop "$target_svc"
    service_start "$target_svc"
    echo "✅ [SUCCESS] Compose 서비스 '$target_svc' 재시작이 완료되었습니다."
  else
    echo "🔄 [RESTART] 전체 Compose 서비스 재시작 중..."
    service_stop ""
    service_start ""
    echo "✅ [SUCCESS] 전체 Compose 서비스 재시작이 완료되었습니다."
  fi
}

##
# 서비스 및 컨테이너 상태, 최근 실패 저널 로그를 확인합니다.
#
# @param $1 {string} 대상 컨테이너 서비스명 (선택 사항)
#
# @return (상태 출력)
##
service_status() {
  local target_svc="${1:-}"

  echo "================================================================================"
  echo "📊 [STATUS] Docker Compose 컨테이너 상태: $SERVICE_FULL_NAME ${target_svc:+($target_svc)}"
  echo "================================================================================"
  if [ -n "$target_svc" ]; then
    run_compose ps "$target_svc"
  else
    run_compose ps
  fi

  echo ""
  echo "================================================================================"
  echo "⚙️  [STATUS] Systemd 서비스 등록 상태 ($SYSTEMD_SERVICE_NAME)"
  echo "================================================================================"
  if [ -f "$SYSTEMD_TARGET_PATH" ]; then
    systemctl status "$SYSTEMD_SERVICE_NAME" --no-pager || true
    echo ""
    echo "📄 [JOURNAL] 최근 Systemd 서비스 실행 로그 (최신 15줄):"
    journalctl -xeu "$SYSTEMD_SERVICE_NAME" --no-pager -n 15 || true
  else
    echo "ℹ️  Systemd 서비스 파일이 아직 등록(enable)되지 않았습니다."
  fi
}

##
# 명령을 호출한 실제 사용자(SUDO_USER 또는 현재 사용자)의 환경 정보를 안전하게 도출합니다.
#
# @param 없음
#
# @return {string} "사용자명:홈디렉터리:주그룹명" 포맷 문자열 출력
##
resolve_target_user_env() {
  local real_user="${SUDO_USER:-$(id -un)}"
  local real_home=""
  local real_group=""

  real_home="$(getent passwd "$real_user" 2>/dev/null | cut -d: -f6 || true)"
  if [ -z "$real_home" ]; then
    real_home="$HOME"
  fi

  real_group="$(id -gn "$real_user" 2>/dev/null || true)"
  if [ -z "$real_group" ]; then
    real_group="$real_user"
  fi

  echo "${real_user}:${real_home}:${real_group}"
}

##
# Systemd 서비스를 시스템에 등록하고, $HOME/bin 심볼릭 링크 생성 및 시스템 Bash Completion 등록을 수행합니다.
#
# @param 없음
#
# @return (서비스 및 환경 등록 결과 출력)
##
service_enable() {
  echo "⚙️  [ENABLE] $SERVICE_FULL_NAME 시스템 서비스 등록을 시작합니다..."

  if [ ! -f "$SERVICE_SOURCE_PATH" ]; then
    help "원본 서비스 파일이 존재하지 않습니다 -> $SERVICE_SOURCE_PATH" "$LINENO"
    exit 1
  fi

  local sudo_cmd=()
  if (( EUID != 0 )); then
    sudo_cmd=(sudo)
  fi

  # 1. Systemd 서비스 등록 및 SELinux 적용
  "${sudo_cmd[@]}" cp -f "$SERVICE_SOURCE_PATH" "$SYSTEMD_TARGET_PATH"
  "${sudo_cmd[@]}" chown root:root "$SYSTEMD_TARGET_PATH"
  "${sudo_cmd[@]}" chmod 644 "$SYSTEMD_TARGET_PATH"

  if command -v restorecon >/dev/null 2>&1; then
    "${sudo_cmd[@]}" restorecon -vF "$SYSTEMD_TARGET_PATH" >/dev/null 2>&1 || true
  fi
  if command -v chcon >/dev/null 2>&1; then
    "${sudo_cmd[@]}" chcon -t systemd_unit_file_t "$SYSTEMD_TARGET_PATH" >/dev/null 2>&1 || true
  fi

  "${sudo_cmd[@]}" systemctl daemon-reload
  "${sudo_cmd[@]}" systemctl enable "$SYSTEMD_SERVICE_NAME"
  echo "✅ [1/3] Systemd 서비스($SYSTEMD_SERVICE_NAME)가 등록 및 활성화되었습니다."

  # 2. 사용자 실행 경로 ($HOME/bin) 심볼릭 링크 생성
  local user_env=""
  user_env="$(resolve_target_user_env)"
  local target_user target_home target_group
  IFS=: read -r target_user target_home target_group <<< "$user_env"

  local user_bin_dir="${target_home}/bin"
  local target_symlink="${user_bin_dir}/${CTL_SCRIPT_NAME}"

  if [ ! -d "$user_bin_dir" ]; then
    mkdir -p "$user_bin_dir"
    if (( EUID == 0 )) && [ "$target_user" != "root" ]; then
      chown "${target_user}:${target_group}" "$user_bin_dir"
    fi
  fi

  ln -sfn "$CTL_SCRIPT_PATH" "$target_symlink"
  if (( EUID == 0 )) && [ "$target_user" != "root" ]; then
    chown -h "${target_user}:${target_group}" "$target_symlink" 2>/dev/null || true
  fi
  echo "✅ [2/3] 사용자 명령어 경로에 심볼릭 링크가 생성되었습니다 -> $target_symlink"

  # 3. 제어 스크립트 Bash Completion 시스템 등록 (현대 표준: /usr/share/bash-completion/completions/)
  if [ -f "$COMPLETION_SOURCE_PATH" ]; then
    local modern_comp_dir="/usr/share/bash-completion/completions"
    local legacy_comp_dir="/etc/bash_completion.d"
    local installed_comp_path=""

    if [ -d "$modern_comp_dir" ]; then
      installed_comp_path="${modern_comp_dir}/${CTL_SCRIPT_NAME}"
      "${sudo_cmd[@]}" cp -f "$COMPLETION_SOURCE_PATH" "$installed_comp_path"
    elif [ -d "$legacy_comp_dir" ]; then
      installed_comp_path="${legacy_comp_dir}/${CTL_SCRIPT_NAME}.completion"
      "${sudo_cmd[@]}" cp -f "$COMPLETION_SOURCE_PATH" "$installed_comp_path"
    fi

    if [ -n "$installed_comp_path" ]; then
      "${sudo_cmd[@]}" chown root:root "$installed_comp_path"
      "${sudo_cmd[@]}" chmod 644 "$installed_comp_path"
      if command -v restorecon >/dev/null 2>&1; then
        "${sudo_cmd[@]}" restorecon -vF "$installed_comp_path" >/dev/null 2>&1 || true
      fi
      echo "✅ [3/3] 시스템 Bash Completion 이 등록되었습니다 -> $installed_comp_path"
    fi
  else
    echo "⚠️  [WARN] Bash Completion 소스 파일이 없어 시스템 등록을 건너뜁니다 -> $COMPLETION_SOURCE_PATH"
  fi

  echo ""
  echo "🎉 [SUCCESS] $SERVICE_FULL_NAME 서비스의 모든 시스템 활성화 작업이 완료되었습니다."
  echo "💡 (터미널 재시작 없이 바로 사용 가능: '$CTL_SCRIPT_NAME start' 또는 'sudo systemctl start $SYSTEMD_SERVICE_NAME')"
}

##
# Systemd 서비스를 비활성화하고, $HOME/bin 심볼릭 링크 및 시스템 Bash Completion 등록을 해제합니다.
#
# @param 없음
#
# @return (서비스 및 환경 등록 해제 결과 출력)
##
service_disable() {
  echo "⚙️  [DISABLE] $SERVICE_FULL_NAME 시스템 서비스 등록 해제를 시작합니다..."

  local sudo_cmd=()
  if (( EUID != 0 )); then
    sudo_cmd=(sudo)
  fi

  # 1. Systemd 서비스 비활성화 및 제거
  if [ -f "$SYSTEMD_TARGET_PATH" ]; then
    "${sudo_cmd[@]}" systemctl disable "$SYSTEMD_SERVICE_NAME" || true
    "${sudo_cmd[@]}" rm -f "$SYSTEMD_TARGET_PATH"
    "${sudo_cmd[@]}" systemctl daemon-reload
    echo "✅ [1/3] Systemd 서비스($SYSTEMD_SERVICE_NAME)가 비활성화 및 제거되었습니다."
  else
    echo "ℹ️  [1/3] Systemd 서비스($SYSTEMD_SERVICE_NAME)가 이미 등록되어 있지 않습니다."
  fi

  # 2. 사용자 실행 경로 ($HOME/bin) 심볼릭 링크 삭제
  local user_env=""
  user_env="$(resolve_target_user_env)"
  local target_user target_home target_group
  IFS=: read -r target_user target_home target_group <<< "$user_env"

  local user_bin_dir="${target_home}/bin"
  local target_symlink="${user_bin_dir}/${CTL_SCRIPT_NAME}"

  if [ -L "$target_symlink" ] || [ -f "$target_symlink" ]; then
    rm -f "$target_symlink"
    echo "✅ [2/3] 사용자 명령어 심볼릭 링크가 삭제되었습니다 -> $target_symlink"
  else
    echo "ℹ️  [2/3] 삭제할 심볼릭 링크가 존재하지 않습니다 -> $target_symlink"
  fi

  # 3. 시스템 Bash Completion 파일 등록 해제
  local modern_comp_file="/usr/share/bash-completion/completions/${CTL_SCRIPT_NAME}"
  local legacy_comp_file="/etc/bash_completion.d/${CTL_SCRIPT_NAME}.completion"

  if [ -f "$modern_comp_file" ]; then
    "${sudo_cmd[@]}" rm -f "$modern_comp_file"
    echo "✅ [3/3] 시스템 Bash Completion 이 제거되었습니다 -> $modern_comp_file"
  elif [ -f "$legacy_comp_file" ]; then
    "${sudo_cmd[@]}" rm -f "$legacy_comp_file"
    echo "✅ [3/3] 시스템 Bash Completion 이 제거되었습니다 -> $legacy_comp_file"
  else
    echo "ℹ️  [3/3] 등록 해제할 시스템 Bash Completion 파일이 없습니다."
  fi

  echo ""
  echo "🎉 [SUCCESS] $SERVICE_FULL_NAME 서비스의 모든 시스템 등록 해제 작업이 완료되었습니다."
}

##
# 스크립트 실행 메인 진입점입니다.
#
# @param $1 {string} 실행할 동작
# @param $2 {string} 대상 서비스명 (선택 사항)
#
# @return (없음)
##
main() {
  local action="${1:-}"
  local target_svc="${2:-}"

  if [ -z "$action" ]; then
    help "실행할 동작(start, stop, restart, status, enable, disable)을 지정해야 합니다." "$LINENO"
    exit 1
  fi

  ensure_docker_compose
  validate_target_service "$target_svc"

  case "$action" in
    start)
      service_start "$target_svc"
      ;;
    stop)
      service_stop "$target_svc"
      ;;
    restart)
      service_restart "$target_svc"
      ;;
    status)
      service_status "$target_svc"
      ;;
    enable)
      service_enable
      ;;
    disable)
      service_disable
      ;;
    *)
      help "지원하지 않는 동작입니다 -> '$action' (start, stop, restart, status, enable, disable 중 선택)" "$LINENO"
      exit 1
      ;;
  esac
}

main "$ACTION" "$TARGET_CONTAINER"
exit 0
BODY_EOF

  atomic_install_file "$tmp_ctl" "$ctl_path" "755" "script"
}

##
# 제어 스크립트 전용 Bash Completion 파일(${service_full_name}-ctl.sh.completion)을 생성합니다.
#
# @param $1 {string} 생성 대상 completion 파일 경로
# @param $2 {string} 제어 스크립트 파일명
# @param $3 {string} Compose 디렉터리 경로
# @param $4 {string} Compose 파일명
# @param $5 {string} 생성될 completion 파일명
#
# @return (completion 파일 생성 완료)
##
generate_ctl_completion() {
  local comp_path="$1"
  local ctl_filename="$2"
  local compose_dir="$3"
  local compose_file="$4"
  local comp_filename="$5"

  local tmp_comp=""
  tmp_comp="$(mktemp "${TMPDIR:-/tmp}/${ctl_filename}.comp.XXXXXX")"

  # 갱신된 지식 파일의 @installation 규격을 동적으로 치환하여 헤더 생성
  cat << HEADER_EOF > "$tmp_comp"
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : ${CURRENT_DATE}
# @desc : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
# 1. insert 'source <path>/${comp_filename}" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/${comp_filename}' into /etc/bashrc for all users.
# =======================================
# Global Reserved Variables
# 1. COMP_WORDS: an array, contains all arguments
# 2. COMP_CWORD: a index of a cursor
# 3. COMP_LINE: all command string
# 4. COMPREPLY: an array, contains suggested words. words are sorted and unique.
#
# Arguments of a function
# 1. $1: command
# 2. $2: current
# 3. $3: previous
#
# e.g.: mycmd arg1 arg2 arg3 arg4[tab]
# - $1: mycmd
# - $2: arg4
# - $3: arg3
# =======================================

HEADER_EOF

  cat << VARS_EOF >> "$tmp_comp"
##
# ${ctl_filename} 스크립트의 자동완성(Auto-completion)을 지원하는 함수입니다.
# Auto-completion function for ${ctl_filename} script.
##
_ctl_script_completion() {
  local cur prev cmd_actions compose_dir compose_file services
  COMPREPLY=()
  cur="\${COMP_WORDS[COMP_CWORD]}"
  prev="\${COMP_WORDS[COMP_CWORD-1]}"

  compose_dir="${compose_dir}"
  compose_file="${compose_file}"

  # 지원하는 1단계 명령어 목록 / Supported 1st-level actions
  cmd_actions="start stop restart status enable disable --help"

  # 1번째 인자 위치: 명령어 목록 단일 추천
  # 1st parameter position: suggest command actions
  if [[ \$COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( \$(compgen -W "\${cmd_actions}" -- "\${cur}") )
    return 0
  fi

  # 2번째 인자 위치: start, stop, restart, status 일 때 Compose 서비스 목록 추천
  # 2nd parameter position: suggest compose services when prev action is start/stop/restart/status
  if [[ \$COMP_CWORD -eq 2 ]]; then
    case "\${prev}" in
      start|stop|restart|status)
        services=""
        if [ -f "\${compose_dir}/\${compose_file}" ]; then
          services=\$(awk '/^services:/{flag=1; next} /^[^ ]/{flag=0} flag && /^  [a-zA-Z0-9_-]+:/{gsub(/:/, "", \$1); print \$1}' "\${compose_dir}/\${compose_file}" 2>/dev/null || true)
        fi
        if [ -n "\${services}" ]; then
          COMPREPLY=( \$(compgen -W "\${services}" -- "\${cur}") )
        fi
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  fi
}

complete -F _ctl_script_completion ${ctl_filename}
VARS_EOF

  atomic_install_file "$tmp_comp" "$comp_path" "644" "completion"
}

##
# Systemd 유닛 파일(${service_full_name}.service)을 생성합니다.
#
# @param $1 {string} 생성 대상 서비스 파일 경로
# @param $2 {string} ctl 스크립트 절대 경로
# @param $3 {string} Compose 디렉터리 절대 경로
# @param $4 {string} 서비스 풀네임
#
# @return (서비스 파일 생성 완료)
##
generate_service_unit() {
  local service_path="$1"
  local ctl_script="$2"
  local compose_dir="$3"
  local full_name="$4"

  local tmp_service=""
  tmp_service="$(mktemp "${TMPDIR:-/tmp}/${full_name}-service.XXXXXX")"

  cat << EOF > "$tmp_service"
[Unit]
Description=${full_name} Docker Compose Service
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${compose_dir}
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
TimeoutStartSec=0
TimeoutStopSec=120
ExecStart=${ctl_script} start
ExecStop=${ctl_script} stop
ExecReload=${ctl_script} restart
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF

  atomic_install_file "$tmp_service" "$service_path" "644" "service"
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 스크립트 실행 인자
#
# @return (없음)
##
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --docker-compose-dir)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--docker-compose-dir 옵션에는 디렉터리 경로를 지정해야 합니다." "$LINENO"
          exit 1
        fi
        DOCKER_COMPOSE_DIR="$2"
        shift 2
        ;;
      --service)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--service 옵션에는 서비스 이름을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        SERVICE_NAME="$2"
        shift 2
        ;;
      --version)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--version 옵션에는 버전을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        SERVICE_VERSION="$2"
        shift 2
        ;;
      --output-dir)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--output-dir 옵션에는 출력 디렉터리 경로를 지정해야 합니다." "$LINENO"
          exit 1
        fi
        OUTPUT_DIR="$2"
        shift 2
        ;;
      --help)
        help "" ""
        exit 0
        ;;
      -*)
        help "지원하지 않는 옵션입니다 (단축 옵션은 지원하지 않습니다) -> $1" "$LINENO"
        exit 1
        ;;
      *)
        help "잘못된 파라미터 형식입니다 -> $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  # 필수 파라미터 및 경로 유효성 검증
  validate_compose_dir
  validate_service_identifiers
  resolve_output_dir

  local ctl_script_name="${SERVICE_FULL_NAME}-ctl.sh"
  local ctl_comp_name="${SERVICE_FULL_NAME}-ctl.sh.completion"
  local service_file_name="${SERVICE_FULL_NAME}.service"

  local target_ctl_path="$ABS_OUTPUT_DIR/$ctl_script_name"
  local target_comp_path="$ABS_OUTPUT_DIR/$ctl_comp_name"
  local target_service_path="$ABS_OUTPUT_DIR/$service_file_name"

  # 중복 서비스 사전 검증
  verify_service_collision "$service_file_name"

  echo "================================================================================"
  echo "🚀 [START] Docker Compose 서비스 등록 및 제어 스크립트 생성을 시작합니다..."
  echo "  - Compose 디렉터리 : $ABS_COMPOSE_DIR"
  echo "  - 서비스 이름      : $SERVICE_NAME"
  echo "  - 서비스 버전      : ${SERVICE_VERSION:-[버전 미지정]}"
  echo "  - 최종 식별자      : $SERVICE_FULL_NAME"
  echo "  - 결과물 출력 경로 : $ABS_OUTPUT_DIR"
  echo "================================================================================"

  echo "⚙️  [1/3] 제어 스크립트 생성 중 -> $target_ctl_path"
  generate_ctl_script "$target_ctl_path" "$ABS_COMPOSE_DIR" "$COMPOSE_FILE_NAME" "$SERVICE_FULL_NAME" "$target_service_path" "$target_comp_path" "$ctl_script_name"

  echo "⚙️  [2/3] Systemd 유닛 파일 생성 중 -> $target_service_path"
  generate_service_unit "$target_service_path" "$target_ctl_path" "$ABS_COMPOSE_DIR" "$SERVICE_FULL_NAME"

  echo "⚙️  [3/3] 제어 스크립트 Bash Completion 생성 중 -> $target_comp_path"
  generate_ctl_completion "$target_comp_path" "$ctl_script_name" "$ABS_COMPOSE_DIR" "$COMPOSE_FILE_NAME" "$ctl_comp_name"

  echo ""
  echo "================================================================================"
  echo "🎉 [SUCCESS] $SERVICE_FULL_NAME 서비스 파일 생성이 완료되었습니다!"
  echo ""
  echo "📦 [생성된 파일 목록]"
  echo "  1) 제어 스크립트     : $target_ctl_path (소유자: root:root, 모드: 755, SELinux: bin_t)"
  echo "  2) 서비스 유닛       : $target_service_path (소유자: root:root, 모드: 644, SELinux: systemd_unit_file_t)"
  echo "  3) 자동완성 스크립트 : $target_comp_path"
  echo ""
  echo "💡 [원클릭 서비스 등록 및 환경 설정 안내]"
  echo "  - O/S 서비스 등록, 심볼릭 링크(\$HOME/bin) 생성, 시스템 Bash Completion 등록을 한 번에 실행하려면:"
  echo "    $ sudo $target_ctl_path enable"
  echo ""
  echo "  - O/S 서비스 등록 해제, 심볼릭 링크 삭제, 시스템 Bash Completion 등록 해제:"
  echo "    $ sudo $target_ctl_path disable"
  echo "================================================================================"
}

main "$@"
exit 0
