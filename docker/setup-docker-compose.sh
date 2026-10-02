#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : setup 'docker-compose' working directory.
# @license : Apache License 2.0
# @since : 2026-10-02
# @desc : support RHEL 7+, Oracle Linux 7+, Ubuntu 18.04+, RockyOS 8+, CentOS 7+
# @installation : 
# 1. insert 'source <path>/setup-docker-compose.sh.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/setup-docker-compose.sh' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
# =======================================

set -Eeuo pipefail

# 전역 상수 및 실행 파일명 정의
readonly FILENAME="$(basename "$0")"

# 전역 런타임 변수
TARGET_BASE_DIR=""
SERVICE_NAME=""
DRY_RUN=false
NEED_SUDO=false

##
# 오류 발생 시 또는 도움말 요청 시 호출되는 도움말 함수
#
# @param $1 {string} 오류 원인 메시지 (선택적)
# @param $2 {integer} 오류 발생 소스코드 라인 번호 (선택적)
#
# @return 없음 (도움말 화면 출력)
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
    printf "$formatl" "line" "${2:-UNKNOWN}"
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
  echo "사용법:"
  echo "  $FILENAME --directory <디렉토리경로> --service <서비스명> [--dry-run] [--help]"
  echo
  echo "옵션:"
  echo "  --directory <경로>     (필수) Docker Compose 환경이 설치될 대상 부모 디렉토리 경로"
  echo "  --service   <이름>     (필수) 생성할 서비스 식별자 이름"
  echo "  --dry-run              실제 파일 생성을 수행하지 않고 계획된 변경 사항만 출력"
  echo "  --help                 도움말 화면 출력"
  echo
  echo "주의사항:"
  echo "  단축 옵션(-d, -s, -h 등)은 지원되지 않으므로 전체 옵션 명칭을 사용하십시오."
  echo
  echo "예시:"
  echo "  $FILENAME --directory /opt/services --service user-api"
  echo "  $FILENAME --directory ./deploy --service AuthService --dry-run"
}

##
# 정보 로그 메시지 출력
#
# @param $1 {string} 출력할 메시지 내용
#
# @return stdout
##
log_info(){
  local message="$1"
  echo -e "ℹ️  [INFO] ${message}"
}

##
# 성공 로그 메시지 출력
#
# @param $1 {string} 출력할 성공 메시지 내용
#
# @return stdout
##
log_success(){
  local message="$1"
  echo -e "✅ [SUCCESS] ${message}"
}

##
# 경고 로그 메시지 출력
#
# @param $1 {string} 출력할 경고 메시지 내용
#
# @return stdout
##
log_warn(){
  local message="$1"
  echo -e "⚠️  [WARN] ${message}"
}

##
# 에러 로그 메시지 출력
#
# @param $1 {string} 출력할 에러 메시지 내용
#
# @return stderr
##
log_error(){
  local message="$1"
  echo -e "❌ [ERROR] ${message}" >&2
}

##
# Dry-run 실행 시뮬레이션 로그 출력
#
# @param $1 {string} 출력할 작업 내용
#
# @return stdout
##
log_dryrun(){
  local message="$1"
  echo -e "💡 [DRY-RUN] ${message}"
}

##
# 문자열을 소문자 snake_case 포맷으로 변환
#
# @param $1 {string} 변환 대상 원본 문자열
#
# @return stdout (변환된 snake_case 문자열)
##
convert_to_snake_case(){
  local input="$1"
  local output=""

  output=$(echo "$input" \
    | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' \
    | sed -E 's/[^a-zA-Z0-9]+/_/g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/_+/_/g; s/^_//; s/_$//')

  echo "$output"
}

##
# 주어진 경로에서 실제 존재하는 가장 가까운 상위 디렉토리 탐색
#
# @param $1 {string} 검사 대상 디렉토리 경로
#
# @return stdout (존재하는 가장 가까운 상위 디렉토리 경로)
##
find_nearest_existing_ancestor(){
  local current_path="$1"
  
  while [ ! -d "$current_path" ]; do
    local parent_path
    parent_path="$(dirname "$current_path")"
    if [ "$parent_path" = "$current_path" ]; then
      break
    fi
    current_path="$parent_path"
  done

  echo "$current_path"
}

##
# 대상 경로에 대한 파일시스템 쓰기 권한 점검 및 sudo 필요 여부 확인
#
# @param $1 {string} 생성 대상 최종 디렉토리 경로
#
# @return 0: 권한 확인 완료, 1: 관리자 권한 획득 불가
##
check_permissions_and_sudo(){
  local target_path="$1"
  local check_dir=""

  if [ -d "$target_path" ]; then
    check_dir="$target_path"
  else
    check_dir="$(find_nearest_existing_ancestor "$target_path")"
  fi

  echo "🔍 [CHECK] 경로 쓰기 권한 검증: '${check_dir}'"

  if [ -w "$check_dir" ]; then
    NEED_SUDO=false
    log_info "현재 사용자 권한으로 작업 수행이 가능합니다. (sudo 불필요)"
  else
    NEED_SUDO=true
    log_warn "현재 사용자에게 쓰기 권한이 없습니다. 관리자 권한(sudo)을 사용합니다."
    
    if [ "$DRY_RUN" = false ]; then
      if ! command -v sudo >/dev/null 2>&1; then
        help "sudo 명령어를 찾을 수 없으며, 디렉토리 쓰기 권한이 없습니다." "$LINENO"
        exit 1
      fi

      if ! sudo -v; then
        help "sudo 권한 인증에 실패하였습니다." "$LINENO"
        exit 1
      fi
    fi
  fi
}

##
# 디렉토리 생성 실행 래퍼 (Dry-Run 및 sudo 분기 제어)
#
# @param $1 {string} 생성할 디렉토리 경로
#
# @return 0: 성공
##
create_directory(){
  local dir_path="$1"

  if [ "$DRY_RUN" = true ]; then
    if [ "$NEED_SUDO" = true ]; then
      log_dryrun "디렉토리 생성 명령 시뮬레이션: sudo mkdir -p \"$dir_path\""
    else
      log_dryrun "디렉토리 생성 명령 시뮬레이션: mkdir -p \"$dir_path\""
    fi
  else
    if [ "$NEED_SUDO" = true ]; then
      sudo mkdir -p "$dir_path"
    else
      mkdir -p "$dir_path"
    fi
    log_success "📁 대상 디렉토리가 성공적으로 생성되었습니다: ${dir_path}"
  fi
}

##
# 파일 생성 및 쓰기 래퍼 (Dry-Run 및 sudo 분기 제어)
#
# @param $1 {string} 대상 파일 전체 경로
# @param $2 {string} 파일에 기록할 내용
#
# @return 0: 성공
##
write_file(){
  local file_path="$1"
  local content="$2"

  if [ "$DRY_RUN" = true ]; then
    log_dryrun "파일 생성 명령 시뮬레이션 -> ${file_path}"
    echo "----------------------------------------"
    printf "%s\n" "$content"
    echo "----------------------------------------"
  else
    if [ "$NEED_SUDO" = true ]; then
      printf "%s\n" "$content" | sudo tee "$file_path" >/dev/null
    else
      printf "%s\n" "$content" > "$file_path"
    fi
    log_success "📝 파일 생성 완료: ${file_path}"
  fi
}

##
# .env 파일 생성 로직
#
# @param $1 {string} 출력 대상 파일 전체 경로
# @param $2 {string} 서비스 이름
#
# @return 없음
##
generate_env_file(){
  local target_file="$1"
  local svc_name="$2"
  local env_content=""

  env_content="TZ: Asia/Seoul
NAME: \"${svc_name}\"
IMAGE_NAME: \"${svc_name}-image\"
IMAGE_TAG: \"latest\"
CONTAINER_NAME: \"${svc_name}\"
PORTS: \"8080:8080\""

  write_file "$target_file" "$env_content"
}

##
# docker-compose.yml 파일 생성 로직
#
# @param $1 {string} 출력 대상 파일 전체 경로
# @param $2 {string} 서비스 식별자
#
# @return 없음
##
generate_compose_file(){
  local target_file="$1"
  local svc_name="$2"
  local snake_name
  snake_name="$(convert_to_snake_case "$svc_name")"

  local compose_content=""
  compose_content="name: \"\${NAME}\"

x-logging: &logging
  driver: local
  options:
    max-size: \"10m\"
    max-file: \"5\"

services:
  ${snake_name}:
    image: \"\${IMAGE_NAME:?Required IMAGE_NAME}:\${IMAGE_TAG:?Required IMAGE_TAG}\"
    container_name: \"\${CONTAINER_NAME?Required CONTAINER_NAME}\"
    restart: unless-stopped
    ports:
      - \"\${PORTS?Required PORTS}\"
    logging: *logging"

  write_file "$target_file" "$compose_content"
}

##
# CLI 옵션 파싱 및 유효성 검증
#
# @param $@ CLI 인자 배열
#
# @return 0: 파싱 성공, 기타: 검증 실패 후 종료
##
parse_and_validate_arguments(){
  if [ $# -eq 0 ]; then
    help "명령어 인자가 전달되지 않았습니다." "$LINENO"
    exit 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --directory)
        if [ -z "${2:-}" ] || [[ "${2:-}" == --* ]]; then
          help "--directory 옵션의 경로 값이 지정되지 않았거나 잘못되었습니다." "$LINENO"
          exit 1
        fi
        TARGET_BASE_DIR="$2"
        shift 2
        ;;
      --service)
        if [ -z "${2:-}" ] || [[ "${2:-}" == --* ]]; then
          help "--service 옵션의 서비스명이 지정되지 않았거나 잘못되었습니다." "$LINENO"
          exit 1
        fi
        SERVICE_NAME="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift 1
        ;;
      --help)
        help "" "$LINENO"
        exit 0
        ;;
      -*)
        help "지원되지 않거나 잘못된 옵션입니다 (단축 옵션은 지원되지 않습니다): $1" "$LINENO"
        exit 1
        ;;
      *)
        help "알 수 없는 인자입니다: $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  # 필수 파라미터 누락 여부 검증
  if [ -z "$TARGET_BASE_DIR" ]; then
    help "필수 파라미터 '--directory'가 누락되었습니다." "$LINENO"
    exit 1
  fi

  if [ -z "$SERVICE_NAME" ]; then
    help "필수 파라미터 '--service'가 누락되었습니다." "$LINENO"
    exit 1
  fi

  # 서비스명 유효 문자 검증 (영문 대소문자, 숫자, 하이픈, 언더스코어)
  if ! [[ "$SERVICE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    help "서비스명에는 영문 대소문자, 숫자, 하이픈(-), 언더스코어(_)만 사용할 수 있습니다: '$SERVICE_NAME'" "$LINENO"
    exit 1
  fi
}

##
# 메인 실행 제어 함수
#
# @param $@ CLI 인자 배열
#
# @return 0: 성공
##
main(){
  parse_and_validate_arguments "$@"

  echo "🚀 [START] Docker Compose 작업 환경 생성 프로세스를 시작합니다."

  if [ "$DRY_RUN" = true ]; then
    log_warn "DRY-RUN 모드가 활성화되었습니다. 파일시스템에 실제 변경 사항은 적용되지 않습니다."
  fi

  # 경로 후행 슬래시 제거 및 타겟 전체 경로 조합
  local clean_base_dir="${TARGET_BASE_DIR%/}"
  local full_target_dir="${clean_base_dir}/${SERVICE_NAME}"

  log_info "설치 대상 경로 -> ${full_target_dir}"
  log_info "대상 서비스명   -> ${SERVICE_NAME}"

  # 1. 파일시스템 권한 사전 점검
  check_permissions_and_sudo "$full_target_dir"

  # 2. 기존 파일 덮어쓰기 위험성 검증
  local env_file="${full_target_dir}/.env"
  local compose_file="${full_target_dir}/docker-compose.yml"

  if [ -f "$env_file" ] || [ -f "$compose_file" ]; then
    help "대상 디렉토리에 기존 구성 파일(.env 또는 docker-compose.yml)이 이미 존재합니다: ${full_target_dir}" "$LINENO"
    exit 1
  fi

  # 3. 디렉토리 생성
  create_directory "$full_target_dir"

  # 4. .env 파일 생성
  generate_env_file "$env_file" "$SERVICE_NAME"

  # 5. docker-compose.yml 파일 생성
  generate_compose_file "$compose_file" "$SERVICE_NAME"

  echo
  if [ "$DRY_RUN" = true ]; then
    log_success "🎉 [DRY-RUN COMPLETED] 모든 시뮬레이션 검증이 안전하게 완료되었습니다."
  else
    log_success "🎉 [ALL COMPLETED] Docker Compose 작업 환경 생성이 성공적으로 완료되었습니다!"
    echo "💡 [NEXT STEP] 다음 명령어를 통해 서비스를 구동할 수 있습니다:"
    echo "   cd \"${full_target_dir}\" && docker compose up -d"
  fi

  exit 0
}

main "$@"
