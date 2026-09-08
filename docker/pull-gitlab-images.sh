#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-25
# @desc : support Ubuntu 18.04 or higher, RHEL 7 or higher, Oracle Linux 7 or higher, RockyOS 8 or higher, CentOS 7 or higher
# @installation : 
# 1. insert 'source <path>/pull-gitlab-images.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/pull-gitlab-images.sh' into /etc/bashrc for all users.
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
  echo "사용법 (Usage): $FILENAME [옵션]"
  echo "옵션 (Options):"
  echo "  --version <버전>[,<버전>...] GitLab 버전 직접 지정 (쉼표로 구분)"
  echo "  --file <파일 경로>           GitLab 버전 목록이 작성된 텍스트 파일 경로 지정"
  echo "  --output <경로>              다운로드 후 tar 아카이브로 저장할 디렉토리 경로 (생략 시 다운로드만 수행)"
  echo "  --help                       도움말 출력"
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

##
# 스크립트 내부에서 사용되는 sudo 권한이 유효한지 사전에 검증합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
check_sudo_privilege() {
  if ! sudo -n true 2>/dev/null; then
    sudo -v || {
      help "Docker 명령 실행 및 제어를 위해 sudo 권한이 필요합니다." "$LINENO"
      exit 1
    }
  fi
}

##
# 시스템에 Docker가 설치되어 있는지 확인하고, 미설치 시 사용자 동의를 얻어 설치를 지원합니다.
#
# @param 없음
#
# @return (설치 거부 시 정상 종료, 설치 실패 시 exit 1)
##
ensure_docker_installed() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi

  echo "⚠️  [WARN] 시스템에 Docker가 설치되어 있지 않습니다."

  # 표준 입력(TTY)이 연결되어 있지 않은 비대화형 환경 방어
  if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
    echo "❌ [ERROR] 비대화형 환경에서는 Docker 자동 설치 프롬프트를 실행할 수 없습니다. Docker를 먼저 설치하십시오."
    exit 1
  fi

  local install_answer=""
  if [ -e /dev/tty ]; then
    read -r -p "👉 Docker를 지금 시스템에 설치하시겠습니까? (y/N): " install_answer < /dev/tty
  else
    read -r -p "👉 Docker를 지금 시스템에 설치하시겠습니까? (y/N): " install_answer
  fi

  case "$install_answer" in
    [yY]|[yY][eE][sS])
      echo "⏳ [INFO] Docker 설치를 시작합니다. 잠시만 기다려주세요..."
      check_sudo_privilege

      if command -v apt >/dev/null 2>&1; then
        echo "📦 [APT] 패키지 목록을 갱신하고 Docker를 설치합니다..."
        sudo apt update -y || true
        sudo apt install -y docker.io || {
          help "APT 패키지 관리자를 통한 Docker 설치에 실패했습니다." "$LINENO"
          exit 1
        }
      elif command -v dnf >/dev/null 2>&1; then
        echo "📦 [DNF] Docker 패키지를 설치합니다..."
        sudo dnf install -y docker || sudo dnf install -y docker-ce || {
          help "DNF 패키지 관리자를 통한 Docker 설치에 실패했습니다." "$LINENO"
          exit 1
        }
      elif command -v yum >/dev/null 2>&1; then
        echo "📦 [YUM] Docker 패키지를 설치합니다..."
        sudo yum install -y docker || sudo yum install -y docker-ce || {
          help "YUM 패키지 관리자를 통한 Docker 설치에 실패했습니다." "$LINENO"
          exit 1
        }
      else
        help "지원하는 패키지 관리자(apt, dnf, yum)를 찾을 수 없어 자동 설치를 진행할 수 없습니다." "$LINENO"
        exit 1
      fi

      # 서비스 시작 및 활성화
      echo "🚀 [INFO] Docker 서비스를 시작하고 활성화합니다..."
      sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
      sudo systemctl enable docker 2>/dev/null || true

      if ! command -v docker >/dev/null 2>&1; then
        help "Docker 설치 후 바이너리를 확인할 수 없습니다." "$LINENO"
        exit 1
      fi

      echo "✅ [SUCCESS] Docker 설치 및 서비스 기동이 완료되었습니다."
      echo ""
      ;;
    *)
      echo "🛑 [INFO] Docker 설치를 취소했습니다. 작업을 진행하지 않고 종료합니다."
      exit 0
      ;;
  esac
}

##
# 입력받은 파일 경로의 존재 여부 및 접근 권한을 검증합니다.
#
# @param $1 {string} 검증할 입력 파일 경로
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
validate_input_file() {
  local target_file="$1"
  if [ ! -f "$target_file" ]; then
    help "지정한 파일이 존재하지 않거나 잘못된 경로입니다 -> $target_file" "$LINENO"
    exit 1
  fi
}

##
# 출력 디렉토리의 존재를 확인하고, 경로가 없으면 sudo 권한으로 생성합니다.
#
# @param $1 {string} 검증 및 생성할 디렉토리 경로
#
# @return (생성 실패 시 에러 출력 후 exit 1)
##
ensure_output_directory() {
  local target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    echo "📁 [INFO] 결과물을 저장할 디렉토리를 생성합니다 -> $target_dir"
    sudo mkdir -p "$target_dir" || {
      help "디렉토리 생성 권한이 없거나 실패했습니다 -> $target_dir" "$LINENO"
      exit 1
    }
  fi
}

##
# 로컬 Docker 환경에 대상 이미지가 존재하는지 식별합니다.
#
# @param $1 {string} 확인할 Docker 이미지 이름 및 태그
#
# @return (존재하면 0, 존재하지 않으면 1 반환)
##
check_local_image_exists() {
  local image_name="$1"
  local image_id
  image_id=$(sudo docker images -q "$image_name" 2>/dev/null)

  if [ -n "$image_id" ]; then
    return 0
  else
    return 1
  fi
}

##
# 순수 숫자 버전 입력 시 사용자에게 대화형으로 EE 또는 CE 에디션을 질의합니다.
#
# @param $1 {string} 순수 숫자 버전 문자열 (예: 19.3.0)
#
# @return {string} 결정된 에디션 문자열 ('ee' 또는 'ce')
##
prompt_edition_selection() {
  local num_version="$1"
  local choice=""

  while true; do
    echo "❓ [SELECT] 버전 '$num_version' 의 GitLab 에디션을 선택해 주십시오."
    if [ -e /dev/tty ]; then
      read -r -p "👉 에디션 선택 (1: EE [Enterprise] / 2: CE [Community]) [기본값: EE]: " choice < /dev/tty
    else
      read -r -p "👉 에디션 선택 (1: EE [Enterprise] / 2: CE [Community]) [기본값: EE]: " choice
    fi

    case "$choice" in
      ""|1|[eE][eE]|[gG][iI][tT][lL][aA][bB]-[eE][eE])
        echo "ee"
        return 0
        ;;
      2|[cC][eE]|[gG][iI][tT][lL][aA][bB]-[cC][eE])
        echo "ce"
        return 0
        ;;
      *)
        echo "⚠️  [WARN] 잘못된 입력입니다. '1'(EE) 또는 '2'(CE)를 입력하십시오." >&2
        ;;
    esac
  done
}

##
# 지정된 버전의 GitLab 이미지를 확인 및 다운로드하고 tar 파일로 저장합니다.
#
# @param $1 {string} 처리할 이미지 원본 버전 문자열
# @param $2 {string} 저장할 출력 디렉토리 경로 (빈 값일 경우 파일 저장 생략)
#
# @return (성공 시 0, 실패 시 1을 반환)
##
pull_and_register_image() {
  local raw_version="$1"
  local output_dir="$2"

  # 데이터 정제 (공백 및 윈도우 개행문자 제거)
  local clean_version
  clean_version=$(echo "$raw_version" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # 주석 및 빈 줄 스킵
  if [[ -z "$clean_version" || "$clean_version" == \#* ]]; then
    return 0
  fi

  echo ""
  echo "==================== [ 버전: $clean_version ] ===================="

  local version="$clean_version"
  local edition="ee"

  # 버전 포맷 유효성 검사, 에디션 질의 및 스마트 교정
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    edition=$(prompt_edition_selection "$version")
    version="${version}-${edition}.0"
    echo "ℹ️  [INFO] 선택된 에디션을 반영하여 태그를 구성합니다 -> $version"
  elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(ee|ce)$ ]]; then
    if [[ "$version" =~ -(ee|ce)$ ]]; then
      edition="${BASH_REMATCH[1]}"
    fi
    version="${version}.0"
    echo "⚠️  [WARN] 빌드 번호가 누락되어 태그를 교정합니다 -> $version"
  elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(ee|ce)\.0$ ]]; then
    if [[ "$version" =~ -(ee|ce)\.0$ ]]; then
      edition="${BASH_REMATCH[1]}"
    fi
    echo "✅ [INFO] 유효한 버전 포맷입니다 -> $version"
  else
    echo "❌ [ERROR] 지원하지 않는 버전 포맷입니다 (스킵 처리) -> $version"
    echo "==============================================================="
    return 1
  fi

  local image_name="gitlab/gitlab-${edition}:$version"
  echo "🚀 [START] 대상 이미지 제어 -> $image_name"

  # 1. 로컬 존재 여부 분기
  if check_local_image_exists "$image_name"; then
    echo "⏭️   [SKIP] 로컬 환경에 이미 존재하는 이미지입니다 -> $image_name"
  else
    echo "⏳ [PULL] 이미지를 다운로드 중입니다. 잠시만 기다려주세요..."
    if ! sudo docker pull "$image_name"; then
      echo "❌ [ERROR] 이미지 다운로드에 실패했습니다 -> $image_name"
      echo "==============================================================="
      return 1
    fi
  fi

  # 2. 아카이빙(Save) 분기
  if [ -n "$output_dir" ]; then
    local tar_file="$output_dir/gitlab-${edition}-${version}.tar"

    if [ -f "$tar_file" ]; then
      echo "⏭️   [SKIP] 대상 경로에 아카이브 파일이 이미 존재합니다 -> $tar_file"
    else
      echo "⏳ [SAVE] 이미지를 파일로 아카이빙 중입니다 -> $tar_file"
      if ! sudo docker save -o "$tar_file" "$image_name"; then
        echo "❌ [ERROR] 이미지 파일 저장에 실패했습니다 -> $tar_file"
        echo "==============================================================="
        return 1
      fi
      sudo chown "$(id -u):$(id -g)" "$tar_file"
    fi
  fi

  echo "🎉 [SUCCESS] 이미지 처리를 성공적으로 완료했습니다 -> $image_name"
  echo "==============================================================="
  return 0
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 스크립트 실행 인자
#
# @return (없음)
##
main() {
  local version_arg=""
  local input_file=""
  local output_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--version 파라미터는 최소 하나 이상의 버전을 입력해야 합니다." "$LINENO"
          exit 1
        fi
        version_arg="$2"
        shift 2
        ;;
      --file)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--file 파라미터는 대상 파일 경로를 입력해야 합니다." "$LINENO"
          exit 1
        fi
        input_file="$2"
        shift 2
        ;;
      --output)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--output 파라미터는 디렉토리 경로를 입력해야 합니다." "$LINENO"
          exit 1
        fi
        output_dir="$2"
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

  local target_versions=()

  # 1. --version 인자 처리 (콤마 구분 분리 및 Trim)
  if [ -n "$version_arg" ]; then
    local raw_v_list=()
    local v=""
    local trimmed_v=""
    IFS=',' read -ra raw_v_list <<< "$version_arg"
    for v in "${raw_v_list[@]}"; do
      trimmed_v=$(echo "$v" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      if [ -n "$trimmed_v" ]; then
        target_versions+=("$trimmed_v")
      fi
    done
  fi

  # 2. --file 인자 처리 (파일에서 라인별 수집)
  if [ -n "$input_file" ]; then
    validate_input_file "$input_file"
    local line=""
    local trimmed_line=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      trimmed_line=$(echo "$line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      if [[ -n "$trimmed_line" && "$trimmed_line" != \#* ]]; then
        target_versions+=("$trimmed_line")
      fi
    done < "$input_file"
  fi

  # 3. 버전 입력 여부 통합 검증
  if [ ${#target_versions[@]} -eq 0 ]; then
    help "--version 또는 --file 옵션을 통해 최소 하나 이상의 GitLab 버전을 지정해야 합니다." "$LINENO"
    exit 1
  fi

  # Docker 설치 여부 확인 및 대화형 설치 지원
  ensure_docker_installed

  # sudo 권한 검증
  check_sudo_privilege

  if [ -n "$output_dir" ]; then
    ensure_output_directory "$output_dir"
  fi

  echo "📦 [INFO] 총 ${#target_versions[@]}개 버전에 대한 이미지 처리를 시작합니다."

  local failed_images=()
  local ver_item=""

  for ver_item in "${target_versions[@]}"; do
    if ! pull_and_register_image "$ver_item" "$output_dir"; then
      failed_images+=("$ver_item")
    fi
  done

  echo ""
  if [ ${#failed_images[@]} -eq 0 ]; then
    echo "🏁 [FINISH] 모든 프로세스가 오류 없이 정상적으로 종료되었습니다."
  else
    echo "⚠️  [FINISH-WITH-WARNINGS] 프로세스가 종료되었으나, 다음 버전의 처리가 실패했습니다:"
    local fail_ver=""
    for fail_ver in "${failed_images[@]}"; do
      echo "   - $fail_ver"
    done
    exit 1
  fi
}

main "$@"
exit 0
