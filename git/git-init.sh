#!/usr/bin/env bash

# =======================================
# @author : parkjunhong77@gmail.com
# @title : push an existing folder to a remote git repository.
# @license : Apache License 2.0
# @since : 2026-08-04
# @desc : support Ubuntu 20.04+, RHEL 8+, Oracle Linux 8+, Rocky Linux 8+
# @installation : 
# 1. insert 'source <path>/git-init.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-init.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME="$(basename "$0")"

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
    for func in "${FUNCNAME[@]:1}"
    do
      printf "$formatr" "[$idx]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi
  echo
  # TODO: Usage 내용 작성
  echo "[사용법]"
  echo "./$FILENAME [-h|--help] [-r|--repository] <원격 git 저장소> [-b|--branch] <원격 git 브랜치>"
  echo
  echo "[옵션]"
  echo " -b | --branch    : 연결할 원격 git 브랜치 이름입니다."
  echo " -r | --repository: 연결할 원격 git 저장소 주소 또는 로컬 경로입니다."
  echo " -h | --help      : 도움말을 출력합니다."
}

##
# 원격 저장소에 대상 브랜치가 존재하는지 확인합니다.
#
# @param $1 {string} 확인할 원격 브랜치 이름
#
# @return 원격 브랜치 해시값(존재 시) 또는 빈 문자열(미존재 시)
##
check_remote_branch() {
  local branch_name="$1"
  local result=""
  
  result=$(git ls-remote --heads origin "$branch_name" 2>/dev/null || true)
  echo "$result"
}

##
# 입력된 문자열이 원격 URL 포맷인지 로컬 경로인지 확인하고, 
# 로컬 경로일 경우 디렉토리 존재 유무를 검증합니다.
#
# @param $1 {string} 저장소 경로 또는 URL
#
# @return 검증 실패 시 스크립트 종료, 성공 시 0 리턴
##
validate_repository_path() {
  local repo_path="$1"
  
  if [[ ! "$repo_path" =~ ^(http|https|git|ssh):// ]] && [[ ! "$repo_path" =~ ^[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+: ]]; then
    if [ ! -d "$repo_path" ]; then
      help "입력된 로컬 저장소 경로가 존재하지 않습니다: $repo_path" "$LINENO"
      exit 1
    fi
  fi
  return 0
}

REMOTE_GIT_REPO=""
REMOTE_BRANCH="master"

while [ ! -z "${1:-}" ];
do
  case "$1" in
    -b | --branch)
      shift
      REMOTE_BRANCH="$1"
      ;;
    -r | --repository)
      shift
      REMOTE_GIT_REPO="$1"
      ;;
    -h | --help)
      help "" ""
      exit 0
      ;;
    *)
      ;;
  esac
  shift
done

if [ -z "$REMOTE_GIT_REPO" ] || [ -z "$REMOTE_BRANCH" ];
then
  help "git 저장소 또는 연동할 branch 이름을 확인하시기 바랍니다. git=$REMOTE_GIT_REPO, branch=$REMOTE_BRANCH" "$LINENO"
  exit 1
fi

validate_repository_path "$REMOTE_GIT_REPO"

echo "[ℹ️ 정보] 로컬 저장소를 '$REMOTE_BRANCH' 브랜치로 초기화합니다."
git init -b "$REMOTE_BRANCH"

git remote add origin "$REMOTE_GIT_REPO" 2>/dev/null || git remote set-url origin "$REMOTE_GIT_REPO"

echo "[ℹ️ 정보] 파일 스테이징 및 초기 커밋을 점검합니다."
git add .

# 임시 변수를 통해 상태값을 저장하여 set -e 에 의한 종료 방지
local_changes=0
git diff --staged --quiet || local_changes=1

if [ "$local_changes" -eq 1 ]; then
  git commit -m "최초 작성."
else
  echo "[💡 안내] 새롭게 커밋할 로컬 파일이 없습니다."
fi

echo "[🔍 탐색] 원격 저장소에 '$REMOTE_BRANCH' 브랜치가 있는지 확인 중입니다..."
REMOTE_EXISTS=$(check_remote_branch "$REMOTE_BRANCH")

if [ -z "$REMOTE_EXISTS" ]; then
  echo "[🚀 실행] 원격에 브랜치가 없습니다. 새 브랜치를 생성하고 푸시합니다."
  git push --set-upstream origin "$REMOTE_BRANCH"
else
  echo "[📥 수신] 원격에 '$REMOTE_BRANCH' 브랜치가 이미 존재합니다. 데이터를 가져옵니다."
  git fetch origin "$REMOTE_BRANCH"
  
  echo "[🔄 병합] 원격 브랜치와 로컬 브랜치의 병합(Merge)을 시도합니다."
  set +e
  git merge "origin/$REMOTE_BRANCH" --allow-unrelated-histories -m "Merge remote branch" > .git_merge_out 2>&1
  merge_status=$?
  set -e
  
  if [ "$merge_status" -eq 0 ]; then
    echo "[✅ 성공] 내용 비교 및 병합에 성공했습니다. 푸시를 진행합니다."
    git push --set-upstream origin "$REMOTE_BRANCH"
  else
    echo ""
    echo "================================================================================"
    echo "[⚠️ 주의] 병합 중 충돌(Conflict)이 발생했거나 자동 처리가 실패했습니다."
    echo "[📄 상세 내역]"
    cat .git_merge_out
    echo "--------------------------------------------------------------------------------"
    echo "[🛠️ 조치 방법] 해결을 위해 다음 작업을 순서대로 진행해 주십시오:"
    echo " 1. 충돌이 발생한 파일의 수정 사항을 정리합니다."
    echo " 2. 수정한 파일을 'git add <파일명>'으로 스테이징합니다."
    echo " 3. 'git commit' 명령어로 병합을 완료합니다."
    echo " 4. 'git push' 명령어로 원격 저장소에 반영합니다."
    echo "================================================================================"
  fi
  rm -f .git_merge_out
fi

exit 0
