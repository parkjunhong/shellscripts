#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-06
# @desc : support RHEL 8+, Oracle Linux 9+, Ubuntu 20.04+, RockyOS 9+, CentOS 7
# @installation : 
# 1. insert 'source <path>/git-branch-module-gitlab-api.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-branch-module-gitlab-api.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

##
# GitLab 저장소의 브랜치를 보호 설정합니다. (멱등성 보장)
#
# @param $1 {string} 브랜치명
##
api_gitlab_protect_branch() {
  local branch="$1"
  
  # 이미 보호되어 409 Conflict 발생 시 우회(Ignore)하여 멱등성 유지
  glab api --method POST "projects/:fullpath/protected_branches" \
    -f name="${branch}" \
    -f push_access_level=0 \
    -f merge_access_level=40 \
    -f allow_force_push=false \
    --silent >/dev/null 2>&1 || true
}

##
# GitLab 저장소의 브랜치 보호를 해제합니다.
#
# @param $1 {string} 브랜치명
##
api_gitlab_unprotect_branch() {
  local branch="$1"
  # URL에 슬래시(/) 등 특수문자 포함 대비 (단순화된 삭제)
  local enc_branch
  enc_branch=$(echo -n "${branch}" | jq -sRr @uri 2>/dev/null || echo "$branch")
  
  glab api --method DELETE "projects/:fullpath/protected_branches/${enc_branch}" \
    --silent >/dev/null 2>&1 || true
}

##
# GitLab 저장소의 보호된 브랜치 목록을 반환합니다.
#
# @return {string} 브랜치명 목록 (개행 분리)
##
api_gitlab_show_protected() {
  glab api "projects/:fullpath/protected_branches" \
    --jq '.[].name' 2>/dev/null || true
}

##
# GitLab 저장소의 기본 브랜치를 설정합니다.
#
# @param $1 {string} 브랜치명
##
api_gitlab_set_default() {
  local branch="$1"
  glab api --method PUT "projects/:fullpath" \
    -f default_branch="${branch}" --silent >/dev/null 2>&1 || true
}

##
# GitLab 저장소의 기본 브랜치 이름을 반환합니다.
#
# @return {string} 기본 브랜치명
##
api_gitlab_show_default() {
  glab api "projects/:fullpath" --jq '.default_branch' 2>/dev/null || true
}
