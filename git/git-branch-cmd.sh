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
  echo "  지정된 경로 하위의 Git 연동 디렉토리를 탐색하여 브랜치 마이그레이션, 삭제 또는 검색 작업을 일괄 수행합니다."
  echo "  (작업 디렉토리를 생략하면 현재 경로('.')를 기준으로 탐색합니다.)"
  echo ""
  echo "[옵션 (Options)]"
  echo "      --migrate-branch <기존>:<신규> 기준 브랜치와 마이그레이션 대상 신규 브랜치명 지정"
  echo "                                 예) --migrate-branch \"master:main\""
  echo "      --delete-source            마이그레이션 완료 후 기준 브랜치를 삭제합니다."
  echo "      --delete-branch <브랜치명> 지정된 브랜치를 로컬/원격에서 삭제합니다. (콤마(,)로 다중 지정 가능)"
  echo "                                 예) --delete-branch \"master, dev\""
  echo "      --find-branch <브랜치명>   지정된 브랜치의 로컬/원격 존재 여부를 검색합니다. (콤마(,)로 다중 지정 가능)"
  echo "                                 예) --find-branch \"master, dev\""
  echo "      --dry-run                  실제로 명령어를 실행하지 않고 실행될 명령어만 출력합니다."
  echo "  -h, --help                     이 도움말을 표시하고 종료합니다."
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

MIGRATE_BRANCH_INPUT=""
SOURCE_BRANCH=""
NEW_BRANCH=""
DELETE_BRANCHES_INPUT=""
FIND_BRANCHES_INPUT=""
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
      shift
      MIGRATE_BRANCH_INPUT="${1:-}"
      ;;
    --delete-source)
      DELETE_SOURCE=1
      ;;
    --delete-branch)
      shift
      DELETE_BRANCHES_INPUT="${1:-}"
      ;;
    --find-branch)
      shift
      FIND_BRANCHES_INPUT="${1:-}"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -*)
      help "지원하지 않는 옵션입니다: $1" "$LINENO"
      exit 1
      ;;
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

# 필수 옵션 조합 검증
if [[ -z "$MIGRATE_BRANCH_INPUT" && -z "$DELETE_BRANCHES_INPUT" && -z "$FIND_BRANCHES_INPUT" ]]; then
  help "마이그레이션(--migrate-branch), 삭제(--delete-branch) 또는 검색(--find-branch) 옵션을 지정해야 합니다." "$LINENO"
  exit 1
fi

if [[ -n "$MIGRATE_BRANCH_INPUT" ]]; then
  if [[ "$MIGRATE_BRANCH_INPUT" != *":"* ]]; then
    help "--migrate-branch 옵션의 값은 '<기존브랜치>:<신규브랜치>' 형식이어야 합니다." "$LINENO"
    exit 1
  fi
  SOURCE_BRANCH="${MIGRATE_BRANCH_INPUT%%:*}"
  NEW_BRANCH="${MIGRATE_BRANCH_INPUT#*:}"
  if [[ -z "$SOURCE_BRANCH" || -z "$NEW_BRANCH" ]]; then
    help "--migrate-branch 옵션의 값이 올바르지 않습니다. (<기존브랜치>:<신규브랜치>)" "$LINENO"
    exit 1
  fi
fi

# 디렉토리 유효성 검증
if [[ ! -d "$TARGET_DIR" ]]; then
  help "입력한 작업 대상이 유효한 디렉토리가 아닙니다: $TARGET_DIR" "$LINENO"
  exit 1
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
# @param $2 {string} 기준 브랜치명
# @param $3 {string} 신규 브랜치명
# @param $4 {string} 삭제할 브랜치 목록
# @param $5 {string} 검색할 브랜치 목록
#
# @return (터미널 진행 로그 출력 및 전역 배열에 결과 추가)
##
process_repo() {
  local repo_path="$1"
  local src_branch="$2"
  local new_branch="$3"
  local del_branches_raw="$4"
  local find_branches_raw="${5:-}"
  local step_failed=0
  local fail_reason=""
  
  # 프로젝트 식별자 이름 추출 로직 (원격 URL 또는 절대경로 기반)
  local abs_path=""
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

  # [1] 마이그레이션 작업 블록
  if [[ -n "$src_branch" && -n "$new_branch" && $step_failed -eq 0 ]]; then
    if ! git rev-parse --verify "$src_branch" >/dev/null 2>&1; then
      fail_reason="'$src_branch' 로컬 브랜치가 존재하지 않아 작업을 중단합니다."
      echo "  ⚠️ $fail_reason"
      step_failed=1
    fi

    if [[ $step_failed -eq 0 ]]; then
      echo "  📦 1. '$src_branch' 브랜치 전환"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] git checkout \"$src_branch\""
      else
        if ! git checkout "$src_branch" >/dev/null 2>&1; then
          fail_reason="'$src_branch' 브랜치 전환 실패"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        fi
      fi
    fi

    if [[ $step_failed -eq 0 ]]; then
      echo "  📥 2. 최신 변경사항 동기화"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] git pull"
      else
        if ! git pull >/dev/null 2>&1; then
          fail_reason="'git pull' 실패 (권한, 병합 충돌 또는 원격 브랜치 부재)"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        fi
      fi
    fi

    if [[ $step_failed -eq 0 ]]; then
      echo "  🌱 3. '$new_branch' 브랜치 생성"
      if git rev-parse --verify "$new_branch" >/dev/null 2>&1; then
        echo "  ℹ️ '$new_branch' 로컬 브랜치가 이미 존재하여 생성을 건너뜁니다."
      else
        if [[ $DRY_RUN -eq 1 ]]; then
          echo "    [DRY-RUN] git branch \"$new_branch\""
        else
          if ! git branch "$new_branch" >/dev/null 2>&1; then
            fail_reason="'$new_branch' 브랜치 생성 실패"
            echo "  ⚠️ $fail_reason"
            step_failed=1
          fi
        fi
      fi
    fi

    if [[ $step_failed -eq 0 ]]; then
      echo "  🔄 4. '$new_branch' 브랜치 전환"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] git checkout \"$new_branch\""
      else
        if ! git checkout "$new_branch" >/dev/null 2>&1; then
          fail_reason="'$new_branch' 브랜치 전환 실패"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        fi
      fi
    fi

    if [[ $step_failed -eq 0 ]]; then
      echo "  📤 5. 원격 저장소에 업로드"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] git push --set-upstream origin \"$new_branch\""
      else
        if ! git push --set-upstream origin "$new_branch" >/dev/null 2>&1; then
          fail_reason="푸시 실패 (Git 권한 또는 네트워크 상태 확인 필요)"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        fi
      fi
    fi

    if [[ $step_failed -eq 0 && $DELETE_SOURCE -eq 1 ]]; then
      echo "  🗑️ 6. 기준 브랜치('$src_branch') 삭제"
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] git branch -d \"$src_branch\""
        echo "    [DRY-RUN] git push origin --delete \"$src_branch\""
      else
        if ! git branch -d "$src_branch" >/dev/null 2>&1; then
          fail_reason="로컬 '$src_branch' 브랜치 삭제 실패 (체크아웃 상태 또는 병합 미완료)"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        elif ! git push origin --delete "$src_branch" >/dev/null 2>&1; then
          fail_reason="원격 '$src_branch' 브랜치 삭제 실패 (권한 부족)"
          echo "  ⚠️ $fail_reason"
          step_failed=1
        fi
      fi
    fi
  fi

  # [2] 독립적 다중 브랜치 삭제 작업 블록
  if [[ -n "$del_branches_raw" && $step_failed -eq 0 ]]; then
    local del_branch_arr=()
    local b
    
    IFS=',' read -ra ADDR <<< "$del_branches_raw"
    for b in "${ADDR[@]}"; do
      b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
      if [[ -n "$b" ]]; then
        del_branch_arr+=("$b")
      fi
    done

    if [[ ${#del_branch_arr[@]} -gt 0 ]]; then
      echo "  🔥 [추가 작업] 지정된 브랜치 다중 삭제"
      for b in "${del_branch_arr[@]}"; do
        echo "    - 대상 브랜치: '$b'"
        if [[ $DRY_RUN -eq 1 ]]; then
          echo "      [DRY-RUN] git branch -d \"$b\""
          echo "      [DRY-RUN] git push origin --delete \"$b\""
        else
          local local_status=0
          local remote_status=0
          local local_out=""
          local remote_out=""
          
          # 로컬 브랜치 삭제 시도
          local_out=$(git branch -d "$b" 2>&1) || local_status=$?
          if [[ $local_status -eq 0 ]]; then
            echo "      ✅ 로컬 '$b' 브랜치 삭제 완료"
          else
            echo "      ℹ️ 로컬 '$b' 브랜치 미존재 또는 삭제 불가 (원격 검증 단계 진행)"
          fi
          
          # 원격 브랜치 존재 여부 사전 검증 (--exit-code 활용)
          local ls_remote_err=""
          local ls_remote_status=0
          
          ls_remote_err=$(git ls-remote --exit-code --heads origin "$b" 2>&1 >/dev/null) || ls_remote_status=$?

          if [[ $ls_remote_status -eq 0 ]]; then
            remote_out=$(git push origin --delete "$b" 2>&1) || remote_status=$?
            if [[ $remote_status -eq 0 ]]; then
              echo "      ✅ 원격 '$b' 브랜치 삭제 완료"
            else
              echo "      ℹ️ 원격 '$b' 브랜치 삭제 실패"
            fi
          elif [[ $ls_remote_status -eq 2 ]]; then
            remote_status=1
            remote_out="not found"
            echo "      ℹ️ 원격 '$b' 브랜치 미존재 (삭제 시도 생략)"
          else
            remote_status=$ls_remote_status
            remote_out="$ls_remote_err"
            echo "      ℹ️ 원격 저장소 접근 실패"
          fi
          
          # 로컬과 원격 삭제가 모두 불가한 경우 최종 실패 마킹 및 사유 조합
          if [[ $local_status -ne 0 && $remote_status -ne 0 ]]; then
            local loc_reason
            local rem_reason
            
            loc_reason=$(parse_git_delete_error "local" "$local_out")
            rem_reason=$(parse_git_delete_error "remote" "$remote_out")
            
            if [[ "$loc_reason" == "미존재" && "$rem_reason" == "미존재" ]]; then
              fail_reason="'$b' 브랜치 미존재 (로컬 및 원격)"
            else
              fail_reason="'$b' 브랜치 삭제 불가 (로컬: $loc_reason | 원격: $rem_reason)"
            fi
            
            echo "      ⚠️ $fail_reason"
            step_failed=1
            break
          fi
        fi
      done
    fi
  fi

  # [3] 브랜치 검색 작업 블록
  if [[ -n "$find_branches_raw" && $step_failed -eq 0 ]]; then
    local find_branch_arr=()
    local b
    
    IFS=',' read -ra ADDR <<< "$find_branches_raw"
    for b in "${ADDR[@]}"; do
      b=$(echo "$b" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
      if [[ -n "$b" ]]; then
        find_branch_arr+=("$b")
      fi
    done

    if [[ ${#find_branch_arr[@]} -gt 0 ]]; then
      echo "  🔍 [추가 작업] 지정된 브랜치 존재 여부 검색"
      local repo_found_count=0
      local repo_branch_details=()

      for b in "${find_branch_arr[@]}"; do
        local is_local="X"
        local is_remote="X"
        
        if git show-ref --verify --quiet "refs/heads/$b" 2>/dev/null; then
          is_local="O"
        fi
        if git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
          is_remote="O"
        fi
        
        printf "    - 대상 브랜치: %-20s | 로컬: %s | 원격: %s\n" "'$b'" "$is_local" "$is_remote"
        
        if [[ "$is_local" == "O" || "$is_remote" == "O" ]]; then
          repo_found_count=$((repo_found_count + 1))
          repo_branch_details+=("${b}::::${is_local}::::${is_remote}")
        fi
      done

      # 존재하는 브랜치가 1개라도 있으면 배열에 세부 정보 조합 저장
      if [[ $repo_found_count -gt 0 ]]; then
        local details_str=""
        local d
        for d in "${repo_branch_details[@]}"; do
          details_str="${details_str}${d}@@"
        done
        FIND_EXIST_REPOS+=("${display_path}####${details_str}")
      else
        FIND_MISSING_REPOS+=("$display_path")
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
# @param $1 {string} 탐색을 시작할 현재 디렉토리 경로
# @param $2 {string} 기준 브랜치명
# @param $3 {string} 신규 브랜치명
# @param $4 {string} 삭제할 브랜치 목록
# @param $5 {string} 검색할 브랜치 목록
#
# @return (조건 충족 시 process_repo 함수 호출)
##
search_git_directories() {
  local current_dir="$1"
  local src_branch="$2"
  local new_branch="$3"
  local del_branches="$4"
  local find_branches="${5:-}"

  if [[ -d "$current_dir/.git" ]]; then
    process_repo "$current_dir" "$src_branch" "$new_branch" "$del_branches" "$find_branches"
  else
    local sub_dir
    while IFS= read -r -d '' sub_dir; do
      search_git_directories "$sub_dir" "$src_branch" "$new_branch" "$del_branches" "$find_branches"
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
    
    # 검색 전용 기능인 경우 기존 성공/실패 렌더링 스킵
    if [[ -z "$SOURCE_BRANCH" && -z "$DELETE_BRANCHES_INPUT" ]]; then
      return 0
    fi
  fi

  # 기존 마이그레이션 및 삭제 로직에 대한 보고서 보존 영역
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
  echo "🏁 모든 처리가 완료되었습니다."
}

echo "🔍 대상 디렉토리('$TARGET_DIR') 하위의 Git 저장소 탐색을 시작합니다..."
if [[ -n "$SOURCE_BRANCH" && -n "$NEW_BRANCH" ]]; then
  echo "👉 마이그레이션 전략: [$SOURCE_BRANCH] -> [$NEW_BRANCH]"
fi
if [[ -n "$DELETE_BRANCHES_INPUT" ]]; then
  echo "👉 브랜치 삭제 대상: [$DELETE_BRANCHES_INPUT]"
fi
if [[ -n "$FIND_BRANCHES_INPUT" ]]; then
  echo "👉 브랜치 검색 대상: [$FIND_BRANCHES_INPUT]"
fi

search_git_directories "$TARGET_DIR" "$SOURCE_BRANCH" "$NEW_BRANCH" "$DELETE_BRANCHES_INPUT" "$FIND_BRANCHES_INPUT"
print_report

exit 0
