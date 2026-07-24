#!/usr/bin/env bash

# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-07-24
# @desc : support RHEL 7 or higher, Oracle Linux 7 or higher, Ubuntu 18.04 or higher, RockyOS 8 or higher, CentOS 7 or higher
# @installation : 
# 1. insert 'source <path>/<파일명>' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/gitlab/gitlab-clone.sh"
TARGET_BIN_DIR="$HOME/bin"
TARGET_SCRIPT_PATH="$TARGET_BIN_DIR/gitlab-clone.sh"

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
      printf "$formatr" "["$idx"]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "${1:-}"
    echo "================================================================================"
  fi 
  echo 
  echo "사용법: ./$FILENAME -g <그룹 경로> [-n <대체 이름>] [-d <저장디렉토리>]"
  echo ""
  echo "옵션:"
  echo "  -g, --group     GitLab 대상 그룹 정보 (예: my-security) (필수)"
  echo "  -n, --name      클론 디렉토리의 상위 그룹 폴더명을 대체할 이름 (선택)"
  echo "  -d, --dir       프로젝트를 Clone 할 대상 최상위 디렉토리 (선택, 기본값: 현재 경로)"
  echo "  -h, --help      도움말 출력"
}

##
# 지정된 URL에서 스크립트를 다운로드하여 임시 파일로 저장합니다.
#
# @param $1 {String} 다운로드할 대상 URL
# @param $2 {String} 다운로드된 파일이 임시로 저장될 경로
#
# @return 실패할 경우 스크립트 종료 및 원인 출력
##
download_remote_script() {
  local target_url="$1"
  local temp_path="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -sSL "$target_url" -o "$temp_path" || { help "curl을 통한 다운로드 실패" "$LINENO"; exit 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$temp_path" "$target_url" || { help "wget을 통한 다운로드 실패" "$LINENO"; exit 1; }
  else
    help "curl 또는 wget 명령어가 시스템에 존재하지 않습니다." "$LINENO"
    exit 1
  fi
}

##
# 디렉토리가 존재하는지 검증하고, 중간 경로가 없는 경우 자동 생성합니다.
#
# @param $1 {String} 검증 및 생성할 디렉토리의 절대/상대 경로
#
# @return 디렉토리 생성 실패 시 스크립트 종료
##
ensure_directory_exists() {
  local dir_path="$1"
  if [ ! -d "$dir_path" ]; then
    # 중간 경로가 없는 경우 자동 생성
    mkdir -p "$dir_path" || { help "디렉토리 생성 권한 부족 또는 실패: $dir_path" "$LINENO"; exit 1; }
  fi
}

##
# gitlab-clone.sh 스크립트의 존재 여부 및 무결성을 검증합니다.
# 안내 메시지는 stderr(>&2)로 출력하고, 결과 경로는 stdout으로 반환합니다.
#
# @param 없음
#
# @return {String} 최종 사용될 gitlab-clone.sh 파일의 절대 경로 출력
##
ensure_gitlab_clone_integrity() {
  echo "🔍 [1/3] 내부 스크립트(gitlab-clone.sh) 상태 검증을 시작합니다..." >&2
  ensure_directory_exists "$TARGET_BIN_DIR"

  case ":$PATH:" in
    *":$TARGET_BIN_DIR:"*) ;;
    *) export PATH="$TARGET_BIN_DIR:$PATH" ;;
  esac

  local temp_remote_file
  temp_remote_file=$(mktemp)
  
  echo "📥 [2/3] 최신 버전의 스크립트를 원격지에서 다운로드 중입니다..." >&2
  download_remote_script "$REMOTE_SCRIPT_URL" "$temp_remote_file"

  if command -v gitlab-clone.sh >/dev/null 2>&1; then
    local installed_script
    installed_script=$(command -v gitlab-clone.sh)

    echo "⚖️  [3/3] 기존 스크립트($installed_script)와 무결성 비교를 진행합니다..." >&2
    if cmp -s "$installed_script" "$temp_remote_file"; then
      echo "✅ 무결성 확인 완료: 기존 'gitlab-clone.sh' 파일이 최신 상태와 일치하여 그대로 사용합니다." >&2
      rm -f "$temp_remote_file"
      echo "$installed_script"
      return 0
    else
      echo "🔄 무결성 불일치: 다운로드 받은 최신 'gitlab-clone.sh' 파일로 교체합니다." >&2
    fi
  else
    echo "⚠️  [3/3] 로컬에 스크립트가 존재하지 않아, 새로 다운로드 받은 'gitlab-clone.sh' 파일을 설치합니다." >&2
  fi

  mv "$temp_remote_file" "$TARGET_SCRIPT_PATH"
  chmod +x "$TARGET_SCRIPT_PATH"
  echo "🚀 적용 완료: $TARGET_SCRIPT_PATH" >&2
  
  echo "$TARGET_SCRIPT_PATH"
}

##
# 입력받은 파라미터를 파싱하고 필수 제약 조건을 검증합니다.
#
# @param $@ {Array} 스크립트 실행 시 전달된 전체 파라미터 배열
#
# @return 실패 시 도움말(help) 호출 후 종료
##
parse_arguments() {
  TARGET_GROUP=""
  TARGET_NEW_DIR=""
  TARGET_DIR=""

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -g|--group)
        if [ -z "${2:-}" ]; then help "-g/--group 대상 그룹 정보가 누락되었습니다." "$LINENO"; exit 1; fi
        TARGET_GROUP="$2"; shift 2 ;;
      -n|--name)
        if [ -z "${2:-}" ]; then help "-n/--name 대체 이름 정보가 누락되었습니다." "$LINENO"; exit 1; fi
        TARGET_NEW_DIR="$2"; shift 2 ;;
      -d|--dir)
        if [ -z "${2:-}" ]; then help "-d/--dir 저장 디렉토리 경로가 누락되었습니다." "$LINENO"; exit 1; fi
        TARGET_DIR="$2"; shift 2 ;;
      -h|--help)
        help ""; exit 0 ;;
      *)
        help "지원하지 않는 옵션입니다: $1" "$LINENO"; exit 1 ;;
    esac
  done

  if [ -z "$TARGET_GROUP" ]; then
    help "필수 파라미터가 누락되었습니다: -g/--group" "$LINENO"
    exit 1
  fi

  if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)"
  else
    # 입력 데이터로 사용되는 디렉토리 검증 (없으면 생성)
    ensure_directory_exists "$TARGET_DIR"
  fi
}

##
# 메인 함수: 스크립트의 전체 라이프사이클을 관리합니다.
#
# @param $@ {Array} 사용자 입력 파라미터 전체 배열
#
# @return 정상 종료 시 0 (exit 0)
##
main() {
  parse_arguments "$@"

  local exec_gitlab_clone
  # 반환받는 경로 데이터가 오염되지 않도록 서브 쉘에서 캡처 실행
  exec_gitlab_clone=$(ensure_gitlab_clone_integrity)

  # Gitlab URL (예: https://gitlab.your-company.com)
  local gitlab_url=""
# Gitlab Personal Access Token
  local gitlab_pat=""

  echo "================================================================================" >&2
  echo "▶️  GitLab Clone 프로젝트 작업을 시작합니다." >&2
  echo "================================================================================" >&2

  # 특수문자 및 띄어쓰기 방어를 위해 전체 파라미터를 쌍따옴표("$@")로 전달
  "$exec_gitlab_clone" -u "${gitlab_url}" -t "${gitlab_pat}" "$@"
}

main "$@"

exit 0
