#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : Github API branch module
# @license  : Apache License 2.0
# @since    : 2026-08-07
# @desc     : support RHEL 8+, Oracle Linux 9+, Ubuntu 20.04+, RockyOS 9+, CentOS 7+
# @installation : 
#   1. insert 'source <path>/git-branch-module-github-api.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-branch-module-github-api.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")
GITHUB_API_VERSION="2022-11-28"

# ---------------------------------------------------------
# [성능 최적화] 리포지토리 이름 캐싱용 전역 변수
# ---------------------------------------------------------
_CACHED_GITHUB_REPO=""

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
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" $func
      idx=$((idx + 1))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: 이 스크립트는 모듈로써 source 하여 사용합니다."
  echo "단독 실행 시 옵션:"
  echo "  -h, --help    이 도움말을 표시하고 종료합니다."
}

##
# 현재 Git 디렉토리의 GitHub 리포지토리 이름을 조회하고 캐싱합니다.
#
# @return (캐싱된 리포지토리 이름 출력)
##
_get_github_repo() {
  if [[ -z "${_CACHED_GITHUB_REPO}" ]]; then
    _CACHED_GITHUB_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)
  fi
  echo "${_CACHED_GITHUB_REPO}"
}

##
# GitHub API 에러 메시지를 사용자 친화적으로 파싱합니다.
#
# @param $1 {string} API 원본 응답(JSON 등)
#
# @return (직관적으로 파싱된 에러 메시지)
##
_parse_github_error() {
  local raw_res="$1"
  local err_msg
  err_msg=$(echo "$raw_res" | gh jq -r '.message' 2>/dev/null || true)
  
  if [[ -z "$err_msg" || "$err_msg" == "null" ]]; then
    err_msg="$raw_res"
  fi
  
  # 403 권한 에러 치환 처리 (Fine-grained PAT 권한 누락 대응)
  if [[ "$err_msg" == *"Resource not accessible by personal access token"* ]]; then
    err_msg="토큰 권한 부족 (해당 저장소 접근 권한 누락 또는 Fine-grained PAT 설정 오류)"
  fi
  
  # 개행 문자 제거 및 연속 공백 치환을 통한 로깅 가독성 확보
  echo "$err_msg" | tr '\n' ' ' | sed -E 's/ +/ /g'
}

##
# Github 저장소의 브랜치를 보호 설정합니다. (멱등성 보장)
#
# @param $1 {string} 브랜치명
#
# @return (오류 발생 시 에러 메시지 출력)
##
api_github_protect_branch() {
  local branch="$1"
  local repo
  repo=$(_get_github_repo)
  
  if [[ -z "$repo" ]]; then
    echo "ERROR: 리포지토리 정보를 가져올 수 없습니다."
    return 1
  fi
  
  local res status=0
  res=$(gh api --method PUT -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}/branches/${branch}/protection" \
    --input - <<EOF 2>&1
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
  ) || status=$?
  
  if [[ $status -ne 0 ]]; then echo "ERROR:$(_parse_github_error "$res")"; fi
}

##
# Github 저장소의 브랜치 보호를 해제합니다.
#
# @param $1 {string} 브랜치명
#
# @return (오류 발생 시 에러 메시지 출력)
##
api_github_unprotect_branch() {
  local branch="$1"
  local repo
  repo=$(_get_github_repo)
  
  if [[ -z "$repo" ]]; then
    echo "ERROR: 리포지토리 정보를 가져올 수 없습니다."
    return 1
  fi
  
  local res status=0
  res=$(gh api --method DELETE -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}/branches/${branch}/protection" 2>&1) || status=$?
    
  if [[ $status -ne 0 && "$res" != *"Not Found"* ]]; then echo "ERROR:$(_parse_github_error "$res")"; fi
}

##
# Github 저장소의 보호된 브랜치 목록을 반환합니다.
#
# @return (브랜치명 목록을 개행으로 분리하여 출력)
##
api_github_show_protected() {
  local repo
  repo=$(_get_github_repo)
  
  if [[ -z "$repo" ]]; then
    echo "ERROR: 리포지토리 정보를 가져올 수 없습니다."
    return 1
  fi
  
  local res status=0
  res=$(gh api -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" "repos/${repo}/branches" 2>&1) || status=$?
  
  if [[ $status -eq 0 ]]; then
    echo "$res" | gh jq '.[] | select(.protected==true) | .name' 2>/dev/null || true
  else
    echo "ERROR:$(_parse_github_error "$res")"
  fi
}

##
# Github 저장소의 기본 브랜치를 설정합니다.
#
# @param $1 {string} 브랜치명
#
# @return (오류 발생 시 에러 메시지 출력)
##
api_github_set_default() {
  local branch="$1"
  local repo
  repo=$(_get_github_repo)
  
  if [[ -z "$repo" ]]; then
    echo "ERROR: 리포지토리 정보를 가져올 수 없습니다."
    return 1
  fi
  
  local res status=0
  res=$(gh api --method PATCH -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}" -f default_branch="${branch}" 2>&1) || status=$?
    
  if [[ $status -ne 0 ]]; then echo "ERROR:$(_parse_github_error "$res")"; fi
}

##
# Github 저장소의 기본 브랜치 이름을 반환합니다.
#
# @return (기본 브랜치명을 출력)
##
api_github_show_default() {
  local repo
  repo=$(_get_github_repo)
  
  if [[ -z "$repo" ]]; then
    echo "ERROR: 리포지토리 정보를 가져올 수 없습니다."
    return 1
  fi
  
  local res status=0
  res=$(gh api -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" "repos/${repo}" --jq '.default_branch' 2>&1) || status=$?
  
  if [[ $status -eq 0 ]]; then
    echo "$res"
  else
    echo "ERROR:$(_parse_github_error "$res")"
  fi
}

# ==============================================================================
# 실행 컨텍스트 검증 블록
# ==============================================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # source 로 로딩된 경우, 부모 프로세스의 종료를 방지하기 위해 제어권을 안전하게 반환합니다.
  return 0 2>/dev/null || true
fi

# 단독 실행 시에만 에러 트랩 및 도움말 파싱 로직을 수행합니다.
trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  help "" ""
fi

exit 0
