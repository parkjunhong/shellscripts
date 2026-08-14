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
NEXUS_USER="${NEXUS_USER:-migration-test}"
NEXUS_PASSWORD="${NEXUS_PASSWORD:-}"
INPUT_DIR="${INPUT_DIR:-./nexus-export}"

CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"
RETRY_COUNT="${RETRY_COUNT:-5}"
RETRY_DELAY="${RETRY_DELAY:-2}"

INSECURE=0
VERBOSE=0
DRY_RUN=0
FORCE=0
VERIFY_REMOTE=1
INCLUDE_CHECKSUM_ASSETS=0

LIMIT=0
PATH_PREFIX=""

DEFAULT_REPOSITORY_MAPS=(
  "maven-releases=maven-migration-test-releases"
  "maven-snapshots=maven-migration-test-snapshots"
)

REPOSITORY_MAPS=()

RUN_ID=""
RUN_LOG=""
AUTH_CONFIG=""
REPOSITORIES_JSON=""

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
  echo "Sonatype Nexus Repository 3 - Maven Assets Import Utility"
  echo
  echo "Options:"
  echo "  --url URL                  신규 타깃 Nexus 기본 URL (기본값: http://localhost:8081)"
  echo "  --user USER                Nexus 마이그레이션 계정 (기본값: migration-test)"
  echo "  --input DIRECTORY          내보내기 파일이 저장된 루트 디렉터리 (기본값: ./nexus-export)"
  echo "  --repository-map SRC=TGT   소스 및 타깃 저장소 매핑 (다중 지정 가능)"
  echo "  --path-prefix PREFIX       특정 접두사로 시작하는 자산만 필터링하여 적재"
  echo "  --limit N                  저장소별 최대 처리 자산 수 제한 (0: 무제한)"
  echo "  --dry-run                  실제 업로드 없이 무결성 및 타깃 저장소 검증만 수행"
  echo "  --force                    타깃에 상이한 파일이 존재하더라도 강제 덮어쓰기"
  echo "  --no-verify                업로드 완료 후 다운로드 및 체크섬 검증 건너뛰기"
  echo "  --include-checksum-assets  체크섬 자산(*.sha1, *.md5)을 명시적으로 함께 업로드"
  echo "  --insecure                 curl TLS 인증서 검증 비활성화"
  echo "  --verbose                  상세 진단 로그 활성화"
  echo "  --help                     도움말 출력"
  echo
  echo "Environment variables:"
  echo "  NEXUS_URL, NEXUS_USER, NEXUS_PASSWORD, INPUT_DIR"
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
# 입력된 디렉터리 경로를 절대 경로(Absolute Path)로 정규화하여 반환합니다.
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
      printf '[%s] [INFO ] 🎉 적재(Import) 프로세스가 정상 종료되었습니다.\n' "$(timestamp)" >> "${RUN_LOG}"
    else
      printf '[%s] [ERROR] ❌ 적재(Import) 프로세스가 오류로 종료되었습니다 (exit code: %d).\n' \
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

  AUTH_CONFIG="$(mktemp "${TMPDIR:-/tmp}/nexus-import-curl.XXXXXX")"
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
    "--silent" \
    "--show-error"

  if [[ "${INSECURE}" -eq 1 ]]; then
    printf '%s\n' "--insecure"
  fi
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

  [[ -n "${path}" ]] || return 1
  [[ "${path}" != /* ]] || return 1

  case "/${path}/" in
    */../*|*/./*)
      return 1
      ;;
  esac

  return 0
}

##
# 대상 파일이 체크섬 파일(*.sha1, *.md5)인지 확인합니다.
#
# @param $1 {string} 파일 경로
#
# @return 0 (체크섬 파일), 1 (일반 아티팩트 파일)
##
is_checksum_asset() {
  local path="$1"

  case "${path}" in
    *.sha1|*.md5)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

##
# 로컬 또는 다운로드된 파일의 SHA-1 및 MD5 체크섬을 검증합니다.
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
    [[ "${actual}" == "${expected_sha1}" ]] || return 10
  fi

  if [[ -n "${expected_md5}" && "${expected_md5}" != "null" ]]; then
    actual="$(md5sum "${file}" | awk '{print $1}')"
    [[ "${actual}" == "${expected_md5}" ]] || return 11
  fi

  return 0
}

##
# Nexus 저장소 아티팩트의 전체 HTTP 엔드포인트 URL을 생성합니다.
#
# @param $1 {string} 저장소 이름
# @param $2 {string} 자산 상대 경로
#
# @return string (HTTP URL)
##
build_repository_url() {
  local repository="$1"
  local path="$2"

  printf '%s/repository/%s/%s' \
    "${NEXUS_URL%/}" \
    "${repository}" \
    "${path}"
}

##
# SOURCE=TARGET 형식의 저장소 매핑 문자열 유효성을 검증합니다.
#
# @param $1 {string} 저장소 매핑 문자열
#
# @return 0 (유효함), 1 (유효하지 않음)
##
parse_repository_map() {
  local mapping="$1"

  [[ "${mapping}" == *=* ]] || return 1

  local source="${mapping%%=*}"
  local target="${mapping#*=}"

  [[ -n "${source}" && -n "${target}" ]]
}

##
# 신규 타깃 Nexus 저장소의 존재 및 포맷(maven2/hosted)을 검증합니다.
#
# @param $1 {string} 타깃 저장소 이름
#
# @return 0 (검증 성공) / 예외 발생 시 프로세스 종료
##
validate_target_repository() {
  local target_repository="$1"
  local repo_json

  repo_json="$(
    jq -c \
      --arg name "${target_repository}" \
      '.[] | select(.name == $name)' \
      <<< "${REPOSITORIES_JSON}" \
      | head -n 1
  )"

  if [[ -z "${repo_json}" ]]; then
    help "타깃 Nexus에 대상 저장소가 존재하지 않습니다 -> ${target_repository}" "${LINENO}"
    exit 1
  fi

  local format type
  format="$(jq -r '.format // ""' <<< "${repo_json}")"
  type="$(jq -r '.type // ""' <<< "${repo_json}")"

  if [[ "${format}" != "maven2" ]]; then
    help "타깃 저장소 '${target_repository}'의 포맷이 maven2가 아닙니다 (format: ${format})" "${LINENO}"
    exit 1
  fi

  if [[ "${type}" != "hosted" ]]; then
    help "타깃 저장소 '${target_repository}'의 타입이 hosted가 아닙니다 (type: ${type})" "${LINENO}"
    exit 1
  fi

  log "INFO" "✅ 타깃 저장소 사양 검증 완료 -> ${target_repository} (format: ${format}, type: ${type})"
}

##
# 타깃 Nexus 저장소에 자산이 이미 존재하는지 확인하고 체크섬을 비교합니다.
#
# @param $1 {string} 타깃 저장소 이름
# @param $2 {string} 자산 경로
# @param $3 {string} 예상 SHA-1 값
# @param $4 {string} 예상 MD5 값
# @param $5 {string} 다운로드 임시 파일 경로
#
# @return 0 (동일 파일 존재), 1 (파일 없음: 404), 2 (파일 존재하나 체크섬 불일치), 3 (조회 실패 또는 권한 오류)
##
check_target_asset() {
  echo ""
  
  local target_repository="$1"
  local path="$2"
  local expected_sha1="$3"
  local expected_md5="$4"
  local temp_file="$5"

  local url http_code
  url="$(build_repository_url "${target_repository}" "${path}")"
  rm -f "${temp_file}"

  http_code="$(
    curl "${CURL_ARGS[@]}" \
      --path-as-is \
      --output "${temp_file}" \
      --write-out '%{http_code}' \
      "${url}" \
      2>/dev/null
  )" || true

  case "${http_code}" in
    200)
      if verify_checksum "${temp_file}" "${expected_sha1}" "${expected_md5}"; then
        rm -f "${temp_file}"
        return 0
      fi
      rm -f "${temp_file}"
      return 2
      ;;
    404)
      rm -f "${temp_file}"
      return 1
      ;;
    *)
      rm -f "${temp_file}"
      return 3
      ;;
  esac
}

##
# 자산을 타깃 Nexus 저장소 엔드포인트로 HTTP PUT 업로드합니다.
#
# @param $1 {string} 타깃 저장소 이름
# @param $2 {string} 자산 경로
# @param $3 {string} 업로드할 로컬 파일 경로
#
# @return 0 (성공), 43 (권한 오류: 401/403), 44 (기타 HTTP 오류), curl 반환코드 (네트워크 오류)
##
upload_asset() {
  echo ""
  
  local target_repository="$1"
  local path="$2"
  local local_file="$3"

  local url response_file http_code
  url="$(build_repository_url "${target_repository}" "${path}")"
  response_file="$(mktemp "${TMPDIR:-/tmp}/nexus-import-response.XXXXXX")"

  http_code="$(
    curl "${CURL_ARGS[@]}" \
      --path-as-is \
      --request PUT \
      --upload-file "${local_file}" \
      --output "${response_file}" \
      --write-out '%{http_code}' \
      "${url}"
  )" || {
    local rc=$?
    rm -f "${response_file}"
    return "${rc}"
  }

  case "${http_code}" in
    200|201|202|204)
      rm -f "${response_file}"
      return 0
      ;;
    401|403)
      log "ERROR" "❌ 권한 부족 오류 발생 (HTTP ${http_code}) -> ${path}"
      log "ERROR" "필요한 Repository View 권한을 확인하세요 (browse, read, add, edit)"
      rm -f "${response_file}"
      return 43
      ;;
    *)
      log "ERROR" "❌ 업로드 실패 (HTTP ${http_code}) -> ${path}"
      if [[ -f "${response_file}" ]]; then
        debug "응답 내용: $(cat "${response_file}")"
      fi
      rm -f "${response_file}"
      return 44
      ;;
  esac
}

##
# 단일 저장소 쌍(Source -> Target)에 대한 자산 적재(Import) 작업을 총괄합니다.
#
# @param $1 {string} 소스 저장소 이름
# @param $2 {string} 타깃 저장소 이름
#
# @return 0 (성공), 1 (실패 항목 존재)
##
import_repository() {

  echo ""
  
  local source_repository="$1"
  local target_repository="$2"

  validate_target_repository "${target_repository}"

  local source_dir="${INPUT_DIR}/${source_repository}"
  local inventory_file="${source_dir}/inventory/assets.jsonl"
  local content_dir="${source_dir}/repository"

  if [[ ! -f "${inventory_file}" ]]; then
    help "인벤토리 파일을 찾을 수 없습니다: ${inventory_file}" "${LINENO}"
    return 1
  fi

  if [[ ! -d "${content_dir}" ]]; then
    help "저장소 원본 아티팩트 디렉터리를 찾을 수 없습니다: ${content_dir}" "${LINENO}"
    return 1
  fi

  local import_dir="${source_dir}/import/${target_repository}"
  mkdir -p "${import_dir}"

  local success_log="${import_dir}/success.log"
  local skipped_log="${import_dir}/skipped.log"
  local filtered_log="${import_dir}/filtered.log"
  local failed_log="${import_dir}/failed.log"
  local checksum_failed_log="${import_dir}/checksum-failed.log"
  local summary_file="${import_dir}/import-summary.txt"

  touch \
    "${success_log}" \
    "${skipped_log}" \
    "${filtered_log}" \
    "${failed_log}" \
    "${checksum_failed_log}"

  local inventory_total
  inventory_total="$(wc -l < "${inventory_file}")"

  local processed=0
  local uploaded=0
  local skipped_existing=0
  local skipped_checksum=0
  local filtered_prefix=0
  local failed=0
  local local_checksum_failed=0
  local remote_checksum_failed=0

  log "INFO" "📥 [${source_repository} -> ${target_repository}] 적재 작업을 개시합니다 (총 ${inventory_total}개 자산) ->"

  local path expected_sha1 expected_md5
  while IFS=$'\t' read -r path expected_sha1 expected_md5; do
    if [[ -n "${PATH_PREFIX}" && "${path}" != "${PATH_PREFIX}"* ]]; then
      printf '%s\t%s\tPATH_PREFIX\n' "$(timestamp)" "${path}" >> "${filtered_log}"
      filtered_prefix=$((filtered_prefix + 1))
      continue
    fi

    if [[ "${INCLUDE_CHECKSUM_ASSETS}" -eq 0 ]] && is_checksum_asset "${path}"; then
      printf '%s\t%s\tCHECKSUM_ASSET\n' "$(timestamp)" "${path}" >> "${filtered_log}"
      skipped_checksum=$((skipped_checksum + 1))
      continue
    fi

    if [[ "${LIMIT}" -gt 0 && "${processed}" -ge "${LIMIT}" ]]; then
      log "INFO" "⚠️  지정된 처리 제한 건수(--limit ${LIMIT})에 도달하여 중단합니다."
      break
    fi

    processed=$((processed + 1))

    # 단일 행 진행률 콘솔 출력
    printf "\r\033[K⏳ [%s -> %s] Processed=%d, Uploaded=%d, Skipped=%d" \
      "${source_repository}" "${target_repository}" "${processed}" "${uploaded}" "${skipped_existing}"

    if ! safe_repository_path "${path}"; then
      printf '%s\t%s\tUNSAFE_PATH\n' "$(timestamp)" "${path}" >> "${failed_log}"
      failed=$((failed + 1))
      continue
    fi

    local local_file="${content_dir}/${path}"

    if [[ ! -f "${local_file}" ]]; then
      printf '%s\t%s\tLOCAL_FILE_NOT_FOUND\n' "$(timestamp)" "${path}" >> "${failed_log}"
      failed=$((failed + 1))
      continue
    fi

    if ! verify_checksum "${local_file}" "${expected_sha1}" "${expected_md5}"; then
      printf '%s\t%s\tLOCAL_CHECKSUM_MISMATCH\n' "$(timestamp)" "${path}" >> "${checksum_failed_log}"
      local_checksum_failed=$((local_checksum_failed + 1))
      continue
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
      printf '%s\t%s\tDRY_RUN_VALIDATED\n' "$(timestamp)" "${path}" >> "${skipped_log}"
      continue
    fi

    local temp_target target_state=0
    temp_target="$(mktemp "${TMPDIR:-/tmp}/nexus-import-target.XXXXXX")"

    check_target_asset \
      "${target_repository}" \
      "${path}" \
      "${expected_sha1}" \
      "${expected_md5}" \
      "${temp_target}" || target_state=$?

    rm -f "${temp_target}" || true

    case "${target_state}" in
      0)
        printf '%s\t%s\tTARGET_CHECKSUM_MATCH\n' "$(timestamp)" "${path}" >> "${skipped_log}"
        skipped_existing=$((skipped_existing + 1))
        continue
        ;;
      1)
        ;;
      2)
        if [[ "${FORCE}" -eq 0 ]]; then
          printf '%s\t%s\tTARGET_CHECKSUM_DIFFERENT\n' "$(timestamp)" "${path}" >> "${failed_log}"
          failed=$((failed + 1))
          continue
        fi
        ;;
      3)
        printf '%s\t%s\tTARGET_READ_FAILED_OR_FORBIDDEN\n' "$(timestamp)" "${path}" >> "${failed_log}"
        failed=$((failed + 1))
        continue
        ;;
    esac

    local upload_rc=0
    upload_asset "${target_repository}" "${path}" "${local_file}" || upload_rc=$?

    if [[ "${upload_rc}" -ne 0 ]]; then
      printf '%s\t%s\tUPLOAD_FAILED\trc=%s\n' "$(timestamp)" "${path}" "${upload_rc}" >> "${failed_log}"
      failed=$((failed + 1))
      continue
    fi

    if [[ "${VERIFY_REMOTE}" -eq 1 ]]; then
      local verify_file post_state=0
      verify_file="$(mktemp "${TMPDIR:-/tmp}/nexus-import-verify.XXXXXX")"

      check_target_asset \
        "${target_repository}" \
        "${path}" \
        "${expected_sha1}" \
        "${expected_md5}" \
        "${verify_file}" || post_state=$?

      rm -f "${verify_file}" || true

      if [[ "${post_state}" -ne 0 ]]; then
        printf '%s\t%s\tPOST_UPLOAD_CHECKSUM_FAILED\tstate=%s\n' \
          "$(timestamp)" "${path}" "${post_state}" \
          >> "${checksum_failed_log}"
        remote_checksum_failed=$((remote_checksum_failed + 1))
        continue
      fi
    fi

    uploaded=$((uploaded + 1))

    printf '%s\t%s\t%s\t%s\n' \
      "$(timestamp)" "${path}" "${expected_sha1}" "${expected_md5}" \
      >> "${success_log}"

  done < <(
    jq -r '
      [
        .path,
        (.checksum.sha1 // ""),
        (.checksum.md5 // "")
      ] | @tsv
    ' "${inventory_file}"
  )

  echo # 단일 행 갱신 후 줄바꿈

  {
    printf 'Source repository            : %s\n' "${source_repository}"
    printf 'Target repository            : %s\n' "${target_repository}"
    printf 'Completed at                 : %s\n' "$(timestamp)"
    printf 'Dry run                      : %s\n' "${DRY_RUN}"
    printf 'Inventory assets             : %s\n' "${inventory_total}"
    printf 'Processed selected assets    : %s\n' "${processed}"
    printf 'Uploaded this run            : %s\n' "${uploaded}"
    printf 'Skipped existing/matching    : %s\n' "${skipped_existing}"
    printf 'Skipped checksum assets      : %s\n' "${skipped_checksum}"
    printf 'Filtered by path prefix      : %s\n' "${filtered_prefix}"
    printf 'Local checksum failures      : %s\n' "${local_checksum_failed}"
    printf 'Remote checksum failures     : %s\n' "${remote_checksum_failed}"
    printf 'Other failures               : %s\n' "${failed}"
  } > "${summary_file}"

  log "INFO" "📊 [${source_repository} -> ${target_repository}] 적재 요약 정보 ->"
  log "INFO" "   인벤토리 총 자산 수      = ${inventory_total}"
  log "INFO" "   선택 처리 대상 수        = ${processed}"
  log "INFO" "   이번 실행 업로드 완료    = ${uploaded}"
  log "INFO" "   기존 검증 완료 건너뜀    = ${skipped_existing}"
  log "INFO" "   체크섬 자산 제외         = ${skipped_checksum}"
  log "INFO" "   접두사 필터 제외         = ${filtered_prefix}"
  log "INFO" "   로컬 체크섬 검증 실패    = ${local_checksum_failed}"
  log "INFO" "   원격 재검증 체크섬 실패  = ${remote_checksum_failed}"
  log "INFO" "   기타 실패 건수           = ${failed}"

  if [[ "${local_checksum_failed}" -gt 0 || "${remote_checksum_failed}" -gt 0 || "${failed}" -gt 0 ]]; then
    log "WARN" "⚠️  [${source_repository} -> ${target_repository}] 적재 중 실패 항목이 존재합니다. ${import_dir} 로그를 확인하세요."
    return 1
  fi

  log "INFO" "✅ [${source_repository} -> ${target_repository}] 저장소 적재 작업이 성공적으로 완료되었습니다."
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
  require_command head
  require_command wc

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
          help "--user 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        NEXUS_USER="$2"
        shift 2
        ;;

      --input)
        [[ $# -ge 2 ]] || {
          help "--input 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        INPUT_DIR="$2"
        shift 2
        ;;

      --repository-map)
        [[ $# -ge 2 ]] || {
          help "--repository-map 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        REPOSITORY_MAPS+=("$2")
        shift 2
        ;;

      --path-prefix)
        [[ $# -ge 2 ]] || {
          help "--path-prefix 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        PATH_PREFIX="$2"
        shift 2
        ;;

      --limit)
        [[ $# -ge 2 ]] || {
          help "--limit 옵션에 값이 입력되지 않았습니다." "${LINENO}"
          exit 1
        }
        LIMIT="$2"
        [[ "${LIMIT}" =~ ^[0-9]+$ ]] || {
          help "--limit 값은 0 이상의 정수여야 합니다: ${LIMIT}" "${LINENO}"
          exit 1
        }
        shift 2
        ;;

      --dry-run)
        DRY_RUN=1
        shift
        ;;

      --force)
        FORCE=1
        shift
        ;;

      --no-verify)
        VERIFY_REMOTE=0
        shift
        ;;

      --include-checksum-assets)
        INCLUDE_CHECKSUM_ASSETS=1
        shift
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

  if [[ "${#REPOSITORY_MAPS[@]}" -eq 0 ]]; then
    REPOSITORY_MAPS=("${DEFAULT_REPOSITORY_MAPS[@]}")
  fi

  local mapping
  for mapping in "${REPOSITORY_MAPS[@]}"; do
    if ! parse_repository_map "${mapping}"; then
      help "올바르지 않은 저장소 매핑 형식입니다 (SOURCE=TARGET 필요): ${mapping}" "${LINENO}"
      exit 1
    fi
  done

  NEXUS_URL="${NEXUS_URL%/}"

  if [[ ! -d "${INPUT_DIR}" ]]; then
    help "입력 데이터 디렉터리가 존재하지 않습니다: ${INPUT_DIR}" "${LINENO}"
    exit 1
  fi

  # 입력 디렉터리를 완전한 절대 경로(Absolute Path)로 정규화
  INPUT_DIR="$(get_absolute_path "${INPUT_DIR}")"

  if [[ -z "${NEXUS_PASSWORD}" ]]; then
    if [[ -t 0 ]]; then
      printf 'Nexus migration password for %s: ' "${NEXUS_USER}" >&2
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

  mkdir -p "${INPUT_DIR}/import-logs"

  RUN_ID="$(date '+%Y%m%d-%H%M%S')"
  RUN_LOG="${INPUT_DIR}/import-logs/run-${RUN_ID}.log"
  touch "${RUN_LOG}"

  create_auth_config

  log "INFO" "🚀 Nexus Assets Import 유틸리티를 시작합니다."
  log "INFO" "⚙️  프로그램 실행       : ${FILENAME}"
  log "INFO" "🌐 타깃 Nexus          : ${NEXUS_URL}"
  log "INFO" "👤 Nexus 계정          : ${NEXUS_USER}"
  log "INFO" "📁 입력 데이터 디렉터리: ${INPUT_DIR}"
  log "INFO" "📝 로그 파일           : ${RUN_LOG}"
  log "INFO" "📦 저장소 매핑 목록    : ${REPOSITORY_MAPS[*]}"
  log "INFO" "🧪 Dry Run 모드        : ${DRY_RUN}"
  log "INFO" "🔄 강제 덮어쓰기       : ${FORCE}"
  log "INFO" "🔍 원격 재검증 수행    : ${VERIFY_REMOTE}"
  log "INFO" "📄 체크섬 파일 포함    : ${INCLUDE_CHECKSUM_ASSETS}"
  
  CURL_ARGS=()
  while IFS= read -r arg; do
    CURL_ARGS+=("${arg}")
  done < <(curl_common_args)

  echo ""
  log "INFO" "🔍 신규 Nexus REST API 연결 및 저장소 목록을 조회합니다 ->"

  if ! REPOSITORIES_JSON="$(curl "${CURL_ARGS[@]}" --fail "${NEXUS_URL}/service/rest/v1/repositories" 2>/dev/null)"; then
    help "타깃 Nexus REST API에 접근할 수 없습니다. URL(${NEXUS_URL}), 계정 권한 및 네트워크 상태를 확인하세요." "${LINENO}"
    exit 1
  fi

  log "INFO" "✅ 타깃 Nexus REST API 연결 확인 완료 ->"

  local overall_failed=0
  local src_repo tgt_repo
  for mapping in "${REPOSITORY_MAPS[@]}"; do
    src_repo="${mapping%%=*}"
    tgt_repo="${mapping#*=}"

    if ! import_repository "${src_repo}" "${tgt_repo}"; then
      overall_failed=1
    fi
  done

  if [[ "${overall_failed}" -ne 0 ]]; then
    log "ERROR" "❌ 하나 이상의 저장소 적재 작업 중 에러가 발생했습니다."
    exit 1
  fi

  log "INFO" "🎉 요청된 모든 저장소에 대한 적재 작업이 성공적으로 종료되었습니다."
}

echo ""

main "$@"

exit 0
