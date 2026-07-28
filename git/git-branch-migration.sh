#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-07-28
# @desc     : support RHEL 8+, Oracle Linux 9+, Ubuntu 20.04+, RockyOS 9+, CentOS 7+
# @installation : 
#   1. insert 'source <path>/git-branch-migration.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-branch-migration.sh' into /etc/bashrc for all users.
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
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" $func
      # set -e 강제 종료 방지를 위해 템플릿의 산술식에 표준 할당 적용
      idx=$((idx + 1))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME [옵션] [작업디렉토리]"
  echo ""
  echo "[설명]"
  echo "  지정된 경로 하위의 Git 연동 디렉토리를 탐색하여 브랜치 마이그레이션 또는 삭제 작업을 일괄 수행합니다."
  echo "  (작업 디렉토리를 생략하면 현재 경로('.')를 기준으로 탐색합니다.)"
  echo ""
  echo "[옵션 (Options)]"
  echo "  -s, --source-branch <브랜치>   마이그레이션 기준 기존 브랜치명"
  echo "  -n, --new-branch <브랜치>      마이그레이션 대상 신규 브랜치명"
  echo "      --delete-source            마이그레이션 완료 후 기준 브랜치(-s)를 삭제합니다."
  echo "      --delete-branch <브랜치명> 지정된 브랜치를 로컬 및 원격에서 삭제합니다. (콤마(,)로 다중 지정 가능)"
  echo "                                 예) --delete-branch \"master, dev\""
  echo "      --dry-run                  실제로 명령어를 실행하지 않고 실행될 명령어만 출력합니다."
  echo "  -h, --help                     이 도움말을 표시하고 종료합니다."
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

SOURCE_BRANCH=""
NEW_BRANCH=""
DELETE_BRANCHES_INPUT=""
TARGET_DIR=""
DELETE_SOURCE=0
DRY_RUN=0

# 작업 결과 추적용 전역 배열 선언
SUCCESS_REPOS=()
FAIL_REPOS=()

# 인자 파싱
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help "" ""
      exit 0
      ;;
    -s|--source-branch)
      shift
      SOURCE_BRANCH="${1:-}"
      ;;
    -n|--new-branch)
      shift
      NEW_BRANCH="${1:-}"
      ;;
    --delete-source)
      DELETE_SOURCE=1
      ;;
    --delete-branch)
      shift
      DELETE_BRANCHES_INPUT="${1:-}"
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
if [[ -z "$SOURCE_BRANCH" && -z "$NEW_BRANCH" && -z "$DELETE_BRANCHES_INPUT" ]]; then
  help "마이그레이션 옵션(-s, -n) 또는 브랜치 삭제 옵션(--delete-branch)을 지정해야 합니다." "$LINENO"
  exit 1
fi
if [[ (-n "$SOURCE_BRANCH" && -z "$NEW_BRANCH") || (-z "$SOURCE_BRANCH" && -n "$NEW_BRANCH") ]]; then
  help "마이그레이션을 위해서는 기준 브랜치(-s)와 신규 브랜치(-n)가 모두 지정되어야 합니다." "$LINENO"
  exit 1
fi

# 디렉토리 유효성 검증
if [[ ! -d "$TARGET_DIR" ]]; then
  help "입력한 작업 대상이 유효한 디렉토리가 아닙니다: $TARGET_DIR" "$LINENO"
  exit 1
fi

##
# 단일 Git 연동 디렉토리에 대해 마이그레이션 및 다중 브랜치 삭제 로직을 수행합니다.
#
# @param $1 {string} 처리할 Git 연동 디렉토리 경로
# @param $2 {string} 기준 브랜치명
# @param $3 {string} 신규 브랜치명
# @param $4 {string} 삭제할 브랜치 목록 (콤마 구분 문자열)
#
# @return (터미널 진행 로그 출력 및 전역 배열에 결과 추가)
##
process_repo() {
  local repo_path="$1"
  local src_branch="$2"
  local new_branch="$3"
  local del_branches_raw="$4"
  local step_failed=0
  local fail_reason=""
  
  echo "================================================================================"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "🚀 [Git 연동 디렉토리 발견] $repo_path (가상 실행 모드)"
  else
    echo "🚀 [Git 연동 디렉토리 발견] $repo_path"
  fi
  
  if ! pushd "$repo_path" > /dev/null 2>&1; then
    fail_reason="디렉토리 접근 권한이 없습니다."
    echo "  ⚠️ $fail_reason"
    FAIL_REPOS+=("${repo_path}::::${fail_reason}")
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
    
    # 콤마(,) 기준 분리 및 Whitespace Trim 처리
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
          # 로컬 브랜치 삭제
          if ! git branch -d "$b" >/dev/null 2>&1; then
            fail_reason="로컬 '$b' 브랜치 삭제 실패 (미존재 또는 체크아웃 상태)"
            echo "      ⚠️ $fail_reason"
            step_failed=1
            break
          fi
          # 원격 브랜치 삭제
          if ! git push origin --delete "$b" >/dev/null 2>&1; then
            fail_reason="원격 '$b' 브랜치 삭제 실패 (미존재 또는 권한 부족)"
            echo "      ⚠️ $fail_reason"
            step_failed=1
            break
          fi
        fi
      done
    fi
  fi

  popd > /dev/null

  # 결과 수집
  if [[ $step_failed -eq 0 ]]; then
    echo "  ✅ 작업 완료: $repo_path"
    SUCCESS_REPOS+=("$repo_path")
  else
    echo "  ❌ 작업 실패: $repo_path"
    FAIL_REPOS+=("${repo_path}::::${fail_reason}")
  fi
  echo "================================================================================"
}

##
# 지정된 디렉토리를 재귀적으로 탐색합니다.
#
# @param $1 {string} 탐색을 시작할 현재 디렉토리 경로
# @param $2 {string} 기준 브랜치명
# @param $3 {string} 신규 브랜치명
# @param $4 {string} 삭제할 콤마 구분 브랜치 목록
#
# @return (조건 충족 시 process_repo 함수 호출)
##
search_git_directories() {
  local current_dir="$1"
  local src_branch="$2"
  local new_branch="$3"
  local del_branches="$4"

  if [[ -d "$current_dir/.git" ]]; then
    process_repo "$current_dir" "$src_branch" "$new_branch" "$del_branches"
  else
    local sub_dir
    while IFS= read -r -d '' sub_dir; do
      search_git_directories "$sub_dir" "$src_branch" "$new_branch" "$del_branches"
    done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
  fi
}

##
# 스크립트 실행 결과를 종합하여 동적 정렬된 보고서 형태로 출력합니다.
#
# @param 없음
#
# @return (성공 및 실패 내역 요약 출력)
##
print_report() {
  local total_repos=$(( ${#SUCCESS_REPOS[@]} + ${#FAIL_REPOS[@]} ))

  echo ""
  echo "📊 [작업 완료 보고서] - 총 $total_repos 개"
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

search_git_directories "$TARGET_DIR" "$SOURCE_BRANCH" "$NEW_BRANCH" "$DELETE_BRANCHES_INPUT"
print_report

exit 0
