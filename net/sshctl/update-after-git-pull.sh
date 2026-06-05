#!/usr/bin/env bash
set -euo pipefail

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : update-after-git-pull.sh
# @license  : Apache License 2.0
# @since    : 2026-06-05
# @desc     : Update git repository and copy configuration file
# @installation : 
#   1. insert 'source <path>/update-after-git-pull.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/update-after-git-pull.sh' into etc/bashrc for all users.
# =======================================

FILENAME="$(basename "$0")"

# =======================================
# help / usage
# =======================================
help() {
  cat <<EOF
사용법 (Usage):
  $FILENAME [options]

필수 옵션 (Required Options):
  -g, --git-dir <path>   Git 저장소 디렉토리 경로
  -s, --src-dir <path>   원본 파일(configuration.conf)이 위치한 경로
  -t, --tgt-dir <path>   파일을 복사할 타겟 디렉토리 경로

기타 옵션 (Other Options):
  -h, --help             이 도움말을 출력하고 종료합니다.

예시 (Example):
  $FILENAME -g ~/my-repo -s ~/my-repo/configs -t ~/.sshctl
EOF
}

# =======================================
# Common utils
# =======================================
log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "${level}" "$*" >&2
}

die() {
  local msg="$*"
  log ERROR "$msg"
  exit 1
}

# =======================================
# main
# =======================================
main() {
  local git_dir=""
  local src_dir=""
  local tgt_dir=""

  # 인자 파싱 (Argument Parsing)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g|--git-dir)
        git_dir="${2:-}"
        shift 2 || die "--git-dir 옵션에 값이 필요합니다."
        ;;
      -s|--src-dir)
        src_dir="${2:-}"
        shift 2 || die "--src-dir 옵션에 값이 필요합니다."
        ;;
      -t|--tgt-dir)
        tgt_dir="${2:-}"
        shift 2 || die "--tgt-dir 옵션에 값이 필요합니다."
        ;;
      -h|--help)
        help
        exit 0
        ;;
      *)
        die "알 수 없는 옵션입니다: $1\n\n$(help)"
        ;;
    esac
  done

  # 필수 파라미터 검증
  if [[ -z "$git_dir" || -z "$src_dir" || -z "$tgt_dir" ]]; then
    help
    echo ""
    die "필수 파라미터(-g, -s, -t)가 누락되었습니다."
  fi

  # ------------------------------------------------------------------------------
  # 1단계: Git 소스 업데이트
  # ------------------------------------------------------------------------------
  log INFO "Git 저장소 업데이트 진행... ($git_dir)"

  if [[ ! -d "$git_dir" ]]; then
    die "GIT_DIR 경로를 찾을 수 없습니다: $git_dir"
  fi

  cd "$git_dir" || die "$git_dir 경로로 이동할 수 없습니다."

  if ! git pull; then
    die "'git pull' 실행 중 오류가 발생했습니다. 이후 작업을 취소합니다."
  fi
  log INFO "Git 업데이트 완료."
  echo ""

  # ------------------------------------------------------------------------------
  # 2단계: 설정 파일 복사
  # ------------------------------------------------------------------------------
  log INFO "설정 파일 복사 진행..."

  if [[ ! -f "$src_dir" ]]; then
    die "복사할 원본을 찾을 수 없습니다: $src_dir"
  fi

  if [[ ! -d "$tgt_dir" ]]; then
    log INFO "타겟 디렉토리가 존재하지 않아 새로 생성합니다: $tgt_dir"
    mkdir -p "$tgt_dir" || die "타겟 디렉토리를 생성할 수 없습니다: $tgt_dir"
  fi

  if cp -p "$src_dir" "$tgt_dir/"; then
    log INFO "복사 성공: $src_dir -> $tgt_dir/"
  else
    die "파일 복사 중 문제가 발생했습니다."
  fi

  echo ""
  log INFO "🎉 모든 작업이 성공적으로 완료되었습니다!"
}

# 진입점
main "$@"

exit 0
