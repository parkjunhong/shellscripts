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
  local res status=0
  
  res=$(glab api --method POST "projects/:fullpath/protected_branches" \
    -f name="${branch}" -f push_access_level=0 -f merge_access_level=40 -f allow_force_push=false 2>&1) || status=$?
    
  if [[ $status -ne 0 && "$res" != *"409"* ]]; then echo "ERROR:${res}"; fi
}

##
# GitLab 저장소의 브랜치 보호를 해제합니다.
#
# @param $1 {string} 브랜치명
##
api_gitlab_unprotect_branch() {
  local branch="$1"
  # URL에 슬래시(/) 등 특수문자 포함 대비 수동 인코딩
  local enc_branch
  enc_branch=$(echo -n "${branch}" | sed 's/\//%2F/g')
  
  local res status=0
  res=$(glab api --method DELETE "projects/:fullpath/protected_branches/${enc_branch}" 2>&1) || status=$?
  
  if [[ $status -ne 0 && "$res" != *"404"* ]]; then echo "ERROR:${res}"; fi
}

##
# GitLab 저장소의 보호된 브랜치 목록을 반환합니다.
# jq 없이 정규식으로 안전하게 추출합니다.
#
# @return {string} 브랜치명 목록 (개행 분리)
##
api_gitlab_show_protected() {
  local res status=0
  res=$(glab api "projects/:fullpath/protected_branches" 2>&1) || status=$?
  
  if [[ $status -eq 0 ]]; then
    echo "$res" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//' || true
  else
    echo "ERROR:${res}"
  fi
}

##
# GitLab 저장소의 기본 브랜치를 설정합니다.
#
# @param $1 {string} 브랜치명
##
api_gitlab_set_default() {
  local branch="$1"
  local res status=0
  res=$(glab api --method PUT "projects/:fullpath" -f default_branch="${branch}" 2>&1) || status=$?
  
  if [[ $status -ne 0 ]]; then echo "ERROR:${res}"; fi
}

##
# GitLab 저장소의 기본 브랜치 이름을 반환합니다.
# jq 없이 정규식으로 안전하게 추출합니다.
#
# @return {string} 기본 브랜치명
##
api_gitlab_show_default() {
  local res status=0
  res=$(glab api "projects/:fullpath" 2>&1) || status=$?
  
  if [[ $status -eq 0 ]]; then
    echo "$res" | grep -o '"default_branch":"[^"]*"' | head -n 1 | sed 's/"default_branch":"//;s/"//' || true
  else
    echo "ERROR:${res}"
  fi
}
