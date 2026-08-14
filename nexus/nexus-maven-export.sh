#!/usr/bin/env bash

# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-14
# @desc : support RHEL 7/8/9, Oracle Linux 7/8/9, Ubuntu 18.04/20.04/22.04/24.04, RockyOS 8/9, CentOS 7/8
# @installation : 
# 1. insert 'source <path>/<파일명>' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
FILENAME="$(basename "$0")"

NEXUS_URL="${NEXUS_URL:-http://localhost:8081}"
NEXUS_USER="${NEXUS_USER:-admin}"
NEXUS_PASSWORD="${NEXUS_PASSWORD:-}"
OUTPUT_DIR="${OUTPUT_DIR:-./nexus-export}"

CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"
RETRY_COUNT="${RETRY_COUNT:-5}"
RETRY_DELAY="${RETRY_DELAY:-2}"

INSECURE=0
VERBOSE=0

DEFAULT_REPOSITORIES=(
  "maven-releases"
  "maven-snapshots"
  "maven-3rd-party"
)

REPOSITORIES=()

RUN_ID=""
RUN_LOG=""
AUTH_CONFIG=""
CURRENT_REPOSITORY=""

##
# 도움말 및 오류 발생 시 콜스택 정보를 출력합니다.
#
# @param $1 {string} 에러 원인 메시지 (선택)
# @param $2 {integer} 에러 발생 라인 번호 (선택)
#
# @return 도움말 및 콜스택 콘솔 출력
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
    if [[ ${#FUNCNAME[@]} -gt 1 ]]; then
      for func in "${FUNCNAME[@]:1}"; do
        printf "$formatr" "["$idx"]" "$func"
        ((idx++))
      done
    fi
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi 
  echo 
  echo "Usage: $FILENAME [options]"
  echo
  echo "Sonatype Nexus Repository 3 - Maven Assets Export Utility"
  echo
  echo "Options:"
  echo "  --url URL           Nexus 서버 기본 URL (기본값: http://localhost:8081)"
  echo "  --user USER         Nexus 사용자 계정 (기본값: admin)"
  echo "  --output DIRECTORY  내보내기 결과 저장 루트 디렉터리 (기본값: ./nexus-export)"
  echo "  --repository NAME   내보낼 저장소 이름 (다중 지정 가능)"
  echo "  --insecure          curl TLS 인증서 검증 비활성화"
  echo "  --verbose           상세 진단 로그 활성화"
  echo "  --help              도움말 출력"
  echo
  echo "Environment variables:"
  echo "  NEXUS_URL, NEXUS_USER, NEXUS_PASSWORD, OUTPUT_DIR"
  echo
}

##
# 현재 날짜 및 시각을 표준 포맷으로 반환합니다.
#
# @return string (yyyy-mm-dd HH:MM:SS)
##
timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

##
# 지정된 로그 레벨과 메시지를 화면 및 로그 파일에 출력합니다.
#
# @param $1 {string} 로그 레벨 (INFO, WARN, ERROR, DEBUG)
# @param $2 {string} 출력할 메시지
#
# @return 콘솔 및 로그 파일 출력
##
log() {
  local level="$1"
  shift
  local message="$*"

  printf '[%s] [%-5s] %s\n' "$(timestamp)" "${level}" "${message}" | tee -a "${RUN_LOG}"
}

##
# Verbose 모드가 활성화된 경우 디버그 로그를 출력합니다.
#
# @param $1 {string} 디버그 메시지
#
# @return 콘솔 및 로그 파일 디버그 출력
##
debug() {
  if [[ "${VERBOSE}" -eq 1 ]]; then
    log "DEBUG" "$@"
  fi
}

##
# 입력된 경로를 절대 경로(Absolute Path)로 정규화하여 반환합니다.
#
# @param $1 {string} 변환 대상 디렉터리 경로
#
# @return string (절대 경로)
##
get_absolute_path() {
  local target_path="$1"
  mkdir -p "${target_path}"
  (cd "${target_path}" && pwd)
}

##
# 필수 명령어가 시스템에 설치되어 있는지 검증합니다.
#
# @param $1 {string} 명령어 이름
#
# @return 명령어가 없을 경우 예외 메시지 출력 후 종료
##
require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    help "필수 명령어를 찾을 수 없습니다: ${cmd}" "${LINENO}"
    exit 1
  fi
}

##
# 스크립트 종료 시 임시 파일 및 자원을 정제합니다.
#
# @return 임시 자원 삭제 및 종료 상태 기록
##
cleanup() {
  local rc=$?

  trap - EXIT

  if [[ -n "${AUTH_CONFIG:-}" && -f "${AUTH_CONFIG}" ]]; then
    rm -f "${AUTH_CONFIG}" || true
  fi

  if [[ -n "${RUN_LOG:-}" && -f "${RUN_LOG}" ]]; then
    if [[ "${rc}" -eq 0 ]]; then
      printf '[%s] [INFO ] 🎉 내보내기 프로세스가 정상 종료되었습니다.\n' "$(timestamp)" >> "${RUN_LOG}"
    else
      printf '[%s] [ERROR] ❌ 내보내기 프로세스가 오류로 종료되었습니다 (exit code: %d).\n' \
        "$(timestamp)" "${rc}" >> "${RUN_LOG}"
    fi
  fi

  exit "${rc}"
}

##
# curl 설정 파일 내에서 사용할 문자열의 특수문자를 이스케이프 처리합니다.
#
# @param $1 {string} 이스케이프할 원본 문자열
#
# @return string (이스케이프된 문자열)
##
curl_config_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

##
# 비밀번호 보안을 위해 curl 인증 임시 설정 파일을 생성합니다.
#
# @return 생성된 임시 파일 경로를 AUTH_CONFIG 변수에 설정
##
create_auth_config() {
  local escaped_credentials

  escaped_credentials="$(curl_config_escape "${NEXUS_USER}:${NEXUS_PASSWORD}")"

  AUTH_CONFIG="$(mktemp "${TMPDIR:-/tmp}/nexus-export-curl.XXXXXX")"
  chmod 600 "${AUTH_CONFIG}"

  {
    printf 'user = "%s"\n' "${escaped_credentials}"
  } > "${AUTH_CONFIG}"
}

##
# curl 호출 시 공통으로 적용할 기본 옵션 배열 목록을 생성합니다.
#
# @return 라인 구분 방식의 curl 옵션 문자열 출력
##
curl_common_args() {
  printf '%s\n' \
    "--config" "${AUTH_CONFIG}" \
    "--connect-timeout" "${CONNECT_TIMEOUT}" \
    "--retry" "${RETRY_COUNT}" \
    "--retry-delay" "${RETRY_DELAY}" \
    "--location" \
    "--fail" \
    "--silent" \
    "--show-error"

  if [[ "${INSECURE}" -eq 1 ]]; then
    printf '%s\n' "--insecure"
  fi
}

##
# 다운로드한 파일의 SHA-1 및 MD5 체크섬을 검증합니다.
#
# @param $1 {string} 검증 대상 파일 경로
# @param $2 {string} 예상 SHA-1 값
# @param $3 {string} 예상 MD5 값
#
# @return 0 (검증 성공), 10 (SHA-1 불일치), 11 (MD5 불일치)
##
verify_checksum() {
  local file="$1"
  local expected_sha1="$2"
  local expected_md5="$3"

  local actual

  if [[ ! -f "${file}" ]]; then
    return 1
  fi

  if [[ -n "${expected_sha1}" && "${expected_sha1}" != "null" ]]; then
    actual="$(sha1sum "${file}" | awk '{print $1}')"
    if [[ "${actual}" != "${expected_sha1}" ]]; then
      return 10
    fi
  fi

  if [[ -n "${expected_md5}" && "${expected_md5}" != "null" ]]; then
    actual="$(md5sum "${file}" | awk '{print $1}')"
    if [[ "${actual}" != "${expected_md5}" ]]; then
      return 11
    fi
  fi

  return 0
}

##
# 저장소 자산 경로의 디렉터리 트래버설 공격 가능성을 검증합니다.
#
# @param $1 {string} 검증할 저장소 상대 경로
#
# @return 0 (안전함), 1 (위험한 경로)
##
safe_repository_path() {
  local path="$1"

  if [[ "${path}" == /* ]]; then
    return 1
  fi

  case "/${path}/" in
    */../*|*/./*)
      return 1
      ;;
  esac

  return 0
}

##
# 자산을 다운로드할 전체 REST URL 경로를 생성합니다.
#
# @param $1 {string} 저장소 이름
# @param $2 {string} 자산 상대 경로
#
# @return string (다운로드 대상 URL)
##
build_download_url() {
  local repository="$1"
  local path="$2"

  printf '%s/repository/%s/%s' \
    "${NEXUS_URL%/}" \
    "${repository}" \
    "${path}"
}

##
# Nexus REST API를 호출하여 저장소의 전체 자산 목록(Inventory)을 수집합니다.
#
# @param $1 {string} 저장소 이름
# @param $2 {string} 저장소별 출력 디렉터리 경로
#
# @return inventory/assets.jsonl, paths.txt, summary.txt 파일 생성
##
fetch_inventory() {
  local repository="$1"
  local repo_dir="$2"

  local inventory_dir="${repo_dir}/inventory"
  local inventory_file="${inventory_dir}/assets.jsonl"
  local paths_file="${inventory_dir}/paths.txt"
  local summary_file="${inventory_dir}/summary.txt"

  local tmp_inventory="${inventory_file}.tmp.$$"

  local token=""
  local page=0
  local total=0
  local response
  local count

  mkdir -p "${inventory_dir}"
  : > "${tmp_inventory}"

  log "INFO" "📦 [${repository}] 전체 자산 목록(Inventory) 수집을 시작합니다 ->"

  while true; do
    page=$((page + 1))

    local query_args=(
      "--get"
      "--data-urlencode" "repository=${repository}"
    )

    if [[ -n "${token}" ]]; then
      query_args+=("--data-urlencode" "continuationToken=${token}")
    fi

    if ! response="$(
      curl "${CURL_ARGS[@]}" \
        "${query_args[@]}" \
        "${NEXUS_URL}/service/rest/v1/assets"
    )"; then
      rm -f "${tmp_inventory}"
      help "[${repository}] ${page} 페이지 목록 수집 중 Nexus API 호출에 실패했습니다." "${LINENO}"
      exit 1
    fi

    if ! jq -e '
      (.items | type == "array") and
      (
        (.continuationToken == null) or
        (.continuationToken | type == "string")
      )
    ' >/dev/null 2>&1 <<< "${response}"; then
      rm -f "${tmp_inventory}"
      help "[${repository}] ${page} 페이지에서 유효하지 않은 API 응답을 수신했습니다." "${LINENO}"
      exit 1
    fi

    count="$(jq '.items | length' <<< "${response}")"
    total=$((total + count))

    jq -c '.items[]' <<< "${response}" >> "${tmp_inventory}"

    token="$(jq -r '.continuationToken // empty' <<< "${response}")"

    # 단일 행 진행률 실시간 출력 (\r 및 \033[K 적용)
    printf "\r\033[K⏳ [%s] Page=%d, Total=%d" "${repository}" "${page}" "${total}"

    if [[ -z "${token}" ]]; then
      break
    fi
  done

  echo

  mv -f "${tmp_inventory}" "${inventory_file}"

  jq -r '.path' "${inventory_file}" | sort > "${paths_file}"

  {
    printf 'Repository       : %s\n' "${repository}"
    printf 'Collected at     : %s\n' "$(timestamp)"
    printf 'Total assets     : %s\n' "$(wc -l < "${inventory_file}")"
    printf 'JAR              : %s\n' "$(grep -cE '\.jar$' "${paths_file}" || true)"
    printf 'POM              : %s\n' "$(grep -cE '\.pom$' "${paths_file}" || true)"
    printf 'WAR              : %s\n' "$(grep -cE '\.war$' "${paths_file}" || true)"
    printf 'EAR              : %s\n' "$(grep -cE '\.ear$' "${paths_file}" || true)"
    printf 'KAR              : %s\n' "$(grep -cE '\.kar$' "${paths_file}" || true)"
    printf 'ZIP              : %s\n' "$(grep -cE '\.zip$' "${paths_file}" || true)"
    printf 'ASC              : %s\n' "$(grep -cE '\.asc$' "${paths_file}" || true)"
    printf 'maven-metadata   : %s\n' "$(grep -cE '(^|/)maven-metadata\.xml$' "${paths_file}" || true)"
    printf 'SHA1 files       : %s\n' "$(grep -cE '\.sha1$' "${paths_file}" || true)"
    printf 'MD5 files        : %s\n' "$(grep -cE '\.md5$' "${paths_file}" || true)"
    printf 'SNAPSHOT paths   : %s\n' "$(grep -c -- '-SNAPSHOT/' "${paths_file}" || true)"
  } > "${summary_file}"

  log "INFO" "✅ [${repository}] 자산 목록 수집 완료 -> 총 ${total} 개"
}

##
# 단일 저장소의 모든 자산을 다운로드하고 검증을 수행합니다.
#
# @param $1 {string} 내보낼 저장소 이름
#
# @return 0 (내보내기 성공), 1 (실패 항목 존재)
##
export_repository() {
  local repository="$1"

  CURRENT_REPOSITORY="${repository}"

  local repo_dir="${OUTPUT_DIR}/${repository}"
  local content_dir="${repo_dir}/repository"
  local log_dir="${repo_dir}/logs"

  local success_log="${log_dir}/success.log"
  local skipped_log="${log_dir}/skipped.log"
  local failed_log="${log_dir}/failed.log"
  local checksum_failed_log="${log_dir}/checksum-failed.log"

  mkdir -p "${content_dir}" "${log_dir}"

  touch \
    "${success_log}" \
    "${skipped_log}" \
    "${failed_log}" \
    "${checksum_failed_log}"

  local inventory_file="${repo_dir}/inventory/assets.jsonl"

  fetch_inventory "${repository}" "${repo_dir}"

  if [[ ! -f "${inventory_file}" ]]; then
    log "ERROR" "❌ [${repository}] 인벤토리 파일이 존재하지 않습니다: ${inventory_file}"
    return 1
  fi

  local total
  total="$(wc -l < "${inventory_file}")"

  local index=0
  local success=0
  local skipped=0
  local failed=0
  local checksum_failed=0
  local downloaded_bytes=0

  log "INFO" "📥 [${repository}] 총 ${total}개 자산에 대한 다운로드를 시작합니다 ->"

  local path expected_sha1 expected_md5 original_download_url
  while IFS=$'\t' read -r path expected_sha1 expected_md5 original_download_url; do
    index=$((index + 1))

    if [[ -z "${path}" ]]; then
      log "ERROR" "❌ [${repository}] 인벤토리 레코드 ${index} 번의 자산 경로가 비어 있습니다."
      printf '%s\tEMPTY_PATH\n' "$(timestamp)" >> "${failed_log}"
      failed=$((failed + 1))
      continue
    fi

    if ! safe_repository_path "${path}"; then
      log "ERROR" "❌ [${repository}] 허용되지 않은 경로가 차단되었습니다 -> ${path}"
      printf '%s\t%s\tUNSAFE_PATH\n' "$(timestamp)" "${path}" >> "${failed_log}"
      failed=$((failed + 1))
      continue
    fi

    local destination="${content_dir}/${path}"
    local destination_dir
    destination_dir="$(dirname "${destination}")"

    mkdir -p "${destination_dir}"

    printf '[%s] [%s/%s] %s\n' \
      "${repository}" "${index}" "${total}" "${path}"

    if [[ -f "${destination}" ]]; then
      if verify_checksum "${destination}" "${expected_sha1}" "${expected_md5}"; then
        printf '%s\t%s\tVERIFIED_EXISTING\n' \
          "$(timestamp)" "${path}" >> "${skipped_log}"
        skipped=$((skipped + 1))
        debug "⏭️  [${repository}] 이미 검증된 파일이 존재하여 건너뜁니다 -> ${path}"
        continue
      else
        log "WARN" "⚠️  [${repository}] 기존 파일 체크섬 불일치로 재다운로드를 진행합니다 -> ${path}"
      fi
    fi

    local download_url
    download_url="$(build_download_url "${repository}" "${path}")"

    local part_file="${destination}.part.$$"
    rm -f "${part_file}"

    if ! curl "${CURL_ARGS[@]}" \
      --output "${part_file}" \
      "${download_url}"; then

      printf '%s\t%s\tDOWNLOAD_FAILED\t%s\t%s\n' \
        "$(timestamp)" "${path}" "${download_url}" "${original_download_url}" \
        >> "${failed_log}"

      rm -f "${part_file}"
      failed=$((failed + 1))

      log "ERROR" "❌ [${repository}] 다운로드 실패 -> ${path}"
      continue
    fi

    local verify_rc=0
    verify_checksum "${part_file}" "${expected_sha1}" "${expected_md5}" || verify_rc=$?

    if [[ "${verify_rc}" -ne 0 ]]; then
      local actual_sha1 actual_md5

      actual_sha1="$(sha1sum "${part_file}" | awk '{print $1}')"
      actual_md5="$(md5sum "${part_file}" | awk '{print $1}')"

      printf '%s\t%s\texpected_sha1=%s\tactual_sha1=%s\texpected_md5=%s\tactual_md5=%s\n' \
        "$(timestamp)" \
        "${path}" \
        "${expected_sha1}" \
        "${actual_sha1}" \
        "${expected_md5}" \
        "${actual_md5}" \
        >> "${checksum_failed_log}"

      rm -f "${part_file}"
      checksum_failed=$((checksum_failed + 1))

      log "ERROR" "❌ [${repository}] 체크섬 검증 실패 -> ${path}"
      continue
    fi

    local size
    size="$(stat -c '%s' "${part_file}")"

    mv -f "${part_file}" "${destination}"

    downloaded_bytes=$((downloaded_bytes + size))
    success=$((success + 1))

    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$(timestamp)" \
      "${path}" \
      "${size}" \
      "${expected_sha1}" \
      "${expected_md5}" \
      >> "${success_log}"

  done < <(
    jq -r '
      [
        .path,
        (.checksum.sha1 // ""),
        (.checksum.md5 // ""),
        (.downloadUrl // "")
      ] | @tsv
    ' "${inventory_file}"
  )

  local local_asset_count local_bytes
  local_asset_count="$(find "${content_dir}" -type f ! -name '*.part.*' | wc -l)"
  local_bytes="$(find "${content_dir}" -type f ! -name '*.part.*' -printf '%s\n' | awk '{s += $1} END {printf "%.0f\n", s + 0}')"

  local export_summary="${repo_dir}/export-summary.txt"

  {
    printf 'Repository             : %s\n' "${repository}"
    printf 'Completed at           : %s\n' "$(timestamp)"
    printf 'Inventory assets       : %s\n' "${total}"
    printf 'Downloaded this run    : %s\n' "${success}"
    printf 'Skipped verified       : %s\n' "${skipped}"
    printf 'Download failures      : %s\n' "${failed}"
    printf 'Checksum failures      : %s\n' "${checksum_failed}"
    printf 'Downloaded bytes(run)  : %s\n' "${downloaded_bytes}"
    printf 'Local asset files      : %s\n' "${local_asset_count}"
    printf 'Local bytes(total)     : %s\n' "${local_bytes}"
  } > "${export_summary}"

  log "INFO" "📊 [${repository}] 내보내기 요약 정보 ->"
  log "INFO" "[${repository}]   인벤토리 총 자산 수 = ${total}"
  log "INFO" "[${repository}]   이번 실행 다운로드  = ${success}"
  log "INFO" "[${repository}]   검증 후 건너뜀      = ${skipped}"
  log "INFO" "[${repository}]   다운로드 실패       = ${failed}"
  log "INFO" "[${repository}]   체크섬 검증 실패    = ${checksum_failed}"
  log "INFO" "[${repository}]   로컬 최종 파일 수   = ${local_asset_count}"

  if [[ "${failed}" -gt 0 || "${checksum_failed}" -gt 0 ]]; then
    log "WARN" "⚠️  [${repository}] 내보내기 도중 실패 항목이 발생했습니다. ${log_dir} 로그를 확인하세요."
    return 1
  fi

  if [[ "${local_asset_count}" -ne "${total}" ]]; then
    log "WARN" "⚠️  [${repository}] 로컬 자산 수(${local_asset_count})와 인벤토리 수(${total})가 일치하지 않습니다."
    return 1
  fi

  log "INFO" "✅ [${repository}] 내보내기가 성공적으로 완료되었습니다."
  return 0
}

##
# 스크립트 실행 메인 함수입니다.
#
# @param $@ {array} 커맨드라인 파라미터 배열
#
# @return 0 (성공), 1 (실패)
##
main() {
  trap 'help "스크립트 실행 중 비정상적인 에러가 발생했습니다." "${LINENO:-}"' ERR
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  require_command bash
  require_command curl
  require_command jq
  require_command sha1sum
  require_command md5sum
  require_command stat
  require_command awk
  require_command sed
  require_command sort
  require_command tee
  require_command mktemp

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url)
        [[ $# -ge 2 ]] || {
          help "--url 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        NEXUS_URL="$2"
        shift 2
        ;;

      --user)
        [[ $# -ge 2 ]] || {
          help "--user 옵션에 값이 입력되지 않았습나다." "${LINENO}"
          exit 1
        }
        NEXUS_USER="$2"
        shift 2
        ;;

      --output)
        [[ $# -ge 2 ]] || {
          help "--output 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        OUTPUT_DIR="$2"
        shift 2
        ;;

      --repository)
        [[ $# -ge 2 ]] || {
          help "--repository 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        REPOSITORIES+=("$2")
        shift 2
        ;;

      --insecure)
        INSECURE=1
        shift
        ;;

      --verbose)
        VERBOSE=1
        shift
        ;;

      --help)
        help
        exit 0
        ;;

      *)
        help "알 수 없거나 지원하지 않는 옵션입니다 (숏 옵션 미지원): $1" "${LINENO}"
        exit 1
        ;;
    esac
  done

  if [[ "${#REPOSITORIES[@]}" -eq 0 ]]; then
    REPOSITORIES=("${DEFAULT_REPOSITORIES[@]}")
  fi

  NEXUS_URL="${NEXUS_URL%/}"

  # 출력 디렉터리를 절대 경로(Absolute Path)로 즉시 정규화
  OUTPUT_DIR="$(get_absolute_path "${OUTPUT_DIR}")"

  if [[ -z "${NEXUS_PASSWORD}" ]]; then
    if [[ -t 0 ]]; then
      printf 'Nexus password for %s: ' "${NEXUS_USER}" >&2
      IFS= read -r -s NEXUS_PASSWORD
      printf '\n' >&2
    else
      help "NEXUS_PASSWORD 환경 변수가 설정되지 않았으며 대화형 터미널을 사용할 수 없습니다." "${LINENO}"
      exit 1
    fi
  fi

  [[ -n "${NEXUS_PASSWORD}" ]] || {
    help "빈 비밀번호는 허용되지 않습니다." "${LINENO}"
    exit 1
  }

  mkdir -p "${OUTPUT_DIR}/logs"

  RUN_ID="$(date '+%Y%m%d-%H%M%S')"
  RUN_LOG="${OUTPUT_DIR}/logs/run-${RUN_ID}.log"
  touch "${RUN_LOG}"

  create_auth_config

  log "INFO" "🚀 Nexus Assets Export 유틸리티를 시작합니다."
  log "INFO" "⚙️  프로그램 실행   : ${FILENAME}"
  log "INFO" "🌐 소스 Nexus      : ${NEXUS_URL}"
  log "INFO" "👤 Nexus 사용자    : ${NEXUS_USER}"
  log "INFO" "📁 출력 디렉터리   : ${OUTPUT_DIR}"
  log "INFO" "📝 로그 파일        : ${RUN_LOG}"
  log "INFO" "📦 대상 저장소     : ${REPOSITORIES[*]}"

  CURL_ARGS=()
  while IFS= read -r arg; do
    CURL_ARGS+=("${arg}")
  done < <(curl_common_args)

  log "INFO" "🔍 Nexus REST API 연결 및 인증을 검증합니다 ->"

  if ! curl "${CURL_ARGS[@]}" "${NEXUS_URL}/service/rest/v1/status" >/dev/null 2>&1; then
    if ! curl "${CURL_ARGS[@]}" "${NEXUS_URL}/service/rest/v1/repositories" >/dev/null; then
      help "Nexus REST API에 접근할 수 없습니다. URL(포트 8081 등), 계정 정보 및 네트워크 상태를 확인하세요." "${LINENO}"
      exit 1
    fi
  fi

  log "INFO" "✅ Nexus REST API 연결 상태 정상 확인 ->"

  local overall_failed=0
  local repository
  for repository in "${REPOSITORIES[@]}"; do
    if ! export_repository "${repository}"; then
      overall_failed=1
    fi
  done

  if [[ "${overall_failed}" -ne 0 ]]; then
    log "ERROR" "❌ 하나 이상의 저장소 내보내기 작업 중 에러가 발생했습니다."
    exit 1
  fi

  log "INFO" "🎉 모든 저장소에 대한 내보내기 작업이 성공적으로 종료되었습니다."
}

main "$@"

exit 0