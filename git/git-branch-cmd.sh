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
  echo "사용법: ./$FILENAME [옵션] [작업디렉토리]"
  echo ""
  echo "[설명]"
  echo "  지정된 경로 하위의 Git 연동 디렉토리를 탐색하여 브랜치 제어 및 API 작업을 일괄 수행합니다."
  echo "  (작업 디렉토리를 생략하면 현재 경로('.')를 기준으로 탐색합니다.)"
  echo ""
  echo "[옵션 (Options)]"
  echo "      --migrate-branch <기존>:<신규> 기준 브랜치와 마이그레이션 대상 신규 브랜치명 지정"
  echo "      --delete-source            마이그레이션 완료 후 기준 브랜치를 삭제합니다."
  echo "      --delete-branch <브랜치명> 지정된 브랜치를 로컬/원격에서 삭제합니다. (다중 지정 가능)"
  echo "      --find-branch <브랜치명>   지정된 브랜치의 로컬/원격 존재 여부를 검색합니다. (다중 지정 가능)"
  echo "      --protect-branch <브랜치>  원격 저장소의 특정 브랜치를 보호 설정합니다. (다중 지정 가능)"
  echo "      --unprotect-branch <브랜치> 원격 저장소의 특정 브랜치 보호를 해제합니다. (다중 지정 가능)"
  echo "      --show-protected-branch    현재 원격 저장소에서 보호받는 브랜치 목록을 조회합니다."
  echo "      --set-default-branch <브랜치> 원격 저장소의 기본 브랜치를 설정합니다."
  echo "      --show-default-branch      원격 저장소의 기본 브랜치 정보를 조회합니다."
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
TARGET_DIR=""
DELETE_SOURCE=0
DRY_RUN=0

# 작업 결과 추적용 전역 배열 선언
SUCCESS_REPOS=()
FAIL_REPOS=()
FIND_EXIST_REPOS=()
FIND_MISSING_REPOS=()

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
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        help "작업 디렉토리는 하나만 지정할 수 있습니다: $1" "$LINENO"
        exit 1
      fi
      ;;
  esac
  shift
done

TARGET_DIR="${TARGET_DIR:-.}"

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

if [[ ! -d "$TARGET_DIR" ]]; then
  help "입력한 작업 대상이 유효한 디렉토리가 아닙니다: $TARGET_DIR" "$LINENO"
  exit 1
fi

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

# API 관련 작업이 요청되었는지 확인하고 모듈 준비
if [[ -n "$PROTECT_BRANCHES_INPUT" || -n "$UNPROTECT_BRANCHES_INPUT" || $SHOW_PROTECTED_BRANCH -eq 1 || -n "$SET_DEFAULT_BRANCH_INPUT" || $SHOW_DEFAULT_BRANCH -eq 1 ]]; then
  ensure_api_modules
fi

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
  
  # 프로젝트 이름 추출
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
  
  local display_path="${project_name} (${repo_path})"
  
  echo "================================================================================"
  echo "🚀 [Git 연동 디렉토리 발견] $display_path"
  
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
      git checkout "$SOURCE_BRANCH" >/dev/null 2>&1 || step_failed=1
      echo "  📥 2. 최신 변경사항 동기화"
      git pull >/dev/null 2>&1 || step_failed=1
      echo "  🌱 3. '$NEW_BRANCH' 브랜치 생성"
      git rev-parse --verify "$NEW_BRANCH" >/dev/null 2>&1 || git branch "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1
      echo "  🔄 4. '$NEW_BRANCH' 브랜치 전환"
      git checkout "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1
      echo "  📤 5. 원격 저장소에 업로드"
      git push --set-upstream origin "$NEW_BRANCH" >/dev/null 2>&1 || step_failed=1
      if [[ $step_failed -eq 0 && $DELETE_SOURCE -eq 1 ]]; then
        echo "  🗑️ 6. 기준 브랜치('$SOURCE_BRANCH') 삭제"
        git branch -d "$SOURCE_BRANCH" >/dev/null 2>&1 || true
        git push origin --delete "$SOURCE_BRANCH" >/dev/null 2>&1 || true
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
        git branch -d "$b" >/dev/null 2>&1 || true
        local ls_remote_status=0
        git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1 || ls_remote_status=$?
        if [[ $ls_remote_status -eq 0 ]]; then
           git push origin --delete "$b" >/dev/null 2>&1 || true
        fi
      done
    fi
  fi

  # --- 기존 기능: 브랜치 검색 ---
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
  local run_api=0
  if [[ -n "$PROTECT_BRANCHES_INPUT" || -n "$UNPROTECT_BRANCHES_INPUT" || $SHOW_PROTECTED_BRANCH -eq 1 || -n "$SET_DEFAULT_BRANCH_INPUT" || $SHOW_DEFAULT_BRANCH -eq 1 ]]; then
    run_api=1
  fi

  if [[ $run_api -eq 1 && $step_failed -eq 0 ]]; then
    local provider=""
    if [[ "$remote_url" == *"github.com"* ]]; then
      provider="github"
    elif [[ "$remote_url" == *"gitlab"* ]]; then
      provider="gitlab"
    else
      echo "  ⚠️ GitHub 또는 GitLab 원격 저장소를 찾을 수 없어 API 작업을 건너뜁니다."
      run_api=0
    fi

    if [[ $run_api -eq 1 ]]; then
      local script_dir
      script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
      
      # API 모듈 로드
      if [[ -f "$script_dir/git-branch-module-${provider}-api.sh" ]]; then
        source "$script_dir/git-branch-module-${provider}-api.sh"
      else
        echo "  ❌ 연동 모듈을 찾을 수 없습니다: git-branch-module-${provider}-api.sh"
        step_failed=1
      fi
      
      if [[ $step_failed -eq 0 ]]; then
        # 1. 보호 설정
        if [[ -n "$PROTECT_BRANCHES_INPUT" ]]; then
          echo "  🔒 [API 작업] 브랜치 보호 설정"
          local protect_arr=(); local b
          IFS=',' read -ra ADDR <<< "$PROTECT_BRANCHES_INPUT"
          for b in "${ADDR[@]}"; do
            b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [[ -z "$b" ]] && continue
            
            # 사전 검증 (원격 브랜치 유무)
            if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
              "api_${provider}_protect_branch" "$b"
              echo "    ✅ 보호 설정 완료: '$b'"
            else
              echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 보호 설정을 생략합니다."
            fi
          done
        fi
        
        # 2. 보호 해제
        if [[ -n "$UNPROTECT_BRANCHES_INPUT" ]]; then
          echo "  🔓 [API 작업] 브랜치 보호 해제"
          local unprotect_arr=(); local b
          IFS=',' read -ra ADDR <<< "$UNPROTECT_BRANCHES_INPUT"
          for b in "${ADDR[@]}"; do
            b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [[ -z "$b" ]] && continue
            
            if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
              "api_${provider}_unprotect_branch" "$b"
              echo "    ✅ 보호 해제 완료: '$b'"
            else
              echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 해제를 생략합니다."
            fi
          done
        fi
        
        # 3. 보호 목록 조회
        if [[ $SHOW_PROTECTED_BRANCH -eq 1 ]]; then
          echo "  🛡️ [API 작업] 보호 브랜치 목록 조회"
          local p_list
          p_list=$("api_${provider}_show_protected" || true)
          if [[ -n "$p_list" ]]; then
            while read -r line; do echo "    - $line"; done <<< "$p_list"
          else
            echo "    ℹ️ 보호 설정된 브랜치가 없습니다."
          fi
        fi
        
        # 4. 기본 브랜치 설정
        if [[ -n "$SET_DEFAULT_BRANCH_INPUT" ]]; then
          echo "  ⭐ [API 작업] 기본 브랜치 설정"
          local b="$SET_DEFAULT_BRANCH_INPUT"
          if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
            "api_${provider}_set_default" "$b"
            echo "    ✅ 기본 브랜치가 '$b' 로 설정되었습니다."
          else
            echo "    ⚠️ 원격 저장소에 '$b' 브랜치가 없어 설정을 중단합니다."
            step_failed=1
            fail_reason="기본 브랜치 설정 대상 미존재"
          fi
        fi
        
        # 5. 기본 브랜치 정보 제공
        if [[ $SHOW_DEFAULT_BRANCH -eq 1 ]]; then
          echo "  ℹ️ [API 작업] 기본 브랜치 정보 제공"
          local d_branch
          d_branch=$("api_${provider}_show_default" || true)
          echo "    👉 현재 기본 브랜치: '$d_branch'"
        fi
      fi
    fi
  fi

  popd > /dev/null

  if [[ $step_failed -eq 0 ]]; then
    echo "  ✅ 작업 완료: $display_path"
    SUCCESS_REPOS+=("$display_path")
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
    echo "--------------------------------------------------------------------------------"
    
    # 검색 전용 기능만 실행된 경우 (나머지 옵션이 모두 비어있는 경우) 기존 성공/실패 렌더링 스킵
    if [[ -z "$MIGRATE_BRANCH_INPUT" && -z "$DELETE_BRANCHES_INPUT" && -z "$PROTECT_BRANCHES_INPUT" && -z "$UNPROTECT_BRANCHES_INPUT" && $SHOW_PROTECTED_BRANCH -eq 0 && -z "$SET_DEFAULT_BRANCH_INPUT" && $SHOW_DEFAULT_BRANCH -eq 0 ]]; then
      return 0
    fi
  fi

  # 기존 마이그레이션, 삭제 및 API 작업 로직에 대한 보고서 보존 영역
  if [[ ${#SUCCESS_REPOS[@]} -gt 0 ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "✅ 성공 프로젝트 목록 (${#SUCCESS_REPOS[@]} 개):"
    local repo
    for repo in "${SUCCESS_REPOS[@]}"; do
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "  - $repo (가상 실행 완료)"
      else
        echo "  - $repo"
      fi
    done
    echo ""
  fi

  if [[ ${#FAIL_REPOS[@]} -gt 0 ]]; then
    echo "--------------------------------------------------------------------------------"
    echo "❌ 실패 프로젝트 목록 (${#FAIL_REPOS[@]} 개):"
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

echo "🔍 대상 디렉토리('$TARGET_DIR') 하위의 Git 저장소 탐색을 시작합니다..."
search_git_directories "$TARGET_DIR"

print_report

echo ""
echo "🏁 모든 처리가 완료되었습니다."
exit 0
