#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-06
# @desc : support RHEL 8+, Oracle Linux 9+, Ubuntu 20.04+, RockyOS 9+, CentOS 7
# @installation : 
# 1. insert 'source <path>/git-branch-cmd.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-branch-cmd.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

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
    for func in "${FUNCNAME[@]:1}"
    do  
      printf "$formatr" "["$idx"]" "$func"
      ((idx++)) || true
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME [옵션] [작업디렉토리1] [작업디렉토리2] ..."
  echo ""
  echo "[설명]"
  echo "  지정된 여러 경로(절대/상대) 하위의 Git 연동 디렉토리를 탐색하여 브랜치 제어 및 API 작업을 일괄 수행합니다."
  echo "  (작업 디렉토리를 생략하면 현재 경로('.')를 기준으로 탐색합니다.)"
  echo "  API 연동이 필요한 경우, 저장소 도메인 및 소유자(개인/조직) 타입에 따라 독립적인"
  echo "  환경변수(예: PAT_GITHUB_COM_USER_<소유자>, PAT_GITHUB_COM_ORG_<조직명>)를 확인하며,"
  echo "  없을 경우 실행 중 Personal Access Token을 안전하게 입력받아 적용합니다."
  echo ""
  echo "[일반 옵션 (인증 불필요)]"
  echo "      --migrate-branch <기존>:<신규> 기준 브랜치와 마이그레이션 대상 신규 브랜치명 지정"
  echo "      --delete-source            마이그레이션 완료 후 기준 브랜치를 삭제합니다."
  echo "      --delete-branch <브랜치명> 지정된 브랜치를 로컬/원격에서 삭제합니다. (다중 지정 가능)"
  echo "      --find-branch <브랜치명>   지정된 브랜치의 로컬/원격 존재 여부를 검색합니다. (다중 지정 가능)"
  echo ""
  echo "[API 옵션 (인증 필요)]"
  echo "      --protect-branch <브랜치>  원격 저장소의 특정 브랜치를 보호 설정합니다. (다중 지정 가능)"
  echo "      --unprotect-branch <브랜치> 원격 저장소의 특정 브랜치 보호를 해제합니다. (다중 지정 가능)"
  echo "      --show-protected-branch    현재 원격 저장소에서 보호받는 브랜치 목록을 조회합니다."
  echo "      --set-default-branch <브랜치> 원격 저장소의 기본 브랜치를 설정합니다."
  echo "      --show-default-branch      원격 저장소의 기본 브랜치 정보를 조회합니다."
  echo ""
  echo "      --dry-run                  실제로 명령어를 실행하지 않고 실행될 명령어만 출력합니다."
  echo "  -h, --help                     이 도움말을 표시하고 종료합니다."
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

MIGRATE_BRANCH_INPUT=""
SOURCE_BRANCH=""
NEW_BRANCH=""
DELETE_BRANCHES_INPUT=""
FIND_BRANCHES_INPUT=""
PROTECT_BRANCHES_INPUT=""
UNPROTECT_BRANCHES_INPUT=""
SHOW_PROTECTED_BRANCH=0
SET_DEFAULT_BRANCH_INPUT=""
SHOW_DEFAULT_BRANCH=0
TARGET_DIRS=()
DELETE_SOURCE=0
DRY_RUN=0

# 작업 결과 추적용 전역 배열 선언
SUCCESS_REPOS=()
FAIL_REPOS=()
FIND_EXIST_REPOS=()
FIND_MISSING_REPOS=()

# 신규 API 보고서 배열 선언
REPORT_PROTECT=()
REPORT_UNPROTECT=()
REPORT_SHOW_PROTECT=()
REPORT_SET_DEFAULT=()
REPORT_SHOW_DEFAULT=()

# 서비스 도메인별 토큰 관리를 위한 Associative Array 선언
declare -A DOMAIN_PAT_MAP=()
RESOLVED_PAT=""

# 인자 파싱
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help "" ""
      exit 0
      ;;
    --migrate-branch)
      shift; MIGRATE_BRANCH_INPUT="${1:-}" ;;
    --delete-source)
      DELETE_SOURCE=1 ;;
    --delete-branch)
      shift; DELETE_BRANCHES_INPUT="${1:-}" ;;
    --find-branch)
      shift; FIND_BRANCHES_INPUT="${1:-}" ;;
    --protect-branch)
      shift; PROTECT_BRANCHES_INPUT="${1:-}" ;;
    --unprotect-branch)
      shift; UNPROTECT_BRANCHES_INPUT="${1:-}" ;;
    --show-protected-branch)
      SHOW_PROTECTED_BRANCH=1 ;;
    --set-default-branch)
      shift; SET_DEFAULT_BRANCH_INPUT="${1:-}" ;;
    --show-default-branch)
      SHOW_DEFAULT_BRANCH=1 ;;
    --dry-run)
      DRY_RUN=1 ;;
    -*)
      help "지원하지 않는 옵션입니다: $1" "$LINENO"
      exit 1 ;;
    *)
      TARGET_DIRS+=("$1")
      ;;
  esac
  shift
done

# 대상 디렉토리가 하나도 없으면 현재 디렉토리를 기본값으로 설정
if [[ ${#TARGET_DIRS[@]} -eq 0 ]]; then
  TARGET_DIRS=(".")
fi

# 필수 옵션 조합 검증
if [[ -z "$MIGRATE_BRANCH_INPUT" && -z "$DELETE_BRANCHES_INPUT" && -z "$FIND_BRANCHES_INPUT" && -z "$PROTECT_BRANCHES_INPUT" && -z "$UNPROTECT_BRANCHES_INPUT" && $SHOW_PROTECTED_BRANCH -eq 0 && -z "$SET_DEFAULT_BRANCH_INPUT" && $SHOW_DEFAULT_BRANCH -eq 0 ]]; then
  help "마이그레이션, 삭제, 검색 또는 API 제어 옵션 중 하나 이상을 지정해야 합니다." "$LINENO"
  exit 1
fi

# 마이그레이션 옵션 파싱 및 유효성 검사
if [[ -n "$MIGRATE_BRANCH_INPUT" ]]; then
  if [[ "$MIGRATE_BRANCH_INPUT" != *":"* ]]; then
    help "--migrate-branch 옵션의 값은 '<기존브랜치>:<신규브랜치>' 형식이어야 합니다." "$LINENO"
    exit 1
  fi
  SOURCE_BRANCH="${MIGRATE_BRANCH_INPUT%%:*}"
  NEW_BRANCH="${MIGRATE_BRANCH_INPUT#*:}"
  if [[ -z "$SOURCE_BRANCH" || -z "$NEW_BRANCH" ]]; then
    help "--migrate-branch 옵션의 값이 올바르지 않습니다." "$LINENO"
    exit 1
  fi
fi

# 모든 입력된 디렉토리에 대한 유효성(존재 여부) 사전 검증
for target_dir in "${TARGET_DIRS[@]}"; do
  if [[ ! -d "$target_dir" ]]; then
    help "입력한 작업 대상이 유효한 디렉토리가 아닙니다: $target_dir" "$LINENO"
    exit 1
  fi
done

##
# 필수 CLI 명령어(gh, glab)의 설치 여부를 확인하고, 없을 경우 패키지 관리자로 설치합니다.
#
# @param $1 {string} 확인할 CLI 명령어 (gh 또는 glab)
#
# @return 설치 실패 시 1 반환 후 스크립트 종료
##
ensure_cli_installed() {
  local cli_cmd="$1"
  if ! command -v "$cli_cmd" >/dev/null 2>&1; then
    echo "  ⚠️ '$cli_cmd' 명령어가 시스템에 설치되어 있지 않습니다."
    echo "  ⏳ 운영체제 패키지 도구(apt, dnf 등)를 이용하여 '$cli_cmd' 자동 설치를 시도합니다..."
    
    if command -v apt >/dev/null 2>&1; then
      sudo apt update -y >/dev/null 2>&1 || true
      sudo apt install -y "$cli_cmd" || { echo "  ❌ '$cli_cmd' 설치에 실패했습니다. 수동으로 설치해 주세요."; exit 1; }
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y "$cli_cmd" || { echo "  ❌ '$cli_cmd' 설치에 실패했습니다. 수동으로 설치해 주세요."; exit 1; }
    else
      echo "  ❌ 지원하는 패키지 관리자(apt, dnf)를 찾을 수 없습니다. '$cli_cmd'를 수동으로 설치해 주세요."
      exit 1
    fi
    echo "  ✅ '$cli_cmd' 명령어 설치가 완료되었습니다."
  fi
}

##
# GitHub / GitLab 연동을 위한 API 모듈을 동적으로 다운로드 및 권한 부여합니다.
#
# @return 실패 시 1 반환 후 스크립트 종료
##
ensure_api_modules() {
  local script_dir
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
  
  local gh_mod="git-branch-module-github-api.sh"
  local gh_url="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/github/$gh_mod"
  
  local gl_mod="git-branch-module-gitlab-api.sh"
  local gl_url="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/gitlab/$gl_mod"

  local mod_info
  for mod_info in "$gh_mod|$gh_url" "$gl_mod|$gl_url"; do
    local mod_name="${mod_info%%|*}"
    local mod_url="${mod_info##*|}"
    local target_path="$script_dir/$mod_name"
    
    if [[ ! -f "$target_path" ]]; then
      echo "  📥 외부 API 모듈 자동 다운로드 중: $mod_name"
      local tmp_dir
      tmp_dir=$(mktemp -d)
      if curl -sSL -f -o "$tmp_dir/$mod_name" "$mod_url" 2>/dev/null || wget -qO "$tmp_dir/$mod_name" "$mod_url" 2>/dev/null; then
        cp "$tmp_dir/$mod_name" "$target_path"
        chmod +x "$target_path"
        echo "  ✅ 모듈 확보 및 권한 부여 완료: $target_path"
      else
        echo "  ❌ 모듈 다운로드 실패: 네트워크 또는 URL을 확인해 주세요."
        rm -rf "$tmp_dir"
        exit 1
      fi
      rm -rf "$tmp_dir"
    fi
  done
}

##
# 대상 도메인별 Personal Access Token(PAT)을 동적 맵핑하고 환경을 검증합니다.
#
# @param $1 {string} 대상 원격 저장소 full domain (예: github.com)
# @param $2 {string} 대상 원격 저장소 URL (파싱용)
#
# @return 토큰 존재 시 0 반환, 전역 변수 RESOLVED_PAT 할당
##
ensure_pat_for_domain() {
  local domain="$1"
  local remote_url="$2"
  local env_var_name=""
  local display_target="$domain"
  
  local domain_upper
  domain_upper=$(echo "$domain" | tr 'a-z' 'A-Z' | sed -E 's/[^A-Z0-9]/_/g')
  
  if [[ "$domain" == *"github.com"* ]]; then
    local owner_repo=""
    if [[ "$remote_url" == http* ]]; then
      owner_repo=$(echo "$remote_url" | sed -E 's|^https?://[^/]+/||; s|\.git$||')
    elif [[ "$remote_url" == git@* ]]; then
      owner_repo=$(echo "$remote_url" | sed -E 's|^git@[^:]+:||; s|\.git$||')
    elif [[ "$remote_url" == ssh://* ]]; then
      owner_repo=$(echo "$remote_url" | sed -E 's|^ssh://[^/]+/||; s|\.git$||')
    fi
    
    local account_name="${owner_repo%%/*}"
    local account_type="User"
    
    if [[ -n "$account_name" ]]; then
      local api_res
      api_res=$(curl -sL "https://api.github.com/users/${account_name}" 2>/dev/null || true)
      local extracted_type
      extracted_type=$(echo "$api_res" | grep -o '"type": *"[^"]*"' | head -n 1 | sed -E 's/.*"type": *"([^"]*)".*/\1/' || true)
      if [[ "$extracted_type" == "Organization" ]]; then
        account_type="Organization"
      fi
    fi
    
    local account_upper
    account_upper=$(echo "$account_name" | tr 'a-z' 'A-Z' | sed -E 's/[^A-Z0-9]/_/g')
    
    if [[ "$account_type" == "Organization" ]]; then
      env_var_name="PAT_${domain_upper}_ORG_${account_upper}"
      display_target="$domain - 조직: $account_name"
    else
      env_var_name="PAT_${domain_upper}_USER_${account_upper}"
      display_target="$domain - 개인: $account_name"
    fi
  else
    env_var_name="PAT_${domain_upper}"
  fi

  if [[ -n "${DOMAIN_PAT_MAP[$env_var_name]:-}" ]]; then
    RESOLVED_PAT="${DOMAIN_PAT_MAP[$env_var_name]}"
    return 0
  fi

  local env_val=""
  eval env_val="\${$env_var_name:-}"

  if [[ -n "$env_val" ]]; then
    DOMAIN_PAT_MAP["$env_var_name"]="$env_val"
    RESOLVED_PAT="$env_val"
    return 0
  fi

  local user_pat=""
  echo "🔒 [보안] 인증 정보가 필요한 API 작업이 포함되어 있습니다."
  read -r -s -p "👉 API 연동($display_target)을 위한 Personal Access Token을 입력하세요: " user_pat </dev/tty
  echo ""

  if [[ -z "$user_pat" ]]; then
    help "인증 토큰이 입력되지 않아 API 작업을 진행할 수 없습니다. ($display_target)" "$LINENO"
    exit 1
  fi

  export "$env_var_name"="$user_pat"
  DOMAIN_PAT_MAP["$env_var_name"]="$user_pat"
  RESOLVED_PAT="$user_pat"
}

# API 관련 작업이 요청되었는지 사전 모듈 다운로드만 실행
GLOBAL_API_REQUIRED=0
if [[ -n "$PROTECT_BRANCHES_INPUT" || -n "$UNPROTECT_BRANCHES_INPUT" || $SHOW_PROTECTED_BRANCH -eq 1 || -n "$SET_DEFAULT_BRANCH_INPUT" || $SHOW_DEFAULT_BRANCH -eq 1 ]]; then
  GLOBAL_API_REQUIRED=1
  ensure_api_modules
fi

##
# Git 명령어의 에러 출력을 분석하여 실패 원인을 한국어로 반환합니다.
#
# @param $1 {string} "local" 또는 "remote" (분석 대상 스코프)
# @param $2 {string} Git 에러 출력 메시지
#
# @return 상세 에러 원인 문자열 반환
##
parse_git_delete_error() {
  local scope="$1"
  local err_msg="$2"
  
  if [[ "$scope" == "local" ]]; then
    if [[ "$err_msg" == *"checked out"* ]]; then
      echo "현재 선택된(checked out) 상태"
    elif [[ "$err_msg" == *"not found"* ]]; then
      echo "미존재"
    elif [[ "$err_msg" == *"not fully merged"* ]]; then
      echo "병합 미완료 (강제 삭제 필요)"
    else
      echo "알 수 없는 시스템 권한/오류"
    fi
  elif [[ "$scope" == "remote" ]]; then
    if [[ "$err_msg" == *"does not exist"* || "$err_msg" == *"not found"* ]]; then
      echo "미존재"
    elif [[ "$err_msg" == *"default branch"* || "$err_msg" == *"current branch prohibited"* || "$err_msg" == *"protected"* ]]; then
      echo "기본/보호 브랜치 지정됨"
    elif [[ "$err_msg" == *"403"* || "$err_msg" == *"Permission"* || "$err_msg" == *"denied"* || "$err_msg" == *"rights"* ]]; then
      echo "권한 없음"
    else
      echo "알 수 없는 네트워크/권한 오류"
    fi
  fi
}

##
# 단일 Git 연동 디렉토리에 대해 작업을 수행합니다.
#
# @param $1 {string} 처리할 Git 연동 디렉토리 경로
#
# @return (터미널 진행 로그 출력 및 전역 배열에 결과 추가)
##
process_repo() {
  local repo_path="$1"
  local step_failed=0
  local fail_reason=""
  
  local abs_path
  abs_path=$(cd "$repo_path" >/dev/null 2>&1 && pwd || echo "$repo_path")
  local project_name=""
  local remote_url=""
  
  remote_url=$(git -C "$abs_path" config --get remote.origin.url 2>/dev/null || true)
  if [[ -n "$remote_url" ]]; then
    project_name=$(basename "$remote_url" .git)
  else
    project_name=$(basename "$abs_path")
  fi
  
  local display_path="${project_name}"
  
  echo "================================================================================"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "🚀 [Git 연동 디렉토리 발견] $display_path (가상 실행 모드)"
  else
    echo "🚀 [Git 연동 디렉토리 발견] $display_path"
  fi
  
  if ! pushd "$repo_path" > /dev/null 2>&1; then
    fail_reason="디렉토리 접근 권한이 없습니다."
    echo "  ⚠️ $fail_reason"
    FAIL_REPOS+=("${display_path}::::${fail_reason}")
    return 0
  fi

  # --- 기존 기능: 마이그레이션 ---
  if [[ -n "$SOURCE_BRANCH" && -n "$NEW_BRANCH" && $step_failed -eq 0 ]]; then
    if ! git rev-parse --verify "$SOURCE_BRANCH" >/dev/null 2>&1; then
      step_failed=1; fail_reason="'$SOURCE_BRANCH' 로컬 미존재"
    else
      echo "  📦 1. '$SOURCE_BRANCH' 브랜치 전환"
      if [[ $DRY_RUN -eq 1 ]]; then echo "    [DRY-RUN] git checkout \"$SOURCE_BRANCH\""; else git checkout "$SOURCE_BRANCH" >/dev/null 2>&1 || step_failed=1; fi
      
      echo "  📥 2. 최신 변경사항 동기화"
      if [[ $DRY_RUN -eq 1 ]]; then echo "    [DRY-RUN] git pull"; else git pull >/dev/null 2>&1 || step_failed=1; fi
      
      echo "  🌱 3. '$NEW_BRANCH' 브랜치 생성"
      if [[ $DRY_RUN -eq 1 ]]; then echo "    [DRY-RUN] git branch \"$NEW_BRANCH\" (존재하지 않을 경우)"; else git rev-parse --verify "$NEW_BRANCH" >/dev/null 2>&1 || git branch "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1; fi
      
      echo "  🔄 4. '$NEW_BRANCH' 브랜치 전환"
      if [[ $DRY_RUN -eq 1 ]]; then echo "    [DRY-RUN] git checkout \"$NEW_BRANCH\""; else git checkout "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1; fi
      
      echo "  📤 5. 원격 저장소에 업로드"
      if [[ $DRY_RUN -eq 1 ]]; then echo "    [DRY-RUN] git push --set-upstream origin \"$NEW_BRANCH\""; else git push --set-upstream origin "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1; fi
      
      if [[ $step_failed -eq 0 && $DELETE_SOURCE -eq 1 ]]; then
        echo "  🗑️ 6. 기준 브랜치('$SOURCE_BRANCH') 삭제"
        if [[ $DRY_RUN -eq 1 ]]; then
          echo "    [DRY-RUN] git branch -d \"$SOURCE_BRANCH\""
          echo "    [DRY-RUN] git push origin --delete \"$SOURCE_BRANCH\""
        else
          git branch -d "$SOURCE_BRANCH" >/dev/null 2>&1 || true
          git push origin --delete "$SOURCE_BRANCH" >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi

  # --- 기존 기능: 브랜치 삭제 ---
  if [[ -n "$DELETE_BRANCHES_INPUT" && $step_failed -eq 0 ]]; then
    local del_branch_arr=(); local b
    IFS=',' read -ra ADDR <<< "$DELETE_BRANCHES_INPUT"
    for b in "${ADDR[@]}"; do
      b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
      [[ -n "$b" ]] && del_branch_arr+=("$b")
    done
    if [[ ${#del_branch_arr[@]} -gt 0 ]]; then
      echo "  🔥 [작업] 지정된 브랜치 다중 삭제"
      for b in "${del_branch_arr[@]}"; do
        echo "    - 대상: '$b'"
        if [[ $DRY_RUN -eq 1 ]]; then
          echo "      [DRY-RUN] git branch -d \"$b\""
          echo "      [DRY-RUN] git push origin --delete \"$b\""
        else
          local local_status=0; local remote_status=0
          local local_out=""; local remote_out=""
          
          local_out=$(git branch -d "$b" 2>&1) || local_status=$?
          if [[ $local_status -eq 0 ]]; then echo "      ✅ 로컬 '$b' 브랜치 삭제 완료"; else echo "      ℹ️ 로컬 '$b' 브랜치 미존재/삭제 불가"; fi
          
          local ls_remote_err=""; local ls_remote_status=0
          ls_remote_err=$(git ls-remote --exit-code --heads origin "$b" 2>&1 >/dev/null) || ls_remote_status=$?

          if [[ $ls_remote_status -eq 0 ]]; then
            remote_out=$(git push origin --delete "$b" 2>&1) || remote_status=$?
            if [[ $remote_status -eq 0 ]]; then echo "      ✅ 원격 '$b' 브랜치 삭제 완료"; else echo "      ℹ️ 원격 '$b' 브랜치 삭제 실패"; fi
          elif [[ $ls_remote_status -eq 2 ]]; then
            remote_status=1; remote_out="not found"
            echo "      ℹ️ 원격 '$b' 브랜치 미존재 (삭제 생략)"
          else
            remote_status=$ls_remote_status; remote_out="$ls_remote_err"
            echo "      ℹ️ 원격 저장소 접근 실패"
          fi
          
          if [[ $local_status -ne 0 && $remote_status -ne 0 ]]; then
            local loc_reason; local rem_reason
            loc_reason=$(parse_git_delete_error "local" "$local_out")
            rem_reason=$(parse_git_delete_error "remote" "$remote_out")
            if [[ "$loc_reason" == "미존재" && "$rem_reason" == "미존재" ]]; then
              fail_reason="'$b' 브랜치 미존재 (로컬 및 원격)"
            else
              fail_reason="'$b' 삭제 불가 (로컬: $loc_reason | 원격: $rem_reason)"
            fi
            echo "      ⚠️ $fail_reason"; step_failed=1; break
          fi
        fi
      done
    fi
  fi

  # --- 기존 기능: 브랜치 검색 (Read-only는 DRY_RUN 무관하게 실행) ---
  if [[ -n "$FIND_BRANCHES_INPUT" && $step_failed -eq 0 ]]; then
    local find_branch_arr=(); local b
    IFS=',' read -ra ADDR <<< "$FIND_BRANCHES_INPUT"
    for b in "${ADDR[@]}"; do
      b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
      [[ -n "$b" ]] && find_branch_arr+=("$b")
    done
    if [[ ${#find_branch_arr[@]} -gt 0 ]]; then
      echo "  🔍 [작업] 브랜치 존재 여부 검색"
      local repo_found_count=0; local repo_branch_details=()
      for b in "${find_branch_arr[@]}"; do
        local is_local="X"; local is_remote="X"
        git show-ref --verify --quiet "refs/heads/$b" 2>/dev/null && is_local="O"
        git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1 && is_remote="O"
        printf "    - 브랜치: %-20s | 로컬: %s | 원격: %s\n" "'$b'" "$is_local" "$is_remote"
        if [[ "$is_local" == "O" || "$is_remote" == "O" ]]; then
          repo_found_count=$((repo_found_count + 1))
          repo_branch_details+=("${b}::::${is_local}::::${is_remote}")
        fi
      done
      if [[ $repo_found_count -gt 0 ]]; then
        local details_str=""; local d
        for d in "${repo_branch_details[@]}"; do details_str="${details_str}${d}@@"; done
        FIND_EXIST_REPOS+=("${display_path}####${details_str}")
      else
        FIND_MISSING_REPOS+=("$display_path")
      fi
    fi
  fi

  # ==========================================
  # 신규 기능: 원격 API 연동 블록 (보호 / 기본 브랜치)
  # ==========================================
  if [[ $GLOBAL_API_REQUIRED -eq 1 && $step_failed -eq 0 ]]; then
    local provider=""
    
    local repo_host=""
    local repo_uri=""
    if [[ "$remote_url" == http* ]]; then
      repo_uri=$(echo "$remote_url" | sed -E 's|^(https?://[^/]+).*|\1|')
      repo_host=$(echo "$repo_uri" | sed -E 's|^https?://||; s|^.*@||')
    elif [[ "$remote_url" == git@* ]]; then
      repo_host=$(echo "$remote_url" | sed -E 's|^git@||; s|:.*$||')
      repo_uri="https://$repo_host"
    elif [[ "$remote_url" == ssh://* ]]; then
      repo_host=$(echo "$remote_url" | sed -E 's|^ssh://||; s|/.*$||; s|^.*@||; s|:.*$||')
      repo_uri="https://$repo_host"
    fi
    
    if [[ "$remote_url" == *"github.com"* ]]; then
      provider="github"
      ensure_cli_installed "gh"
    elif [[ "$remote_url" == *"gitlab"* ]]; then
      provider="gitlab"
      ensure_cli_installed "glab"
    else
      echo "  ⚠️ GitHub 또는 GitLab 원격 저장소를 찾을 수 없어 API 작업을 건너뜁니다."
    fi

    if [[ -n "$repo_host" ]]; then
      if [[ "$provider" == "gitlab" || "$provider" == "github" ]]; then
        ensure_pat_for_domain "$repo_host" "$remote_url"
        
        if [[ "$provider" == "gitlab" ]]; then
          export GITLAB_HOST="$repo_host"
          export GITLAB_URI="$repo_uri"
          export GITLAB_TOKEN="$RESOLVED_PAT"
        elif [[ "$provider" == "github" ]]; then
          export GH_HOST="$repo_host"
          export GITHUB_TOKEN="$RESOLVED_PAT"
        fi
      fi
    fi

    if [[ -n "$provider" ]]; then
      local script_dir
      script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
      
      if [[ -f "$script_dir/git-branch-module-${provider}-api.sh" ]]; then
        source "$script_dir/git-branch-module-${provider}-api.sh"
      else
        echo "  ❌ 연동 모듈을 찾을 수 없습니다: git-branch-module-${provider}-api.sh"
        step_failed=1
      fi
      
      if [[ $step_failed -eq 0 ]]; then
        
        # 1. 보호 설정 (Write 작업: DRY_RUN 반영)
        if [[ -n "$PROTECT_BRANCHES_INPUT" ]]; then
          echo "  🔒 [API 작업] 브랜치 보호 설정"
          local protect_arr=(); local b
          IFS=',' read -ra ADDR <<< "$PROTECT_BRANCHES_INPUT"
          for b in "${ADDR[@]}"; do
            b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [[ -n "$b" ]] && protect_arr+=("$b")
          done
          
          local p_details=""
          for b in "${protect_arr[@]}"; do
            if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
              if [[ $DRY_RUN -eq 1 ]]; then
                echo "    [DRY-RUN] api_${provider}_protect_branch \"$b\""
                echo "    ✅ 보호 설정 완료: '$b' (가상 실행)"
                p_details+="${b}::::보호 설정 완료 (가상)@@"
              else
                local api_res
                api_res=$("api_${provider}_protect_branch" "$b" || true)
                if [[ "$api_res" == ERROR:* ]]; then
                  local err_msg="${api_res#ERROR:}"
                  err_msg=$(echo "$err_msg" | head -n 1 | tr '\n' ' ' | sed 's/ $//')
                  echo "    ❌ 보호 설정 실패: '$b' ($err_msg)"
                  p_details+="${b}::::보호 실패 ($err_msg)@@"
                else
                  echo "    ✅ 보호 설정 완료: '$b'"
                  p_details+="${b}::::보호 설정 완료@@"
                fi
              fi
            else
              echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 보호 설정을 생략합니다."
              p_details+="${b}::::원격 브랜치 미존재 (생략)@@"
            fi
          done
          REPORT_PROTECT+=("${display_path}####${p_details}")
        fi
        
        # 2. 보호 해제 (Write 작업: DRY_RUN 반영)
        if [[ -n "$UNPROTECT_BRANCHES_INPUT" ]]; then
          echo "  🔓 [API 작업] 브랜치 보호 해제"
          local unprotect_arr=(); local b
          IFS=',' read -ra ADDR <<< "$UNPROTECT_BRANCHES_INPUT"
          for b in "${ADDR[@]}"; do
            b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [[ -n "$b" ]] && unprotect_arr+=("$b")
          done
          
          local up_details=""
          for b in "${unprotect_arr[@]}"; do
            if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
              if [[ $DRY_RUN -eq 1 ]]; then
                echo "    [DRY-RUN] api_${provider}_unprotect_branch \"$b\""
                echo "    ✅ 보호 해제 완료: '$b' (가상 실행)"
                up_details+="${b}::::보호 해제 완료 (가상)@@"
              else
                local api_res
                api_res=$("api_${provider}_unprotect_branch" "$b" || true)
                if [[ "$api_res" == ERROR:* ]]; then
                  local err_msg="${api_res#ERROR:}"
                  err_msg=$(echo "$err_msg" | head -n 1 | tr '\n' ' ' | sed 's/ $//')
                  echo "    ❌ 보호 해제 실패: '$b' ($err_msg)"
                  up_details+="${b}::::보호 해제 실패 ($err_msg)@@"
                else
                  echo "    ✅ 보호 해제 완료: '$b'"
                  up_details+="${b}::::보호 해제 완료@@"
                fi
              fi
            else
              echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 해제를 생략합니다."
              up_details+="${b}::::원격 브랜치 미존재 (생략)@@"
            fi
          done
          REPORT_UNPROTECT+=("${display_path}####${up_details}")
        fi
        
        # 3. 보호 목록 조회 (Read-only는 DRY_RUN 무관하게 실행)
        if [[ $SHOW_PROTECTED_BRANCH -eq 1 ]]; then
          echo "  🛡️ [API 작업] 보호 브랜치 목록 조회"
          local p_list
          p_list=$("api_${provider}_show_protected" || true)
          local shp_details=""
          if [[ "$p_list" == ERROR:* ]]; then
            local err_msg="${p_list#ERROR:}"
            err_msg=$(echo "$err_msg" | head -n 1 | tr '\n' ' ' | sed 's/ $//')
            echo "    ❌ 보호 브랜치 목록 조회 실패 ($err_msg)"
            shp_details="(정보 없음)::::조회 실패 ($err_msg)@@"
          elif [[ -n "$p_list" ]]; then
            while read -r line; do
              [[ -n "$line" ]] && shp_details+="${line}::::보호 중@@"
              echo "    - $line"
            done <<< "$p_list"
          else
            echo "    ℹ️ 보호 설정된 브랜치가 없습니다."
            shp_details="(정보 없음)::::보호된 브랜치 없음@@"
          fi
          REPORT_SHOW_PROTECT+=("${display_path}####${shp_details}")
        fi
        
        # 4. 기본 브랜치 설정 (Write 작업: DRY_RUN 반영)
        if [[ -n "$SET_DEFAULT_BRANCH_INPUT" ]]; then
          echo "  ⭐ [API 작업] 기본 브랜치 설정"
          local b="$SET_DEFAULT_BRANCH_INPUT"
          local sd_details=""
          if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
            if [[ $DRY_RUN -eq 1 ]]; then
              echo "    [DRY-RUN] api_${provider}_set_default \"$b\""
              echo "    ✅ 기본 브랜치가 '$b' 로 설정되었습니다. (가상 실행)"
              sd_details="${b}::::기본 브랜치 설정 완료 (가상)@@"
            else
              local api_res
              api_res=$("api_${provider}_set_default" "$b" || true)
              if [[ "$api_res" == ERROR:* ]]; then
                local err_msg="${api_res#ERROR:}"
                err_msg=$(echo "$err_msg" | head -n 1 | tr '\n' ' ' | sed 's/ $//')
                echo "    ❌ 기본 브랜치 설정 실패: '$b' ($err_msg)"
                sd_details="${b}::::기본 브랜치 설정 실패 ($err_msg)@@"
              else
                echo "    ✅ 기본 브랜치가 '$b' 로 설정되었습니다."
                sd_details="${b}::::기본 브랜치 설정 완료@@"
              fi
            fi
          else
            echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 설정을 중단합니다."
            step_failed=1
            fail_reason="기본 브랜치 설정 대상 미존재"
            sd_details="${b}::::원격 브랜치 미존재 (설정 중단)@@"
          fi
          REPORT_SET_DEFAULT+=("${display_path}####${sd_details}")
        fi
        
        # 5. 기본 브랜치 정보 제공 (Read-only는 DRY_RUN 무관하게 실행)
        if [[ $SHOW_DEFAULT_BRANCH -eq 1 ]]; then
          echo "  ℹ️ [API 작업] 기본 브랜치 정보 제공"
          local d_branch
          d_branch=$("api_${provider}_show_default" || true)
          local shd_details=""
          if [[ "$d_branch" == ERROR:* ]]; then
            local err_msg="${d_branch#ERROR:}"
            err_msg=$(echo "$err_msg" | head -n 1 | tr '\n' ' ' | sed 's/ $//')
            echo "    ❌ 현재 기본 브랜치: (조회 실패 - $err_msg)"
            shd_details="(정보 없음)::::조회 실패 ($err_msg)@@"
          elif [[ -z "$d_branch" ]]; then
            echo "    👉 현재 기본 브랜치: (설정된 브랜치 없음)"
            shd_details="(정보 없음)::::기본 브랜치 미설정@@"
          else
            echo "    👉 현재 기본 브랜치: '$d_branch'"
            shd_details="${d_branch}::::기본 브랜치@@"
          fi
          REPORT_SHOW_DEFAULT+=("${display_path}####${shd_details}")
        fi
      fi
    fi
  fi

  popd > /dev/null

  if [[ $step_failed -eq 0 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "  ✅ 작업 완료: $display_path (가상 실행 완료)"
      SUCCESS_REPOS+=("$display_path (가상 실행 완료)")
    else
      echo "  ✅ 작업 완료: $display_path"
      SUCCESS_REPOS+=("$display_path")
    fi
  else
    echo "  ❌ 작업 실패: $display_path"
    FAIL_REPOS+=("${display_path}::::${fail_reason}")
  fi
  echo "================================================================================"
}

##
# 지정된 디렉토리를 재귀적으로 탐색합니다.
#
# @param $1 {string} 디렉토리 경로
#
# @return (조건 충족 시 process_repo 호출)
##
search_git_directories() {
  local current_dir="$1"
  if [[ -d "$current_dir/.git" ]]; then
    process_repo "$current_dir"
  else
    local sub_dir
    while IFS= read -r -d '' sub_dir; do
      search_git_directories "$sub_dir"
    done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
  fi
}

##
# API 작업 결과를 동적 패딩을 적용하여 출력합니다.
#
# @param $1 {string} 출력할 보고서 제목
# @param $2 {string} 참조할 결과 배열의 이름
##
print_api_report() {
  local title="$1"
  local array_name="$2"
  local -n data_arr="$array_name"
  
  if [[ ${#data_arr[@]} -gt 0 ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "✅ ${title} (${#data_arr[@]} 개):"
    
    local max_len=0
    local item
    for item in "${data_arr[@]}"; do
      local r_path="${item%%####*}"
      if [[ ${#r_path} -gt $max_len ]]; then
        max_len=${#r_path}
      fi
    done
    
    for item in "${data_arr[@]}"; do
      local r_path="${item%%####*}"
      local details_str="${item##*####}"
      local first=1
      
      local details_arr
      IFS='@@' read -ra details_arr <<< "$details_str"
      local d
      for d in "${details_arr[@]}"; do
        if [[ -z "$d" ]]; then continue; fi
        local b_name="${d%%::::*}"
        local b_stat="${d##*::::}"
        
        if [[ $first -eq 1 ]]; then
          if [[ -z "$b_name" || "$b_name" == "(정보 없음)" ]]; then
            printf "  - %-${max_len}s : %s\n" "$r_path" "$b_stat"
          else
            printf "  - %-${max_len}s : %-15s (%s)\n" "$r_path" "'$b_name'" "$b_stat"
          fi
          first=0
        else
          if [[ -z "$b_name" || "$b_name" == "(정보 없음)" ]]; then
            printf "    %-${max_len}s : %s\n" "" "$b_stat"
          else
            printf "    %-${max_len}s : %-15s (%s)\n" "" "'$b_name'" "$b_stat"
          fi
        fi
      done
    done
  fi
}

##
# 스크립트 실행 결과를 종합하여 보고서 형태로 출력합니다.
#
# @param 없음
#
# @return (성공 및 실패 내역 요약 출력)
##
print_report() {
  local total_repos=$(( ${#SUCCESS_REPOS[@]} + ${#FAIL_REPOS[@]} ))

  echo ""
  echo "📊 [작업 완료 보고서] - 총 $total_repos 개"

  # [브랜치 검색(find-branch)] 기능 단독 처리용 보고서 출력 블록
  if [[ -n "$FIND_BRANCHES_INPUT" ]]; then
    local find_branch_arr=()
    local b
    IFS=',' read -ra ADDR <<< "$FIND_BRANCHES_INPUT"
    for b in "${ADDR[@]}"; do
      b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
      if [[ -n "$b" ]]; then
        find_branch_arr+=("$b")
      fi
    done
    
    local display_names=""
    for b in "${find_branch_arr[@]}"; do
      if [[ -z "$display_names" ]]; then
        display_names="$b"
      else
        display_names="$display_names, $b"
      fi
    done

    if [[ ${#FIND_EXIST_REPOS[@]} -gt 0 ]]; then
      echo "--------------------------------------------------------------------------------"
      echo "✅ '${display_names}' 존재 프로젝트 목록 (${#FIND_EXIST_REPOS[@]} 개):"
      
      local max_len=0
      local item
      for item in "${FIND_EXIST_REPOS[@]}"; do
        local r_path="${item%%####*}"
        if [[ ${#r_path} -gt $max_len ]]; then
          max_len=${#r_path}
        fi
      done
      
      for item in "${FIND_EXIST_REPOS[@]}"; do
        local r_path="${item%%####*}"
        local details_str="${item##*####}"
        local first=1
        
        local details_arr
        IFS='@@' read -ra details_arr <<< "$details_str"
        local d
        for d in "${details_arr[@]}"; do
          if [[ -z "$d" ]]; then continue; fi
          local b_name="${d%%::::*}"
          local rem="${d#*::::}"
          local loc="${rem%%::::*}"
          local rmt="${rem##*::::}"
          
          if [[ $first -eq 1 ]]; then
            printf "  - %-${max_len}s : %-4s (로컬: %s | 원격: %s)\n" "$r_path" "$b_name" "$loc" "$rmt"
            first=0
          else
            printf "    %-${max_len}s : %-4s (로컬: %s | 원격: %s)\n" "" "$b_name" "$loc" "$rmt"
          fi
        done
      done
    fi

    if [[ ${#FIND_MISSING_REPOS[@]} -gt 0 ]]; then
      echo "--------------------------------------------------------------------------------"
      echo "❌ '${display_names}' 미존재 프로젝트 목록 (${#FIND_MISSING_REPOS[@]} 개):"
      local r_path
      for r_path in "${FIND_MISSING_REPOS[@]}"; do
        echo "  - $r_path"
      done
    fi
  fi

  # API 신규 기능들의 결과 출력
  print_api_report "'protect-branch' 작업 결과" REPORT_PROTECT
  print_api_report "'unprotect-branch' 작업 결과" REPORT_UNPROTECT
  print_api_report "'show-protected-branch' 조회 결과" REPORT_SHOW_PROTECT
  print_api_report "'set-default-branch' 작업 결과" REPORT_SET_DEFAULT
  print_api_report "'show-default-branch' 조회 결과" REPORT_SHOW_DEFAULT

  # 순수 조회 전용 기능들만 실행된 경우 마이그레이션 성공/실패 목록은 생략
  if [[ -z "$MIGRATE_BRANCH_INPUT" && -z "$DELETE_BRANCHES_INPUT" && -z "$PROTECT_BRANCHES_INPUT" && -z "$UNPROTECT_BRANCHES_INPUT" && -z "$SET_DEFAULT_BRANCH_INPUT" ]]; then
    echo "--------------------------------------------------------------------------------"
    return 0
  fi

  # 기존 마이그레이션, 삭제 및 API 작업 로직에 대한 보고서 보존 영역
  if [[ ${#SUCCESS_REPOS[@]} -gt 0 ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "✅ 전체 성공 프로젝트 목록 (${#SUCCESS_REPOS[@]} 개):"
    local repo
    for repo in "${SUCCESS_REPOS[@]}"; do
      echo "  - $repo"
    done
    echo ""
  fi

  if [[ ${#FAIL_REPOS[@]} -gt 0 ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "❌ 전체 실패 프로젝트 목록 (${#FAIL_REPOS[@]} 개):"
    local max_len=0
    local item
    local path
    local reason

    for item in "${FAIL_REPOS[@]}"; do
      path="${item%%::::*}"
      if [[ ${#path} -gt $max_len ]]; then
        max_len=${#path}
      fi
    done

    for item in "${FAIL_REPOS[@]}"; do
      path="${item%%::::*}"
      reason="${item##*::::}"
      printf "  - %-${max_len}s : %s\n" "$path" "$reason"
    done
  fi
  echo "--------------------------------------------------------------------------------"
}

if [[ -n "$SOURCE_BRANCH" && -n "$NEW_BRANCH" ]]; then
  echo "👉 마이그레이션 전략: [$SOURCE_BRANCH] -> [$NEW_BRANCH]"
fi

# 모든 대상 디렉토리에 대해 루프 수행 (다중 디렉토리 파싱)
for target_dir in "${TARGET_DIRS[@]}"; do
  echo "🔍 대상 디렉토리('$target_dir') 하위의 Git 저장소 탐색을 시작합니다..."
  search_git_directories "$target_dir"
done

print_report

echo ""
echo "🏁 모든 처리가 완료되었습니다."
exit 0
