#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : pull gitlab images.
# @license : Apache License 2.0
# @since : 2026-08-20
# @desc : support Ubuntu 18.04 or higher, RHEL 7 or higher, Oracle Linux 7 or higher, RockyOS 8 or higher, CentOS 7 or higher
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
    if [ ${#FUNCNAME[@]} -gt 1 ]; then
      for func in "${FUNCNAME[@]:1}"; do 
        printf "$formatr" "["$idx"]" "$func"
        ((idx++))
      done
    fi
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi 
  echo 
  echo "사용법 (Usage): $FILENAME [옵션]"
  echo "옵션 (Options):"
  echo "  -f, --file <파일 경로>    GitLab 버전 목록이 작성된 텍스트 파일 경로 지정"
  echo "  -o, --output <경로>       다운로드 후 tar 아카이브로 저장할 디렉토리 경로 (생략 시 다운로드만 수행)"
  echo "  -h, --help                도움말 출력"
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
  
  # 데이터 정제 (공백 및 윈도우 줄바꿈 제거)
  local clean_version
  clean_version=$(echo "$raw_version" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  # 주석 및 빈 줄 스킵 (로그 구분선이 출력되기 전에 조기 종료)
  if [[ -z "$clean_version" || "$clean_version" == \#* ]]; then
    return 0
  fi

  echo ""
  echo "==================== [ 버전: $clean_version ] ===================="

  local version="$clean_version"
  
  # 버전 포맷 유효성 검사 및 스마트 교정
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(ee|ce)$ ]]; then
    version="${version}.0"
    echo "⚠️  [WARN] 빌드 번호가 누락되어 태그를 교정합니다 -> $version"
  elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-(ee|ce)\.0$ ]]; then
    echo "✅ [INFO] 유효한 버전 포맷입니다 -> $version"
  else
    echo "❌ [ERROR] 지원하지 않는 버전 포맷입니다 (스킵 처리) -> $version"
    echo "==============================================================="
    return 1
  fi

  local image_name="gitlab/gitlab-ee:$version"
  echo "🚀 [START] 대상 이미지 제어 -> $image_name"

  # 1. 로컬 존재 여부 분기
  if check_local_image_exists "$image_name"; then
    echo "⏭️  [SKIP] 로컬 환경에 이미 존재하는 이미지입니다 -> $image_name"
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
    local tar_file="$output_dir/gitlab-ee-${version}.tar"
    
    if [ -f "$tar_file" ]; then
      echo "⏭️  [SKIP] 대상 경로에 아카이브 파일이 이미 존재합니다 -> $tar_file"
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
  local input_file=""
  local output_dir=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        if [[ -z "${2:-}" || "$2" == -* ]]; then
          help "--file 파라미터는 대상 파일 경로를 입력해야 합니다." "$LINENO"
          exit 1
        fi
        input_file="$2"
        shift 2
        ;;
      -o|--output)
        if [[ -z "${2:-}" || "$2" == -* ]]; then
          help "--output 파라미터는 디렉토리 경로를 입력해야 합니다." "$LINENO"
          exit 1
        fi
        output_dir="$2"
        shift 2
        ;;
      -h|--help)
        help "" ""
        exit 0
        ;;
      *)
        help "알 수 없는 파라미터입니다 -> $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  if [ -z "$input_file" ]; then
    help "--file 파라미터를 통해 버전을 담은 텍스트 파일을 전달해야 합니다." "$LINENO"
    exit 1
  fi

  check_sudo_privilege
  validate_input_file "$input_file"

  if [ -n "$output_dir" ]; then
    ensure_output_directory "$output_dir"
  fi

  echo "📄 [INFO] 지정된 파일($input_file)에서 데이터 읽기를 시작합니다."
  
  local failed_images=()
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! pull_and_register_image "$line" "$output_dir"; then
      failed_images+=("$line")
    fi
  done < "$input_file"

  echo ""
  if [ ${#failed_images[@]} -eq 0 ]; then
    echo "🏁 [FINISH] 모든 프로세스가 오류 없이 정상적으로 종료되었습니다."
  else
    echo "⚠️  [FINISH-WITH-WARNINGS] 프로세스가 종료되었으나, 다음 버전의 처리가 실패했습니다:"
    for fail_ver in "${failed_images[@]}"; do
      echo "   - $fail_ver"
    done
    exit 1
  fi
}

main "$@"
exit 0
