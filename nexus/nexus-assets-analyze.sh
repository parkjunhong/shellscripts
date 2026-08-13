#!/usr/bin/env bash

# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-12
# @desc : support RHEL 8/9, Oracle Linux 8/9, Ubuntu 20.04/22.04/24.04, RockyOS 8/9, CentOS 7/8
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
OUTPUT_DIR="${OUTPUT_DIR:-./nexus-analysis}"
REPOSITORIES=("maven-releases" "maven-snapshots")

##
# 스크립트 실행 실패 또는 도움말 요청 시 사용법 및 콜스택을 출력합니다.
#
# @param $1 {string} 에러 원인 메시지
# @param $2 {integer} 에러 발생 라인 번호
#
# @return 콘솔 도움말 및 에러 리포트 출력
##
help(){
  if [ ! -z "${1:-}" ]; then
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
  echo "Usage: $FILENAME [OPTIONS]"
  echo "Nexus 저장소 assets 분석 도구"
  echo
  echo "Options:"
  echo "  --url URL         Nexus 서버 URL (기본값: http://localhost:8080)"
  echo "  --user USER       Nexus 사용자 ID (기본값: admin)"
  echo "  --pass PASS       Nexus 비밀번호"
  echo "  --repo REPO       분석할 저장소명 (다중 지정 가능, 예: -r repo1 -r repo2)"
  echo "  --output DIR      결과 저장 디렉터리 (기본값: ./nexus-analysis)"
  echo "  --help            도움말 출력"
  echo
}

# 에러 발생 시 help 함수 자동 호출 트랩 설정
trap 'help "Command execution failed unexpectedly" ${LINENO}' ERR

##
# 필수 필수 종용 도구 설치 여부를 검증합니다.
#
# @return 필수 명령어가 없는 경우 스크립트 종료
##
check_dependencies() {
  local cmd
  for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "ERROR: 필수 명령어 '$cmd'가 설치되어 있지 않습니다." >&2
      exit 1
    fi
  done
}

##
# Nexus 저장소로부터 Assets 목록을 페이징하여 가져옵니다.
#
# @param $1 {string} 저장소 이름
# @param $2 {string} 저장 대상 파일 경로
#
# @return assets.jsonl 파일 생성 및 단일 행 진행률 콘솔 출력
##
fetch_assets() {
  local repository="$1"
  local output_file="$2"

  local token=""
  local page=0
  local total=0

  : > "${output_file}"

  echo
  echo "======================================================================"
  echo "Repository : ${repository}"
  echo "======================================================================"

  while true; do
    ((page += 1))

    local url="${NEXUS_URL}/service/rest/v1/assets?repository=${repository}"
    if [[ -n "${token}" ]]; then
      url="${url}&continuationToken=${token}"
    fi

    local response
    if ! response="$(curl --silent --show-error --fail --user "${NEXUS_USER}:${NEXUS_PASSWORD}" "${url}")"; then
      echo -e "\nERROR: Nexus API 호출에 실패했습니다. (URL: ${url})" >&2
      return 1
    fi

    if ! jq -e . >/dev/null 2>&1 <<< "${response}"; then
      echo -e "\nERROR: Nexus로부터 올바르지 않은 JSON 응답을 수신했습니다." >&2
      return 1
    fi

    local count
    count="$(jq '.items | length' <<< "${response}")"
    total=$((total + count))

    # 단일 행 진행률 출력 (\r 및 라인 지우기 \033[K 적용)
    printf "\r\033[KPage=%d, Total=%d" "${page}" "${total}"

    jq -c '.items[]' <<< "${response}" >> "${output_file}"

    token="$(jq -r '.continuationToken // empty' <<< "${response}")"
    if [[ -z "${token}" ]]; then
      break
    fi
  done

  echo # 단일 행 출력 후 줄바꿈 처리
  echo "Total Assets : ${total}"
}

##
# 수집된 Assets 데이터를 분석하여 요약 리포트를 생성합니다.
#
# @param $1 {string} 저장소 이름
# @param $2 {string} Assets JSONL 파일 경로
# @param $3 {string} 리포트 저장 디렉터리 경로
#
# @return summary.txt 및 extensions.txt 파일 생성
##
analyze_assets() {
  local repository="$1"
  local assets_file="$2"
  local repo_dir="$3"

  local paths_file="${repo_dir}/paths.txt"
  local extensions_file="${repo_dir}/extensions.txt"
  local summary_file="${repo_dir}/summary.txt"

  if [[ ! -f "${assets_file}" ]]; then
    echo "ERROR: 분석할 데이터 파일이 존재하지 않습니다: ${assets_file}" >&2
    return 1
  fi

  jq -r '.path' "${assets_file}" | sort > "${paths_file}"

  {
    echo "======================================================================"
    echo "Repository Analysis"
    echo "======================================================================"
    echo
    echo "Repository : ${repository}"
    echo
    echo "[Total Assets]"
    wc -l < "${paths_file}"
    echo
    echo "[Checksum Files]"

    local sha1_count md5_count
    sha1_count="$(grep -cE '\.sha1$' "${paths_file}" || true)"
    md5_count="$(grep -cE '\.md5$' "${paths_file}" || true)"

    echo "SHA1 : ${sha1_count}"
    echo "MD5  : ${md5_count}"
    echo "Total: $((sha1_count + md5_count))"
    echo
    echo "[Maven Metadata]"
    echo "maven-metadata.xml      : $(grep -cE '/?maven-metadata\.xml$' "${paths_file}" || true)"
    echo "maven-metadata.xml.sha1 : $(grep -cE 'maven-metadata\.xml\.sha1$' "${paths_file}" || true)"
    echo "maven-metadata.xml.md5  : $(grep -cE 'maven-metadata\.xml\.md5$' "${paths_file}" || true)"
    echo
    echo "[Artifact Types]"
    echo "JAR       : $(grep -cE '\.jar$' "${paths_file}" || true)"
    echo "POM       : $(grep -cE '\.pom$' "${paths_file}" || true)"
    echo "WAR       : $(grep -cE '\.war$' "${paths_file}" || true)"
    echo "EAR       : $(grep -cE '\.ear$' "${paths_file}" || true)"
    echo "ZIP       : $(grep -cE '\.zip$' "${paths_file}" || true)"
    echo "TAR       : $(grep -cE '\.tar$' "${paths_file}" || true)"
    echo "TGZ       : $(grep -cE '\.tgz$' "${paths_file}" || true)"
    echo "KAR       : $(grep -cE '\.kar$' "${paths_file}" || true)"
    echo "XML       : $(grep -cE '\.xml$' "${paths_file}" || true)"
    echo "MODULE    : $(grep -cE '\.module$' "${paths_file}" || true)"
    echo
    echo "[Classifiers]"
    echo "sources.jar : $(grep -cE '\-sources\.jar$' "${paths_file}" || true)"
    echo "javadoc.jar : $(grep -cE '\-javadoc\.jar$' "${paths_file}" || true)"
    echo "tests.jar   : $(grep -cE '\-tests\.jar$' "${paths_file}" || true)"
    echo
    echo "[SNAPSHOT]"
    echo "SNAPSHOT paths : $(grep -c -- '-SNAPSHOT/' "${paths_file}" || true)"
  } | tee "${summary_file}"

  awk '
  {
      file=$0
      sub(/^.*\//, "", file)

      if (file ~ /\.sha1$/) {
          print ".sha1"
      }
      else if (file ~ /\.md5$/) {
          print ".md5"
      }
      else if (file ~ /\./) {
          sub(/^.*\./, ".", file)
          print file
      }
      else {
          print "(no-extension)"
      }
  }
  ' "${paths_file}" \
    | sort \
    | uniq -c \
    | sort -nr \
    > "${extensions_file}"

  echo
  echo "[Extension Distribution]"
  cat "${extensions_file}"
}

##
# 메인 실행 함수
##
main() {
  check_dependencies

  local custom_repos=()

  # CLI 옵션 파싱
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url)
        NEXUS_URL="${2:-}"
        shift 2
        ;;
      --user)
        NEXUS_USER="${2:-}"
        shift 2
        ;;
      --pass)
        NEXUS_PASSWORD="${2:-}"
        shift 2
        ;;
      --repo)
        custom_repos+=("${2:-}")
        shift 2
        ;;
      --output)
        OUTPUT_DIR="${2:-}"
        shift 2
        ;;
      --help)
        help
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        help "Invalid Option '$1'" "${LINENO}"
        exit 1
        ;;
    esac
  done

  if [[ ${#custom_repos[@]} -gt 0 ]]; then
    REPOSITORIES=("${custom_repos[@]}")
  fi

  if [[ -z "${NEXUS_PASSWORD}" ]]; then
    echo "ERROR: NEXUS_PASSWORD가 설정되지 않았습니다. (-p 옵션 또는 환경변수 설정 필수)" >&2
    help "Missing NEXUS_PASSWORD" "${LINENO}"
    exit 1
  fi

  # 결과 저장 디렉터리 자동 생성
  mkdir -p "${OUTPUT_DIR}"

  local repository repo_dir assets_file
  for repository in "${REPOSITORIES[@]}"; do
    repo_dir="${OUTPUT_DIR}/${repository}"
    mkdir -p "${repo_dir}"
    assets_file="${repo_dir}/assets.jsonl"

    fetch_assets "${repository}" "${assets_file}"
    analyze_assets "${repository}" "${assets_file}" "${repo_dir}"
  done

  echo
  echo "======================================================================"
  echo "Analysis completed."
  echo "Output Directory: ${OUTPUT_DIR}"
  echo "======================================================================"
}

main "$@"

exit 0

