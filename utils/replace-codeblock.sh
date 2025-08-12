#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : replace code blocks in shell scripts
# @license  : Apache License 2.0
# @since    : 2025-08-05
# @desc     : support macOS 11.2.3, Ubuntu 18.04 or higher, CentOS 7 or higher
# @completion: replace-codeblock.completion
#   1. insert 'source <path>/replace-codeblock.completion' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

help() {
  local FILENAME=$(basename "$0")
  if [ ! -z "$1" ]; then
    local indent=10
    local formatl=" - %-${indent}s: %s\n"
    local formatr=" - %${indent}s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}; do
      printf "$formatr" "[$idx]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo
  echo "Usage:"
  echo "$FILENAME --target-dir <path> --target-name <filename> --before <file> --after <file> [--dry-run]"
  echo
  echo "Options:"
  echo "  --target-dir    : root directory to search for target files"
  echo "  --target-name   : name of the file to modify (e.g., deploy.sh)"
  echo "  --before        : file that contains the original code block"
  echo "  --after         : file that contains the replacement code block"
  echo "  --dry-run       : show what would be replaced without modifying files"
  echo "  -h | --help     : show this help message"
}

TARGET_DIR=""
TARGET_NAME=""
BEFORE_FILE=""
AFTER_FILE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift ;;
    --target-name) TARGET_NAME="$2"; shift ;;
    --before) BEFORE_FILE="$2"; shift ;;
    --after) AFTER_FILE="$2"; shift ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) help; exit 0 ;;
    *) help "[ERROR] Unknown option: $1" "$LINENO"; exit 1 ;;
  esac
  shift
done

[[ -z "$TARGET_DIR" || -z "$TARGET_NAME" || -z "$BEFORE_FILE" || -z "$AFTER_FILE" ]] && help "[ERROR] Missing required arguments." "$LINENO" && exit 1
[[ ! -d "$TARGET_DIR" ]] && help "[ERROR] Target directory not found: $TARGET_DIR" "$LINENO" && exit 1
[[ ! -f "$BEFORE_FILE" ]] && help "[ERROR] Before file not found: $BEFORE_FILE" "$LINENO" && exit 1
[[ ! -f "$AFTER_FILE" ]] && help "[ERROR] After file not found: $AFTER_FILE" "$LINENO" && exit 1

BEFORE_BLOCK=$(<"$BEFORE_FILE")
AFTER_BLOCK=$(<"$AFTER_FILE")

mapfile -t FILES < <(find "$TARGET_DIR" -type f -name "$TARGET_NAME")
TOTAL=${#FILES[@]}
CURRENT=0

NO_MATCH=0
NO_MATCH_FILES=()
REPLACED=0
REPLACED_FILES=()

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$(pwd)/replace-codeblocks-${TARGET_NAME}.log"

for FILE in "${FILES[@]}"; do
  ((CURRENT++))
  LABEL="[처리 중: $(printf "%06d" "$CURRENT") / $(printf "%06d" "$TOTAL")]"
  COLS=$(tput cols)
  PAD=$((COLS - ${#LABEL} - 8))
  PROGRESS=$(printf "%0.s*" $(seq 1 $((PAD * CURRENT / TOTAL))))
  printf "\r%s [%-*s]" "$LABEL" "$PAD" "$PROGRESS"

  FILE_CONTENT=$(<"$FILE")

  if [[ "$FILE_CONTENT" != *"$BEFORE_BLOCK"* ]]; then
    ((NO_MATCH++))
    NO_MATCH_FILES+=("$FILE")
    continue
  fi

  if $DRY_RUN; then
    ((REPLACED++))
    REPLACED_FILES+=("$FILE")
    continue
  fi

  BACKUP_DIR="$(dirname "$FILE")/.rollback_backup_$TIMESTAMP"
  mkdir -p "$BACKUP_DIR"
  cp "$FILE" "$BACKUP_DIR/$(basename "$FILE").bak"

  perl -0777 -i -pe "s/\Q$BEFORE_BLOCK\E/$AFTER_BLOCK/" "$FILE"
  ((REPLACED++))
  REPLACED_FILES+=("$FILE")
done

echo
{
  echo "1. '변경 전 블록'이 존재하지 않는 파일 개수: $NO_MATCH 개"
  for f in "${NO_MATCH_FILES[@]}"; do echo " - $f"; done
  echo "2. '변경 전 블록'이 '변경 후 블록'으로 변경된 파일 개수: $REPLACED 개"
  for f in "${REPLACED_FILES[@]}"; do echo " - $f"; done
} > "$LOG_FILE"

echo "[COMPLETE] 모든 파일 처리 완료"
echo
echo "1. '변경 전 블록'이 존재하지 않는 파일 개수: $NO_MATCH 개"
echo "2. '변경 전 블록'이 '변경 후 블록'으로 변경된 파일 개수: $REPLACED 개"
echo
echo "[LOG] 작업 결과 로그 저장됨: $LOG_FILE"

