#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : git-push-after-sync.sh
# @license  : Apache License 2.0
# @since    : 2026-05-21
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/git-push-after-sync.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-push-after-sync.sh' into etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")

##
# 스크립트의 사용법 및 도움말을 출력합니다.
#
# @param $1 {string} 오류 발생 원인 메시지
# @param $2 {string} 오류 발생 라인 번호 (BASH_LINENO)
#
# @return 명령줄 포맷의 도움말 출력
##
help(){
  if [ ! -z "$1" ];
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
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법:"
  echo "  $FILENAME -s <소스_디렉토리> -t <대상_디렉토리>"
  echo "옵션:"
  echo "  -s, --source  : 변경을 감지하고 복사할 원본 디렉토리"
  echo "  -t, --target  : 복사된 파일이 위치하며 git 연동이 설정된 대상 디렉토리"
  echo "  -m, --message : 'git commit' 메시지"
  echo "  -h, --help    : 도움말 출력"
}

##
# 입력 및 대상 디렉토리의 유효성을 검증하고 필요시 자동 생성합니다.
#
# @param $1 {string} 디렉토리 경로
# @param $2 {string} 경로의 역할 타입 (source 또는 target)
#
# @return 유효하지 않은 경우 오류 출력 및 종료
##
validate_and_prepare_path() {
  local target_path="$1"
  local path_type="$2"
  
  if [[ -z "$target_path" ]]; then
    help "${path_type} 경로가 입력되지 않았습니다." "${BASH_LINENO[0]}"
    exit 1
  fi

  if [[ "$path_type" == "source" ]]; then
    if [[ ! -d "$target_path" ]]; then
      help "소스 경로가 존재하지 않거나 디렉토리가 아닙니다: $target_path" "${BASH_LINENO[0]}"
      exit 1
    fi
  elif [[ "$path_type" == "target" ]]; then
    if [[ ! -d "$target_path" ]]; then
      mkdir -p "$target_path" || { help "대상 디렉토리를 생성할 수 없습니다: $target_path" "${BASH_LINENO[0]}"; exit 1; }
    fi
    
    if ! git -C "$target_path" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      help "대상 디렉토리가 유효한 git 디렉토리에 포함되어 있지 않습니다: $target_path" "${BASH_LINENO[0]}"
      exit 1
    fi
  fi
}

##
# 소스와 대상 디렉토리를 비교하여 변경된 내용만 복사합니다.
#
# @param $1 {string} 소스 디렉토리 경로
# @param $2 {string} 대상 디렉토리 경로
#
# @return 동기화 수행 및 진행 상태 출력
##
sync_directories() {
  local source_dir="$1"
  local target_dir="$2"
  
  echo "디렉토리 비교: $source_dir => $target_dir"
  
  if diff -qr "$source_dir" "$target_dir" > /dev/null 2>&1; then
    echo "변경된 내용이 없으므로 복사를 건너뜁니다."
    return 0
  fi
  
  find "$source_dir" -type f | while read -r file; do
    if [[ "$file" == *.tmp ]] || [[ "$file" == *.swp ]] || [[ "$file" == *~ ]]; then
      continue
    fi
    
    if lsof "$file" > /dev/null 2>&1; then
      echo "경고: 파일이 다른 프로세스에 의해 사용 중입니다. ($file)"
      continue
    fi
    
    local relative_path="${file#$source_dir/}"
    local dest_file="$target_dir/$relative_path"
    local dest_dir=$(dirname "$dest_file")
    
    mkdir -p "$dest_dir"
    cp -f "$file" "$dest_file"
  done
  
  echo "파일 복사가 완료되었습니다."
}

##
# 오류 발생 시 대상 디렉토리의 파일 상태를 동기화 이전으로 되돌립니다.
#
# @param $1 {string} 롤백 기준이 되는 Git Commit Hash 값
#
# @return 복구 작업 실행 상태 출력
##
rollback_git_state() {
  local original_commit="$1"
  
  echo "장애 복구를 위해 파일 상태를 동기화 이전으로 롤백합니다."
  
  if [[ -n "$original_commit" ]]; then
    # 기존 커밋이 존재하는 경우 해당 해시로 하드 리셋
    git reset --hard "$original_commit" > /dev/null 2>&1
    git clean -fd > /dev/null 2>&1
  else
    # 저장소 생성 직후 최초 커밋 시도 중 실패했을 경우
    git rm -rf . > /dev/null 2>&1
    git clean -fd > /dev/null 2>&1
  fi
  
  echo "롤백이 완료되었습니다. 다음 변경 감지 시 재작업을 수행합니다."
}

##
# 복사된 대상 디렉토리로 이동하여 최신화 후 git 커밋 및 푸시를 진행합니다.
#
# @param $1 {string} 대상 디렉토리 경로
# @param $2 {string} git commit 메시지
#
# @return Git 처리 결과 전달 (실패 시 롤백 수행)
##
commit_and_push() {
  local target_dir="$1"
  
  cd "$target_dir" || { help "대상 디렉토리 진입에 실패했습니다: $target_dir" "${BASH_LINENO[0]}"; exit 1; }
  
  if [[ -z $(git status --porcelain .) ]]; then
    echo "Git에 추가할 변경사항이 없습니다."
    return 0
  fi
  
  # 동기화(Commit) 전 롤백을 위한 안전 장치: 현재 상태 캡처
  local original_commit=""
  if git rev-parse HEAD > /dev/null 2>&1; then
    original_commit=$(git rev-parse HEAD)
  fi
  
  git add .
  
  local commit_title="$2"
  local commit_body="동기화 일시: $(date +'%Y-%m-%d %H:%M:%S')"
  
  git commit -m "$commit_title" -m "$commit_body"
  
  echo "원격 저장소의 최신 변경사항을 병합합니다 (git pull --rebase)..."
  if ! git pull --rebase > /dev/null 2>&1; then
    echo "오류: 원격 데이터를 병합하는 중 충돌이 발생했습니다."
    git rebase --abort > /dev/null 2>&1
    rollback_git_state "$original_commit"
    return 1
  fi
  
  if ! git push > /dev/null 2>&1; then
    echo "오류: Git Push에 실패했습니다. (네트워크/권한 문제)"
    rollback_git_state "$original_commit"
    return 1
  fi
  
  echo "Git 커밋 및 푸시가 성공적으로 완료되었습니다."
}

##
# inotifywait를 이용해 소스 경로의 변경사항을 이벤트 기반으로 감지합니다.
#
# @param $1 {string} 소스 디렉토리
# @param $2 {string} 대상 디렉토리
#
# @return 무한 루프 모니터링 실행
##
monitor_changes() {
  local source_dir="$1"
  local target_dir="$2"
  
  echo "$source_dir 디렉토리의 변경사항 감지를 시작합니다..."
  
  while inotifywait -r -e modify,create,delete,move "$source_dir" > /dev/null 2>&1; do
    echo "파일 시스템 이벤트가 감지되었습니다. 동기화를 진행합니다."
    sync_directories "$source_dir" "$target_dir"
    commit_and_push "$target_dir"
  done
}

##
# 메인 실행 함수입니다.
#
# @param $@ {array} 쉘 스크립트 실행 인자
#
# @return 프로그램 상태 반환
##
main() {
  local source_dir=""
  local target_dir=""
  local commit_msg="Auto-sync: 소스 변경사항 동기화"
  
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--source) source_dir="$2"; shift 2 ;;
      -t|--target) target_dir="$2"; shift 2 ;;
      -m|--message) commit_msg="$2"; shift 2 ;;
      -h|--help) help; exit 0 ;;
      *) help "알 수 없는 파라미터입니다: $1" "${BASH_LINENO[0]}"; exit 1 ;;
    esac
  done
  
  validate_and_prepare_path "$source_dir" "source"
  validate_and_prepare_path "$target_dir" "target"
  
#  if ! command -v inotifywait > /dev/null 2>&1; then
#    help "inotifywait 명령어가 없습니다. inotify-tools 패키지를 설치해 주십시오." "${BASH_LINENO[0]}"
#    exit 1
#  fi
  if ! command -v lsof > /dev/null 2>&1; then
    help "lsof 명령어가 없습니다. 패키지를 설치해 주십시오." "${BASH_LINENO[0]}"
    exit 1
  fi
  
  sync_directories "$source_dir" "$target_dir"
  commit_and_push "$target_dir" "$commit_msg"
  
#  monitor_changes "$source_dir" "$target_dir"
}

main "$@"

exit 0
