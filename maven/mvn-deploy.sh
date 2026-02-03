#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : maven deploy helper.
# @license  : Apache License 2.0
# @since    : 2026-01-22
# @desc     : support RHEL 7/8/9, Oracle Linux 7/8/9, Ubuntu 20.04/22.04/24.04, Centos 7/Stream 8/9.
# @installation :
#   1. insert 'source <path>/<파일명>" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into
#   /etc/bashrc for all users.
# =======================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
FILENAME="$SCRIPT_NAME"

##
# 사용법/오류 출력 함수입니다.
#
# @param $1 {string} 오류 원인(선택)
# @param $2 {string|int} 오류 발생 라인(선택)
#
# @return (stdout) 사용법 출력
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
    printf "$formatl" "line" "${2:-N/A}"
    printf "$formatl" "callstack"
    local idx=1
    local func
    for func in "${FUNCNAME[@]:1}"
    do
      printf "$formatr" "["$idx"]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi
  echo
  cat <<'EOF'
Usage:
  mvn-deploy.sh [options] [-- <extra maven args...>]

Default Goals:
  -e clean deploy

Options:
  -U, --update-snapshots   스냅샷 업데이트 (mvn -U)
  -s, --skip-tests         테스트 생략 (mvn -DskipTests)
      --maven <path>       Maven 실행 파일 경로 또는 명령어 (기본: mvn)
      --settings <path>    settings.xml 경로 (mvn -s <path>)
      --profile <name>     활성화할 프로파일 (mvn -P <name>) (반복 가능)
      --dry-run            실행하지 않고 명령만 출력
  -h, --help               도움말 출력

Examples:
  ./mvn-deploy.sh
  ./mvn-deploy.sh -U -s
  ./mvn-deploy.sh --settings ~/.m2/settings.xml --profile prod
  ./mvn-deploy.sh -U -- --batch-mode -Drevision=1.2.3
EOF
}

##
# "~"로 시작하는 경로를 $HOME 기준으로 확장합니다.
#
# @param $1 {string} 경로
#
# @return (stdout) 확장된 경로
##
expand_tilde() {
  local p="${1:-}"
  if [[ "$p" == "~" ]]; then
    echo "$HOME"
  elif [[ "$p" == "~/"* ]]; then
    echo "$HOME/${p:2}"
  else
    echo "$p"
  fi
}

MVN_BIN="mvn"
UPDATE_SNAPSHOTS="false"
SKIP_TESTS="false"
DRY_RUN="false"
SETTINGS_XML=""
PROFILES=()
EXTRA_ARGS=()

##
# 인자를 파싱합니다.
# 알 수 없는 인자는 Maven 추가 인자로 전달합니다.
#
# @param $@ {array} 인자 목록
#
# @return 전역 변수 설정
##
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -U|--update-snapshots)
        UPDATE_SNAPSHOTS="true"
        shift
        ;;
      -s|--skip-tests)
        SKIP_TESTS="true"
        shift
        ;;
      --maven)
        if [ "$#" -lt 2 ]; then
          help "ERROR: --maven requires a value" "${LINENO}"
          exit 2
        fi
        MVN_BIN="$(expand_tilde "$2")"
        shift 2
        ;;
      --settings)
        if [ "$#" -lt 2 ]; then
          help "ERROR: --settings requires a path" "${LINENO}"
          exit 2
        fi
        SETTINGS_XML="$(expand_tilde "$2")"
        shift 2
        ;;
      --profile)
        if [ "$#" -lt 2 ]; then
          help "ERROR: --profile requires a value" "${LINENO}"
          exit 2
        fi
        PROFILES+=("$2")
        shift 2
        ;;
      --dry-run)
        DRY_RUN="true"
        shift
        ;;
      -h|--help)
        help
        exit 0
        ;;
      --)
        shift
        while [ "$#" -gt 0 ]; do
          EXTRA_ARGS+=("$1")
          shift
        done
        ;;
      *)
        EXTRA_ARGS+=("$1")
        shift
        ;;
    esac
  done
}

##
# 입력값 유효성을 검증합니다.
#
# @return 실패 시 exit
##
validate() {
  if ! command -v "$MVN_BIN" >/dev/null 2>&1; then
    help "ERROR: Maven executable not found: $MVN_BIN (힌트: --maven <path> 또는 PATH 확인)" "${LINENO}"
    exit 127
  fi

  if [ -n "$SETTINGS_XML" ] && [ ! -f "$SETTINGS_XML" ]; then
    help "ERROR: settings.xml not found: $SETTINGS_XML" "${LINENO}"
    exit 2
  fi
}

##
# Maven 실행 커맨드를 배열로 구성합니다.
#
# @return 전역 배열 CMD 설정
##
build_cmd() {
  CMD=("$MVN_BIN" "-e" "clean" "deploy")

  if [ "$UPDATE_SNAPSHOTS" = "true" ]; then
    CMD+=("-U")
  fi

  if [ "$SKIP_TESTS" = "true" ]; then
    CMD+=("-DskipTests")
  fi

  if [ -n "$SETTINGS_XML" ]; then
    CMD+=("-s" "$SETTINGS_XML")
  fi

  if [ "${#PROFILES[@]}" -gt 0 ]; then
    local joined
    joined="$(IFS=','; echo "${PROFILES[*]}")"
    CMD+=("-P" "$joined")
  fi

  if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    CMD+=("${EXTRA_ARGS[@]}")
  fi
}

##
# 사람이 읽기 좋게(쉘 이스케이프) 명령을 출력합니다.
#
# @return (stdout) 이스케이프된 커맨드 문자열
##
print_cmd() {
  printf '%q ' "${CMD[@]}"
}

##
# Maven을 실행하거나(dry-run이면 출력만) 종료 코드를 반환합니다.
#
# @return 종료 코드
##
run_cmd() {
  build_cmd

  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] ${SCRIPT_NAME}: $(print_cmd)"
    return 0
  fi

  echo "${SCRIPT_NAME}: $(print_cmd)"
  exec "${CMD[@]}"
}

main() {
  parse_args "$@"
  validate
  run_cmd
}

main "$@" || {
  help "ERROR: 실행 중 오류가 발생했습니다." "${LINENO}"
  exit 1
}

exit 0

