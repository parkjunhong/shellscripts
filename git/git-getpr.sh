#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-07-08
# @desc     : support Ubuntu 20+, Rocky Linux 9+, RHEL 8+, Oracle Linux 9+, CentOS Stream 9+, macOS
# @installation : 
#   1. insert 'source <path>/git-getpr.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/git-getpr.sh' into 
#      etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")
OVERWRITE_MODE="ASK" # 상태값: ASK, FORCE, SKIP

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
  # TODO: Usage 내용 작성
  echo "사용법: $FILENAME [-g <git-url>] -p <project> -t <type> -r <resource> [-b <branch>] [-o <output-path>]"
  echo "옵션:"
  echo "  -g, --git-url       : Git 서비스 URL ('https' 시작, 미입력시 GIT_GETPR_GIT_URL 콤마(,) 구분 환경변수 사용. 다중 값일 경우 선택 제공)"
  echo "  -p, --project       : Git 서비스에서 사용하는 프로젝트 이름"
  echo "  -b, --branch        : 다운로드 대상 브랜치 (기본값: main, 실패시 master 재시도)"
  echo "  -t, --resource-type : 다운로드 대상 유형 (directory, d: 디렉토리, file, f: 파일)"
  echo "  -r, --resource      : 다운로드 하려는 대상 이름"
  echo "  -o, --output-path   : 저장 경로 (기본값: resource 의 마지막 이름)"
  echo "  -h, --help          : 도움말 출력"
}

##
# 로그를 출력합니다.
#
# @param $1 {string} 이모지가 포함된 메시지
#
# @return 콘솔 출력
##
print_log() {
  echo "$1"
}

##
# 대상 파일의 SHA-256 해시를 계산합니다.
#
# @param $1 {string} 대상 파일 경로
#
# @return SHA-256 해시값 문자열
##
calc_sha256() {
  local file_path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file_path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file_path" | awk '{print $1}'
  else
    echo ""
  fi
}

##
# 덮어쓰기 여부를 사용자에게 묻습니다.
#
# @param $1 {string} 충돌이 발생한 대상 경로
#
# @return 진행(0) 또는 건너뜀(1) 상태 코드
##
prompt_overwrite() {
  local target="$1"
  
  if [ "$OVERWRITE_MODE" == "FORCE" ]; then
    return 0
  elif [ "$OVERWRITE_MODE" == "SKIP" ]; then
    return 1
  fi
  
  while true; do
    read -p "⚠️  '$target' 경로가 이미 존재합니다. 덮어쓰시겠습니까? (yY/fF/nN/xX): " ynfx
    case $ynfx in
      [Yy]* ) return 0;;
      [Ff]* ) OVERWRITE_MODE="FORCE"; return 0;;
      [Nn]* ) return 1;;
      [Xx]* ) OVERWRITE_MODE="SKIP"; return 1;;
      * ) print_log "ℹ️  'y', 'f', 'n', 'x' 중 하나를 입력해 주세요.";;
    esac
  done
}

##
# Git Credential Helper가 설정되어 있는지 확인합니다.
##
ensure_credential_helper() {
  local current_helper
  current_helper=$(git config --get credential.helper)
  if [ -z "$current_helper" ]; then
    print_log "🔑 Git 자격 증명 도우미가 감지되지 않아 자동 저장(store) 모드를 활성화합니다."
    git config --global credential.helper store
  fi
}

##
# 자원을 재귀적으로 순회하며 충돌 검사, 해시 비교, 복사를 수행합니다.
##
sync_resource() {
  local src="$1"
  local dest="$2"

  # 1. 대상(Local)이 존재하는 경우
  if [ -e "$dest" ]; then
    # [치명적 오류 방어] 원격 자원과 로컬 자원의 유형(파일/디렉토리) 불일치 검사
    if [ -f "$src" ] && [ -d "$dest" ]; then
      print_log "🚨 [치명적 오류] 다운로드 대상은 '파일'이나, 로컬 경로('$dest')에 '디렉토리'가 이미 존재합니다."
      print_log "   데이터 유실을 방지하기 위해 작업을 즉시 중단합니다."
      exit 1
    elif [ -d "$src" ] && [ -f "$dest" ]; then
      print_log "🚨 [치명적 오류] 다운로드 대상은 '디렉토리'이나, 로컬 경로('$dest')에 '파일'이 이미 존재합니다."
      print_log "   데이터 유실을 방지하기 위해 작업을 즉시 중단합니다."
      exit 1
    fi

    # 유형이 같은 경우에만 덮어쓰기 진행 여부 확인
    if ! prompt_overwrite "$dest"; then
      print_log "⏭️  건너뜀: $dest"
      return 0
    fi
  fi

  # 2. 자원이 파일인 경우
  if [ -f "$src" ]; then
    if [ -f "$dest" ]; then
      OLD_HASH=$(calc_sha256 "$dest")
      NEW_HASH=$(calc_sha256 "$src")
      if [ "$OLD_HASH" == "$NEW_HASH" ] && [ -n "$OLD_HASH" ]; then
        print_log "✅ 동일한 파일: $dest"
      else
        print_log "✨ 새로운 파일로 변경: $dest"
      fi
    else
      # 기존에 있던 rm -rf 삭제 위험 로직 제거됨
      print_log "✅ 새로운 파일 다운로드: $dest"
    fi
    mkdir -p "$(dirname "$dest")"
    cp -f "$src" "$dest"

  # 3. 자원이 디렉토리인 경우
  elif [ -d "$src" ]; then
    # 기존에 있던 rm -f 삭제 위험 로직 제거됨
    mkdir -p "$dest"
    
    shopt -s dotglob
    for item in "$src"/*; do
      if [ -e "$item" ]; then
        sync_resource "$item" "$dest/$(basename "$item")"
      fi
    done
    shopt -u dotglob
  fi
}

GIT_URL=""
PROJECT=""
BRANCH="main"
RESOURCE_TYPE=""
RESOURCE=""
OUTPUT_PATH=""

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -g|--git-url) GIT_URL="$2"; shift ;;
    -p|--project) PROJECT="$2"; shift ;;
    -b|--branch) BRANCH="$2"; shift ;;
    -t|--resource-type) RESOURCE_TYPE="$2"; shift ;;
    -r|--resource) RESOURCE="$2"; shift ;;
    -o|--output-path) OUTPUT_PATH="$2"; shift ;;
    -h|--help) help; exit 0 ;;
    *) help "알 수 없는 옵션: $1" "$LINENO"; exit 1 ;;
  esac
  shift
done

GIT_URLS=()

# Git URL 할당 및 다중 URL 처리 로직
if [ -n "$GIT_URL" ]; then
  if [[ ! "$GIT_URL" =~ ^https:// ]]; then
    help "Git URL(-g 옵션)은 'https://'로 시작해야 합니다." "$LINENO"
    exit 1
  fi
else
  if [ -n "$GIT_GETPR_GIT_URL" ]; then
    IFS=',' read -ra URL_ARRAY <<< "$GIT_GETPR_GIT_URL"
    for url in "${URL_ARRAY[@]}"; do
      url="${url#"${url%%[![:space:]]*}"}"
      url="${url%"${url##*[![:space:]]}"}"
      if [[ ! "$url" =~ ^https:// ]]; then
        help "환경변수 GIT_GETPR_GIT_URL에 포함된 URL('$url')은 'https://'로 시작해야 합니다." "$LINENO"
        exit 1
      fi
      GIT_URLS+=("$url")
    done
  fi

  # 환경변수 기반 처리: 1개인 경우 자동 할당, 2개 이상인 경우 선택 프롬프트 제공
  if [ ${#GIT_URLS[@]} -eq 1 ]; then
    GIT_URL="${GIT_URLS[0]}"
  elif [ ${#GIT_URLS[@]} -gt 1 ]; then
    echo "🤔 환경변수(GIT_GETPR_GIT_URL)에 여러 개의 Git URL이 설정되어 있습니다."
    echo "다운로드에 사용할 Git URL을 선택해 주세요:"
    
    # 1. 'Git URL' 목록 빈칸 2칸 들여쓰기 출력
    idx=1
    for url in "${GIT_URLS[@]}"; do
      echo "  $idx) $url"
      ((idx++))
    done
    
    # 2. 이모지를 활용한 시각적 프롬프트 변경 및 입력 처리
    while true; do
      read -p "👉 번호를 선택해 주세요 ❯ " choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#GIT_URLS[@]}" ]; then
        GIT_URL="${GIT_URLS[$((choice-1))]}"
        break
      else
        echo "❌ 잘못된 선택입니다. 목록에 있는 번호를 다시 입력해 주세요."
      fi
    done
  fi
fi

# 필수 옵션 누락 검증
if [ -z "$GIT_URL" ] || [ -z "$PROJECT" ] || [ -z "$RESOURCE_TYPE" ] || [ -z "$RESOURCE" ]; then
  help "필수 파라미터가 누락되었습니다. (-g/환경변수, -p, -t, -r 를 확인하세요)" "$LINENO"
  exit 1
fi

# 대상 유형 정규화
if [[ "$RESOURCE_TYPE" != "d" && "$RESOURCE_TYPE" != "directory" && "$RESOURCE_TYPE" != "f" && "$RESOURCE_TYPE" != "file" ]]; then
  help "자원 유형(-t)은 'directory', 'd', 'file', 'f'만 가능합니다." "$LINENO"
  exit 1
fi
if [ "$RESOURCE_TYPE" == "directory" ]; then RESOURCE_TYPE="d"; fi
if [ "$RESOURCE_TYPE" == "file" ]; then RESOURCE_TYPE="f"; fi

if [ -z "$OUTPUT_PATH" ]; then
  OUTPUT_PATH="${RESOURCE##*/}"
fi

# 안전한 PROJECT_URL 생성
GIT_URL="${GIT_URL%/}"
PROJECT="${PROJECT#/}"
PROJECT_URL="${GIT_URL}/${PROJECT}"

ACTUAL_BRANCH="$BRANCH"

# ==========================================
# 다운로드 요약 정보 출력 (가독성 향상)
# ==========================================
# 1. 출력용 리소스 타입 치환 (d -> directory, f -> file)
DISPLAY_RESOURCE_TYPE="directory"
if [ "$RESOURCE_TYPE" == "f" ]; then
  DISPLAY_RESOURCE_TYPE="file"
fi

# 2. 출력용 절대 경로 계산
if [[ "$OUTPUT_PATH" = /* ]]; then
  DISPLAY_OUTPUT_PATH="$OUTPUT_PATH"
else
  DISPLAY_OUTPUT_PATH="$(pwd)/$OUTPUT_PATH"
fi

print_log ""
print_log "================================================================================"
print_log " 📄 다운로드 정보 요약"
print_log "================================================================================"
format_str=" - %-18s: %s\n"
printf "$format_str" "--git-url" "$GIT_URL"
printf "$format_str" "--project" "$PROJECT"
printf "$format_str" "--branch" "$ACTUAL_BRANCH"
printf "$format_str" "--resource-type" "$DISPLAY_RESOURCE_TYPE"
printf "$format_str" "--resource" "$RESOURCE"
printf "$format_str" "--output-path" "$DISPLAY_OUTPUT_PATH"
print_log "================================================================================"
print_log ""

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_credential_helper

# 브랜치 검증
print_log "🚀 저장소 연결 및 브랜치 확인 중..."
if ! git ls-remote --heads "$PROJECT_URL" "$ACTUAL_BRANCH" | grep -q "refs/heads/$ACTUAL_BRANCH"; then
  if [ "$ACTUAL_BRANCH" == "main" ]; then
    print_log "ℹ️  'main' 브랜치가 발견되지 않아 'master' 브랜치로 재시도합니다."
    ACTUAL_BRANCH="master"
  else
    print_log "❌ '$ACTUAL_BRANCH' 브랜치를 찾을 수 없습니다."
    exit 1
  fi
fi

# 다운로드 수행
print_log "🚀 자원 다운로드 중... ($PROJECT_URL)"
git clone --filter=blob:none --no-checkout --depth 1 --sparse "$PROJECT_URL" "$TMP_DIR" > /dev/null 2>&1
cd "$TMP_DIR" || exit 1
git sparse-checkout set "$RESOURCE" > /dev/null 2>&1
git checkout "$ACTUAL_BRANCH" > /dev/null 2>&1
cd - > /dev/null || exit 1

if [ ! -e "$TMP_DIR/$RESOURCE" ]; then
  print_log "❌ 요청한 자원 '$RESOURCE'을(를) 원격 저장소에서 찾을 수 없습니다."
  exit 1
fi

if [ "$RESOURCE_TYPE" == "d" ] && [ ! -d "$TMP_DIR/$RESOURCE" ]; then
  print_log "❌ 대상 유형 불일치: '$RESOURCE'은(는) 디렉토리가 아닙니다. (-t file 또는 f 를 사용하세요)"
  exit 1
fi
if [ "$RESOURCE_TYPE" == "f" ] && [ ! -f "$TMP_DIR/$RESOURCE" ]; then
  print_log "❌ 대상 유형 불일치: '$RESOURCE'은(는) 파일이 아닙니다. (-t directory 또는 d 를 사용하세요)"
  exit 1
fi

sync_resource "$TMP_DIR/$RESOURCE" "$OUTPUT_PATH"

print_log "✅ 자원 다운로드 및 처리가 완료되었습니다: $OUTPUT_PATH"
exit 0

