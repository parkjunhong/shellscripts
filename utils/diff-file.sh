#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-08-12
# @desc     : support RHEL 9+, Oracle Linux 9+, Ubuntu 22.04+, RockyOS 9+, CentOS 9+
# @installation : 
#   1. insert 'source <path>/diff-file.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/diff-file.sh' into /etc/bashrc for all users.
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
      printf "$formatr" "["$idx"]" $func
      ((idx++)) || true
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME -s <기준파일> -f <검색패턴> [옵션]"
  echo ""
  echo "[설명]"
  echo "  기준 파일과 대상 디렉토리 하위 파일들의 내용을 정규화하여 비교 보고서를 생성합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  -d, --directory <디렉토리>  검색 대상 디렉토리 (기본값: 현재 디렉토리 '.')"
  echo "  -s, --source <파일>         비교 기준이 되는 파일 경로 (필수)"
  echo "  -f, --file <패턴>           검색 대상 파일명 또는 패턴 (예: \"*.yml\", \"application-*\") (필수)"
  echo "      --copy-content          내용이 다른 대상 파일의 내용을 기준 파일 내용으로 복사/변경합니다."
  echo "      --no-ne-files           동일하지 않은 파일 목록 정보는 보고서에서 제외합니다."
  echo "      --dry-run               실제 비교 및 복사 수행 과정을 가상으로 출력합니다."
  echo "  -h, --help                  이 도움말을 출력하고 종료합니다."
}

# 전역 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
TARGET_DIR="."
SOURCE_FILE=""
FILE_PATTERN=""
COPY_CONTENT=0
NO_NE_FILES=0
DRY_RUN=0

TMP_DIR=""
ABS_TARGET_DIR=""
ABS_SOURCE_FILE=""
NORM_SOURCE_FILE=""
SOURCE_HASH=""

SCANNED_COUNT=0
FOUND_COUNT=0

SEARCH_START_MS=0
SEARCH_END_MS=0
SEARCH_ELAPSED_MS=0
SEARCH_TIME_STR=""

TARGET_FILE_LIST=()
IDENTICAL_FILES=()
DIFFERENT_FILES=()
COPIED_FILES=()

##
# 실행 종료 시 생성된 임시 디렉토리를 정리합니다.
#
# @return (임시 디렉토리 삭제)
##
cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}

##
# diff 명령어 설치 여부를 확인하고 미설치 시 패키지 관리자로 자동 설치합니다.
#
# @return (설치 진행 결과 출력)
##
ensure_diff_installed() {
  if ! command -v diff >/dev/null 2>&1; then
    echo "  ⚠️ 'diff' 명령어가 시스템에 설치되어 있지 않습니다."
    echo "  ⏳ 패키지 관리자(apt, dnf)를 이용하여 'diffutils' 자동 설치를 시도합니다..."
    
    if command -v apt >/dev/null 2>&1; then
      sudo apt update -y >/dev/null 2>&1 || true
      sudo apt install -y diffutils || { echo "  ❌ 'diffutils' 설치에 실패했습니다."; exit 1; }
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y diffutils || { echo "  ❌ 'diffutils' 설치에 실패했습니다."; exit 1; }
    else
      echo "  ❌ 지원하는 패키지 관리자(apt, dnf)를 찾을 수 없습니다."
      exit 1
    fi
    echo "  ✅ 'diffutils' 설치가 완료되었습니다."
  fi
}

##
# 현재 시각을 밀리초(ms) 단위로 반환합니다.
#
# @return {integer} 밀리초 epoch time
##
get_time_ms() {
  date +%s%3N 2>/dev/null || echo "$(( $(date +%s) * 1000 ))"
}

##
# 밀리초 단위 시간을 상위 0 단위를 생략한 '##일 ##시간 ##분 ##초 ###ms' 포맷으로 변환합니다.
#
# @param $1 {integer} 밀리초(ms) 값
#
# @return {string} 포맷팅된 시간 문자열
##
format_elapsed_time() {
  local total_ms="$1"
  local ms=$(( total_ms % 1000 ))
  local total_sec=$(( total_ms / 1000 ))
  local sec=$(( total_sec % 60 ))
  local total_min=$(( total_sec / 60 ))
  local min=$(( total_min % 60 ))
  local total_hr=$(( total_min / 60 ))
  local hr=$(( total_hr % 24 ))
  local day=$(( total_hr / 24 ))

  local res=""
  if [[ $day -gt 0 ]]; then
    res=$(printf "%d일 %02d시간 %02d분 %02d초 %03dms" "$day" "$hr" "$min" "$sec" "$ms")
  elif [[ $hr -gt 0 ]]; then
    res=$(printf "%02d시간 %02d분 %02d초 %03dms" "$hr" "$min" "$sec" "$ms")
  elif [[ $min -gt 0 ]]; then
    res=$(printf "%02d분 %02d초 %03dms" "$min" "$sec" "$ms")
  elif [[ $sec -gt 0 ]]; then
    res=$(printf "%02d초 %03dms" "$sec" "$ms")
  else
    res=$(printf "%dms" "$ms")
  fi
  echo "$res"
}

##
# 파일의 SHA-256 또는 MD5 해시값을 계산합니다.
#
# @param $1 {string} 파일 경로
#
# @return {string} 계산된 해시값
##
calculate_hash() {
  local target_path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target_path" | awk '{print $1}'
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum "$target_path" | awk '{print $1}'
  else
    shasum -a 256 "$target_path" | awk '{print $1}'
  fi
}

##
# 파일 내용 중 주석(#), 빈 줄, trailing whitespace를 제거하여 정규화 스트림을 생성합니다.
# (시작 부분의 whitespace는 보존함)
#
# @param $1 {string} 원본 파일 경로
# @param $2 {string} 정규화 결과를 저장할 임시 파일 경로
#
# @return (임시 파일 생성)
##
normalize_file() {
  local src_path="$1"
  local out_path="$2"
  sed -E -e 's/[[:space:]]+$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$src_path" > "$out_path"
}

##
# 두 파일이 물리적으로 동일한 파일(같은 Inode)인지 검증합니다.
#
# @param $1 {string} 첫 번째 파일 경로
# @param $2 {string} 두 번째 파일 경로
#
# @return {integer} 동일 파일일 경우 0, 다를 경우 1 반환
##
is_same_physical_file() {
  local file1="$1"
  local file2="$2"

  if [[ "$file1" -ef "$file2" ]]; then
    return 0
  fi
  return 1
}

##
# 대상 파일 탐색 및 수집 진행 상황을 터미널 상단에 실시간으로 출력합니다.
#
# @param $1 {integer} 발견된 대상 파일 개수
# @param $2 {integer} 진행(스캔)한 파일 개수
#
# @return (터미널 단일 라인 동적 출력)
##
print_search_progress() {
  local found="$1"
  local scanned="$2"
  printf "\r\033[K📂 [대상 파일 탐색 및 수집 중] %d / %d..." "$found" "$scanned"
}

##
# 디렉토리를 탐색하며 비교 대상 파일을 수집합니다.
# 최적화를 위해 find 명령어로 하위 전체를 고속 탐색합니다.
#
# @param $1 {string} 현재 탐색 디렉토리 경로
#
# @return (전역 배열 TARGET_FILE_LIST 에 절대경로 추가)
##
collect_target_files() {
  local cdir="$1"
  local f=""
  local abs_f=""

  while IFS= read -r -d '' f; do
    ((SCANNED_COUNT++)) || true
    abs_f="$(cd "$(dirname "$f")" 2>/dev/null && pwd)/$(basename "$f")"
    if ! is_same_physical_file "$abs_f" "$ABS_SOURCE_FILE"; then
      TARGET_FILE_LIST+=("$abs_f")
      ((FOUND_COUNT++)) || true
    fi
    print_search_progress "$FOUND_COUNT" "$SCANNED_COUNT"
  done < <(find "$cdir" -type f -name "$FILE_PATTERN" -print0 2>/dev/null || true)
}

##
# 단일 파일에 대해 2단계 비교(해시 및 정규화 diff)를 수행합니다.
#
# @param $1 {string} 대상 파일 절대 경로
# @param $2 {string} 정규화된 기준 파일 경로
# @param $3 {string} 기준 파일 해시값
#
# @return (전역 배열 IDENTICAL_FILES 또는 DIFFERENT_FILES 에 추가)
##
compare_single_file() {
  local target_f="$1"
  local norm_src="$2"
  local src_hash="$3"
  local target_hash=""
  local norm_target=""
  local diff_status=0

  # Pass 1: 해시값 1차 비교
  target_hash=$(calculate_hash "$target_f")
  if [[ "$src_hash" == "$target_hash" ]]; then
    IDENTICAL_FILES+=("$target_f")
    return 0
  fi

  # Pass 2: 정규화 스트림 diff 비교
  norm_target="$TMP_DIR/target.norm"
  normalize_file "$target_f" "$norm_target"

  # diff의 반환 코드 1(내용 다름)을 안전하게 포획하여 set -e 오작동 방지
  diff -u "$norm_src" "$norm_target" >/dev/null 2>&1 || diff_status=$?

  if [[ $diff_status -eq 0 ]]; then
    IDENTICAL_FILES+=("$target_f")
  else
    DIFFERENT_FILES+=("$target_f")
    
    # --copy-content 옵션 활성화 시 내용 복사 수행
    if [[ $COPY_CONTENT -eq 1 ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        COPIED_FILES+=("$target_f (가상 복사 완료)")
      else
        cp "$ABS_SOURCE_FILE" "$target_f"
        COPIED_FILES+=("$target_f (복사 완료)")
      fi
    fi
  fi
}

##
# 파일 비교 작업의 진행률 프로그래스 바를 터미널 상단에 출력합니다.
#
# @param $1 {integer} 현재 처리 개수
# @param $2 {integer} 전체 수집 파일 개수
#
# @return (터미널 단일 라인 동적 출력)
##
print_progress() {
  local current="$1"
  local total="$2"
  
  if [[ $total -le 0 ]]; then
    return 0
  fi

  local term_w
  term_w=$(tput cols 2>/dev/null || echo 120)
  if [[ ! "$term_w" =~ ^[0-9]+$ ]] || [[ "$term_w" -lt 60 ]]; then
    term_w=120
  fi

  local pct=$(( current * 100 / total ))
  local prefix_str="- ${current} / ${total}: "
  local suffix_str=" | ${pct}%"
  local p_len=${#prefix_str}
  local s_len=${#suffix_str}
  
  local bar_max_w=$(( term_w - p_len - s_len - 2 ))
  if [[ $bar_max_w -lt 10 ]]; then
    bar_max_w=10
  fi

  local filled_w=$(( pct * bar_max_w / 100 ))
  local empty_w=$(( bar_max_w - filled_w ))

  local filled_bar=""
  local empty_bar=""
  if [[ $filled_w -gt 0 ]]; then
    printf -v filled_bar '%*s' "$filled_w" ''
    filled_bar="${filled_bar// /-}"
  fi
  if [[ $empty_w -gt 0 ]]; then
    printf -v empty_bar '%*s' "$empty_w" ''
    empty_bar="${empty_bar// /.}"
  fi

  # \r (Carriage Return) 및 라인 클리어를 활용하여 터미널 동일 라인에 프로그래스 바 갱신
  printf "\r\033[K%s%s%s%s" "$prefix_str" "$filled_bar" "$empty_bar" "$suffix_str"
}

##
# 문자열의 실제 터미널 표시 너비(Display Width)를 계산합니다.
# (한글 및 이모지 등 2칸 점유 다중 바이트 문자 너비 정확 보정)
#
# @param $1 {string} 계산할 문자열
#
# @return {integer} 실제 화면 점유 칼럼 수
##
get_display_width() {
  local text="$1"
  local char_len=${#text}
  local byte_len
  byte_len=$(LC_ALL=C echo -n "$text" | wc -c)
  local extra_width=$(( (byte_len - char_len) / 2 ))
  echo $(( char_len + extra_width ))
}

##
# 비교 작업 결과를 터미널 넓이에 맞추어 동적 보고서로 출력합니다.
# --no-ne-files 설정 여부에 따라 단일 열 또는 2분할(Side-by-Side) 서식으로 출력합니다.
#
# @return (보고서 콘솔 출력)
##
print_report() {
  local term_w
  term_w=$(tput cols 2>/dev/null || echo 120)
  if [[ ! "$term_w" =~ ^[0-9]+$ ]] || [[ "$term_w" -lt 60 ]]; then
    term_w=120
  fi

  local ident_count=${#IDENTICAL_FILES[@]}
  local diff_count=${#DIFFERENT_FILES[@]}

  local left_header="✅ 동일한 파일 목록 (${ident_count} 개):"
  local right_header="❌ 동일하지 않은 파일 목록 (${diff_count} 개):"

  local bot_divider=""
  printf -v bot_divider '%*s' "$term_w" ''
  bot_divider="${bot_divider// /-}"

  # --no-ne-files 옵션이 설정된 경우: 단일 열 보고서 출력
  if [[ $NO_NE_FILES -eq 1 ]]; then
    local left_lines=()
    local f=""
    local rem=""
    local chunk_sz=$(( term_w - 4 ))
    if [[ $chunk_sz -lt 10 ]]; then chunk_sz=10; fi

    if [[ $ident_count -gt 0 ]]; then
      for f in "${IDENTICAL_FILES[@]}"; do
        if [[ $(( ${#f} + 4 )) -le $term_w ]]; then
          left_lines+=("  - $f")
        else
          rem="$f"
          left_lines+=("  - ${rem:0:$chunk_sz}")
          rem="${rem:$chunk_sz}"
          while [[ -n "$rem" ]]; do
            left_lines+=("    ${rem:0:$chunk_sz}")
            rem="${rem:$chunk_sz}"
          done
        fi
      done
    else
      left_lines+=("  (No identical files found.)")
    fi

    echo ""
    echo "📊 [비교 작업 완료 보고서]"
    echo "$bot_divider"
    echo "$left_header"
    for f in "${left_lines[@]}"; do
      echo "$f"
    done
    echo "$bot_divider"
  else
    # 기존 2분할(Side-by-Side) 보고서 출력
    local avail_w=$(( term_w - 3 ))
    local col1_w=$(( avail_w / 2 ))
    local col2_w=$(( avail_w - col1_w ))

    local left_lines=()
    local right_lines=()
    local f=""
    local rem=""
    
    local chunk_sz_1=$(( col1_w - 4 ))
    local chunk_sz_2=$(( col2_w - 4 ))

    if [[ $chunk_sz_1 -lt 10 ]]; then chunk_sz_1=10; fi
    if [[ $chunk_sz_2 -lt 10 ]]; then chunk_sz_2=10; fi

    if [[ $ident_count -gt 0 ]]; then
      for f in "${IDENTICAL_FILES[@]}"; do
        if [[ $(( ${#f} + 4 )) -le $col1_w ]]; then
          left_lines+=("  - $f")
        else
          rem="$f"
          left_lines+=("  - ${rem:0:$chunk_sz_1}")
          rem="${rem:$chunk_sz_1}"
          while [[ -n "$rem" ]]; do
            left_lines+=("    ${rem:0:$chunk_sz_1}")
            rem="${rem:$chunk_sz_1}"
          done
        fi
      done
    else
      left_lines+=("  (No identical files found.)")
    fi

    if [[ $diff_count -gt 0 ]]; then
      for f in "${DIFFERENT_FILES[@]}"; do
        if [[ $(( ${#f} + 4 )) -le $col2_w ]]; then
          right_lines+=("  - $f")
        else
          rem="$f"
          right_lines+=("  - ${rem:0:$chunk_sz_2}")
          rem="${rem:$chunk_sz_2}"
          while [[ -n "$rem" ]]; do
            right_lines+=("    ${rem:0:$chunk_sz_2}")
            rem="${rem:$chunk_sz_2}"
          done
        fi
      done
    else
      right_lines+=("  (No differing files found.)")
    fi

    local left_hdr_disp_w
    left_hdr_disp_w=$(get_display_width "$left_header")
    local left_hdr_pad=$(( col1_w - left_hdr_disp_w ))
    if [[ $left_hdr_pad -lt 0 ]]; then left_hdr_pad=0; fi

    local top_divider_left=""
    local top_divider_right=""

    printf -v top_divider_left '%*s' "$col1_w" ''
    top_divider_left="${top_divider_left// /-}"
    printf -v top_divider_right '%*s' "$col2_w" ''
    top_divider_right="${top_divider_right// /-}"

    echo ""
    echo "📊 [비교 작업 완료 보고서]"
    echo "${top_divider_left}-|-${top_divider_right}"
    printf "%s%*s | %s\n" "$left_header" "$left_hdr_pad" "" "$right_header"

    local max_idx=${#left_lines[@]}
    if [[ ${#right_lines[@]} -gt $max_idx ]]; then
      max_idx=${#right_lines[@]}
    fi

    local i=0
    local l_text=""
    local r_text=""
    local l_disp_w=0
    local l_pad=0

    while [[ $i -lt $max_idx ]]; do
      l_text="${left_lines[$i]:-}"
      r_text="${right_lines[$i]:-}"

      l_disp_w=$(get_display_width "$l_text")
      l_pad=$(( col1_w - l_disp_w ))
      if [[ $l_pad -lt 0 ]]; then l_pad=0; fi

      printf "%s%*s | %s\n" "$l_text" "$l_pad" "" "$r_text"
      ((i++)) || true
    done

    echo "$bot_divider"
  fi

  # --copy-content 옵션 실행 결과 보고서 출력
  if [[ $COPY_CONTENT -eq 1 ]]; then
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "📋 [파일 내용 복사 변경 보고서] (${#COPIED_FILES[@]} 개):"
    if [[ ${#COPIED_FILES[@]} -gt 0 ]]; then
      local cf=""
      for cf in "${COPIED_FILES[@]}"; do
        echo "  - $cf"
      done
    else
      echo "  (복사 변경된 파일이 없습니다.)"
    fi
    echo "--------------------------------------------------------------------------------"
  fi
}

# 트랩 등록
trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR
trap cleanup EXIT

# 파라미터 파싱 (전역 스코프 - local 키워드 미사용)
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help "" ""
      exit 0
      ;;
    -d|--directory)
      shift; TARGET_DIR="${1:-.}" ;;
    -s|--source)
      shift; SOURCE_FILE="${1:-}" ;;
    -f|--file)
      shift; FILE_PATTERN="${1:-}" ;;
    --copy-content)
      COPY_CONTENT=1 ;;
    --no-ne-files)
      NO_NE_FILES=1 ;;
    --dry-run)
      DRY_RUN=1 ;;
    -*)
      help "지원하지 않는 옵션입니다: $1" "$LINENO"
      exit 1 ;;
    *)
      help "잘못된 파라미터 형식입니다: $1" "$LINENO"
      exit 1 ;;
  esac
  shift
done

# 파라미터 트림(Trim) 정제
TARGET_DIR=$(echo "$TARGET_DIR" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
SOURCE_FILE=$(echo "$SOURCE_FILE" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
FILE_PATTERN=$(echo "$FILE_PATTERN" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')

# 파라미터 기본값 보정
TARGET_DIR="${TARGET_DIR:-.}"

# 필수 옵션 및 유효성 검증
if [[ -z "$SOURCE_FILE" || -z "$FILE_PATTERN" ]]; then
  help "기준 파일(-s)과 검색 대상 파일 패턴(-f)은 필수 입력 사항입니다." "$LINENO"
  exit 1
fi

if [[ ! -f "$SOURCE_FILE" || ! -r "$SOURCE_FILE" ]]; then
  help "비교 기준 파일이 존재하지 않거나 읽기 권한이 없습니다: $SOURCE_FILE" "$LINENO"
  exit 1
fi

if [[ ! -d "$TARGET_DIR" || ! -r "$TARGET_DIR" ]]; then
  help "작업 대상 디렉토리가 존재하지 않거나 읽기 권한이 없습니다: $TARGET_DIR" "$LINENO"
  exit 1
fi

# 의존성 검증
ensure_diff_installed

# 기준 파일 및 대상 디렉토리 절대 경로 전환
ABS_SOURCE_FILE="$(cd "$(dirname "$SOURCE_FILE")" 2>/dev/null && pwd)/$(basename "$SOURCE_FILE")"
ABS_TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)"

# 격리된 임시 디렉토리 생성
TMP_DIR=$(mktemp -d)

# 기준 파일 정규화 및 해시 계산
NORM_SOURCE_FILE="$TMP_DIR/source.norm"
normalize_file "$ABS_SOURCE_FILE" "$NORM_SOURCE_FILE"
SOURCE_HASH=$(calculate_hash "$ABS_SOURCE_FILE")

echo "================================================================================"
echo "🚀 파일 내용 정밀 비교 작업을 시작합니다..."
echo "  - 기준 파일     : $ABS_SOURCE_FILE"
echo "  - 대상 디렉토리 : $ABS_TARGET_DIR"
echo "  - 검색 패턴     : $FILE_PATTERN"
if [[ $COPY_CONTENT -eq 1 ]]; then
  echo "  - 내용 복사     : 활성화 (--copy-content)"
fi
if [[ $NO_NE_FILES -eq 1 ]]; then
  echo "  - 보고서 필터   : 동일하지 않은 파일 목록 제외 (--no-ne-files)"
fi
if [[ $DRY_RUN -eq 1 ]]; then
  echo "  - 모드           : 가상 실행 모드 (DRY-RUN)"
fi
echo "================================================================================"

# 탐색 상태 실시간 출력 및 소요 시간 측정 시작
SCANNED_COUNT=0
FOUND_COUNT=0
print_search_progress 0 0

SEARCH_START_MS=$(get_time_ms)
collect_target_files "$ABS_TARGET_DIR"
SEARCH_END_MS=$(get_time_ms)

SEARCH_ELAPSED_MS=$(( SEARCH_END_MS - SEARCH_START_MS ))
if [[ $SEARCH_ELAPSED_MS -lt 0 ]]; then SEARCH_ELAPSED_MS=0; fi
SEARCH_TIME_STR=$(format_elapsed_time "$SEARCH_ELAPSED_MS")

TOTAL_TARGET_COUNT=${#TARGET_FILE_LIST[@]}
echo "" # 프로그래스 바 줄바꿈 마무리
echo "  ✅ 수집 완료: 총 ${TOTAL_TARGET_COUNT} 개 대상 파일 발견 (⏱️  ${SEARCH_TIME_STR})"
echo ""

echo "🔍 [파일 비교 진행 중]"

# 2단계 비교 수행 및 진행률 표시
CUR_idx=0
if [[ $TOTAL_TARGET_COUNT -gt 0 ]]; then
  for target_f_item in "${TARGET_FILE_LIST[@]:-}"; do
    if [[ -z "$target_f_item" ]]; then continue; fi
    ((CUR_idx++)) || true
    print_progress "$CUR_idx" "$TOTAL_TARGET_COUNT"
    compare_single_file "$target_f_item" "$NORM_SOURCE_FILE" "$SOURCE_HASH"
  done
  echo "" # 프로그래스 바 줄바꿈 마무리
else
  print_progress 0 0
  echo ""
fi

# 보고서 출력
print_report

echo "🏁 모든 처리가 완료되었습니다."
exit 0