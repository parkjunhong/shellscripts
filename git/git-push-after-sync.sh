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
# @return 메인 명령줄 출력 포맷
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
  echo "사용법 (Usage):"
  echo "  $FILENAME -s <소스_디렉토리> -t <대상_디렉토리>"
  echo "  -s, --source  : 변경을 감지하고 복사할 원본 디렉토리"
  echo "  -t, --target  : 복사된 파일이 위치하며 git 연동이 설정된 대상 디렉토리"
  echo "  -h, --help    : 도움말 출력"
}

##
# 입력 및 대상 디렉토리의 유효성을 검증하고 필요시 디렉토리를 생성합니다.
#
# @param $1 {string} 디렉토리 경로
# @param $2 {string} 경로의 역할 타입 (source 또는 target)
#
# @return 유효성 검증 실패 시 프로그램 오류 종료
##
validate_and_prepare_path() {
  local target_path="$1"
  local path_type="$2"
  
  if [[ -z "$target_path" ]]; then
    help "${path_type} 경로가 입력되지 않았습니다." "${BASH_LINENO[0]}"
    exit 1
  fi

  if [[ "$path_type" == "source" ]]; then
    # 소스 경로는 입력 데이터이므로 반드시 존재해야 함
    if [[ ! -d "$target_path" ]]; then
      help "입력 데이터로 사용되는 소스 경로가 존재하지 않거나 디렉토리가 아닙니다: $target_path" "${BASH_LINENO[0]}"
      exit 1
    fi
  elif [[ "$path_type" == "target" ]]; then
    # 대상 경로는 결과물을 저장하므로 중간 경로 포함 자동 생성
    if [[ ! -d "$target_path" ]]; then
      mkdir -p "$target_path" || { help "대상 디렉토리를 생성할 수 없습니다: $target_path" "${BASH_LINENO[0]}"; exit 1; }
    fi
    
    # 유효한 git 디렉토리에 포함되어 있는지 검증
    if ! git -C "$target_path" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      help "대상 디렉토리가 유효한 git 디렉토리에 포함되어 있지 않습니다: $target_path" "${BASH_LINENO[0]}"
      exit 1
    fi
  fi
}

##
# 소스 디렉토리와 대상 디렉토리를 비교하여 복사합니다.
#
# @param $1 {string} 소스 디렉토리 경로
# @param $2 {string} 대상 디렉토리 경로
#
# @return 표준 출력으로 동기화 진행 상태 전달
##
sync_directories() {
  local source_dir="$1"
  local target_dir="$2"
  
  echo "디렉토리 비교: $source_dir &rarr; $target_dir"
  
  # 변경사항 유무 1차 비교
  if diff -qr "$source_dir" "$target_dir" > /dev/null 2>&1; then
    echo "변경된 내용이 없으므로 복사를 건너뜁니다."
    return 0
  fi
  
  # 파일 탐색 시 공백 및 특수기호 처리를 위해 find와 while read -r 구문 사용
  find "$source_dir" -type f | while read -r file; do
    # 임시 파일 무시
    if [[ "$file" == *.tmp ]] || [[ "$file" == *.swp ]] || [[ "$file" == *~ ]]; then
      continue
    fi
    
    # lsof를 활용하여 파일 사용 여부 검증
    if lsof "$file" > /dev/null 2>&1; then
      echo "경고: 파일이 다른 프로세스에 의해 사용 중입니다. ($file)"
      continue
    fi
    
    local relative_path="${file#$source_dir/}"
    local dest_file="$target_dir/$relative_path"
    local dest_dir=$(dirname "$dest_file")
    
    # 하위 디렉토리가 존재하지 않는 경우 생성
    mkdir -p "$dest_dir"
    cp -f "$file" "$dest_file"
  done
  
  echo "파일 복사가 완료되었습니다."
}

##
# 복사된 대상 디렉토리로 이동하여 git 커밋 및 푸시를 진행합니다.
#
# @param $1 {string} 대상 디렉토리 경로
#
# @return 표준 출력으로 git 처리 결과 전달
##
commit_and_push() {
  local target_dir="$1"
  
  cd "$target_dir" || { help "대상 디렉토리 진입에 실패했습니다: $target_dir" "${BASH_LINENO[0]}"; exit 1; }
  
  # 현재 디렉토리 기준 변경사항 확인
  if [[ -z $(git status --porcelain .) ]]; then
    echo "Git에 추가할 변경사항이 없습니다."
    return 0
  fi
  
  git add .
  
  local commit_title="Auto-sync: 소스 변경사항 동기화"
  local commit_body="동기화 일시: $(date +'%Y-%m-%d %H:%M:%S')"
  
  git commit -m "$commit_title" -m "$commit_body"
  git push
  
  echo "Git 커밋 및 푸시가 완료되었습니다."
}

##
# inotifywait를 이용해 소스 경로의 변경사항을 폴링 없이 이벤트 기반으로 감지합니다.
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
# @return 프로그램 정상/비정상 종료 코드
##
main() {
  local source_dir=""
  local target_dir=""
  
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--source) source_dir="$2"; shift 2 ;;
      -t|--target) target_dir="$2"; shift 2 ;;
      -h|--help) help; exit 0 ;;
      *) help "알 수 없는 파라미터입니다: $1" "${BASH_LINENO[0]}"; exit 1 ;;
    esac
  done
  
  validate_and_prepare_path "$source_dir" "source"
  validate_and_prepare_path "$target_dir" "target"
  
  # 필수 의존성 명령어 존재 여부 검증
  if ! command -v inotifywait > /dev/null 2>&1; then
    help "inotifywait 명령어가 없습니다. inotify-tools 패키지를 설치해 주십시오." "${BASH_LINENO[0]}"
    exit 1
  fi
  if ! command -v lsof > /dev/null 2>&1; then
    help "lsof 명령어가 없습니다. 패키지를 설치해 주십시오." "${BASH_LINENO[0]}"
    exit 1
  fi
  
  sync_directories "$source_dir" "$target_dir"
  commit_and_push "$target_dir"
 
  # 작은 변화에도 무조건 동기화가 진행될 것으로 염려되어 주석처리. 
#  monitor_changes "$source_dir" "$target_dir"
}

main "$@"

exit 0

