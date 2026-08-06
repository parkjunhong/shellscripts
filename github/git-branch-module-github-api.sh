#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-06
# @desc : support RHEL 8+, Oracle Linux 9+, Ubuntu 20.04+, RockyOS 9+, CentOS 7
# @installation : 
# 1. insert 'source <path>/git-branch-module-github-api.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-branch-module-github-api.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

# GitHub API 버전 상수화 (변동 대비)
GITHUB_API_VERSION="2022-11-28"

##
# Github 저장소의 브랜치를 보호 설정합니다. (멱등성 보장)
#
# @param $1 {string} 브랜치명
##
api_github_protect_branch() {
  local branch="$1"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  
  # PUT 요청은 덮어쓰기(Upsert)로 동작하므로 멱등성이 기본 보장됩니다.
  gh api --method PUT -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}/branches/${branch}/protection" \
    --input - <<EOF >/dev/null 2>&1 || true
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
}

##
# Github 저장소의 브랜치 보호를 해제합니다.
#
# @param $1 {string} 브랜치명
##
api_github_unprotect_branch() {
  local branch="$1"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  
  # 삭제 실패 시(이미 보호가 안된 경우) 스크립트가 죽지 않도록 || true 처리
  gh api --method DELETE -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}/branches/${branch}/protection" >/dev/null 2>&1 || true
}

##
# Github 저장소의 보호된 브랜치 목록을 반환합니다.
#
# @return {string} 브랜치명 목록 (개행 분리)
##
api_github_show_protected() {
  local repo
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  gh api -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}/branches" --jq '.[] | select(.protected==true) | .name' 2>/dev/null || true
}

##
# Github 저장소의 기본 브랜치를 설정합니다.
#
# @param $1 {string} 브랜치명
##
api_github_set_default() {
  local branch="$1"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  gh api --method PATCH -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}" -f default_branch="${branch}" >/dev/null 2>&1 || true
}

##
# Github 저장소의 기본 브랜치 이름을 반환합니다.
#
# @return {string} 기본 브랜치명
##
api_github_show_default() {
  local repo
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  gh api -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    "repos/${repo}" --jq '.default_branch' 2>/dev/null || true
}

