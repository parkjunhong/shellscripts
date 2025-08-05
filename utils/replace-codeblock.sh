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
  echo "$FILENAME --target-dir <path> --target-name <filename> --before <file> --after <file> [--dry-run] [--diff-only] [--rollback <backup-dir>]"
  echo
  echo "Options:"
  echo "  --target-dir    : root directory to search for target files"
  echo "  --target-name   : name of the file to modify (e.g., deploy.sh)"
  echo "  --before        : file that contains the original code block"
  echo "  --after         : file that contains the replacement code block"
  echo "  --dry-run       : show what would be replaced without modifying files"
  echo "  --diff-only     : show files that differ from the original block"
  echo "  --rollback <dir>: rollback changes from the given backup directory"
  echo "  -h | --help     : show this help message"
}

ROLLBACK_DIR=""
DRY_RUN=0
DIFF_ONLY=0
LOG_FILE="replace-codeblocks.log"
: > "$LOG_FILE"

declare -a FILES_NOT_FOUND
declare -a FILES_DIFFERENT
declare -a FILES_REPLACED

normalize_block() {
  sed 's/[[:space:]]\+$//' "$1" | tr '\t' ' ' | tr -s ' '
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case "$key" in
    -h|--help) help ""; exit 0;;
    --target-dir) TARGET_DIR="$2"; shift 2;;
    --target-name) TARGET_NAME="$2"; shift 2;;
    --before) BEFORE_BLOCK_FILE="$2"; shift 2;;
    --after) AFTER_BLOCK_FILE="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --diff-only) DIFF_ONLY=1; shift;;
    --rollback) ROLLBACK_DIR="$2"; shift 2;;
    *) help "Unknown option: $1" "$LINENO"; exit 1;;
  esac
done

NOW=$(date +%Y%m%d_%H%M%S)

if [[ -n "$ROLLBACK_DIR" ]]; then
  echo "[ROLLBACK] 복원 시작: $ROLLBACK_DIR"
  find . -type d -name "$ROLLBACK_DIR" | while read -r rollback_dir; do
    find "$rollback_dir" -name "*.bak" | while read -r bak; do
      original_dir="$(dirname "$rollback_dir")"
      original_file="$original_dir/$(basename "$bak" .bak)"
      cp "$bak" "$original_file"
      echo "[RESTORED] $original_file"
    done
  done
  echo "[ROLLBACK] 완료"
  exit 0
fi

[[ ! -d "$TARGET_DIR" ]] && help "Not found: $TARGET_DIR" "$LINENO" && exit 1
[[ ! -f "$BEFORE_BLOCK_FILE" ]] && help "Not found: $BEFORE_BLOCK_FILE" "$LINENO" && exit 1
[[ ! -f "$AFTER_BLOCK_FILE" ]] && help "Not found: $AFTER_BLOCK_FILE" "$LINENO" && exit 1

NORMALIZED_BEFORE=$(mktemp)
normalize_block "$BEFORE_BLOCK_FILE" > "$NORMALIZED_BEFORE"
BEFORE_HASH=$(md5sum "$NORMALIZED_BEFORE" | awk '{print $1}')

TARGET_FILES=()
while IFS= read -r file; do TARGET_FILES+=("$file"); done < <(find "$TARGET_DIR" -type f -name "$TARGET_NAME")
TOTAL_FILES=${#TARGET_FILES[@]}
CURRENT=0
BAR_WIDTH=30

for FILE in "${TARGET_FILES[@]}"; do
  ((CURRENT++))
  PERCENT=$((CURRENT * BAR_WIDTH / TOTAL_FILES))
  BAR=$(printf '%*s' "$PERCENT" '' | tr ' ' '*')
  SPACES=$(printf '%*s' $((BAR_WIDTH - PERCENT)) '')
  echo -ne "\r[처리 중: $CURRENT / $TOTAL_FILES] [${BAR}${SPACES}]"

  MATCH_START=$(grep -n "^update_property(){$" "$FILE" | cut -d: -f1)
  if [[ -z "$MATCH_START" ]]; then
    FILES_NOT_FOUND+=("$(realpath "$FILE")")
    continue
  fi

  MATCH_END=$(tail -n +"$MATCH_START" "$FILE" | grep -n "^}$" | head -1 | cut -d: -f1)
  if [[ -z "$MATCH_END" ]]; then
    FILES_NOT_FOUND+=("$(realpath "$FILE")")
    continue
  fi
  MATCH_END=$((MATCH_START + MATCH_END - 1))

  TMP_BLOCK=$(mktemp)
  sed -n "${MATCH_START},${MATCH_END}p" "$FILE" > "$TMP_BLOCK"

  NORMALIZED_CURRENT=$(mktemp)
  normalize_block "$TMP_BLOCK" > "$NORMALIZED_CURRENT"
  CURRENT_HASH=$(md5sum "$NORMALIZED_CURRENT" | awk '{print $1}')
  rm -f "$TMP_BLOCK" "$NORMALIZED_CURRENT"

  if [[ "$CURRENT_HASH" != "$BEFORE_HASH" ]]; then
    FILES_DIFFERENT+=("$(realpath "$FILE")")
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    FILES_REPLACED+=("$(realpath "$FILE")")
    continue
  fi

  backup_dir="$(dirname "$FILE")/.rollback_backup_$NOW"
  mkdir -p "$backup_dir"
  cp "$FILE" "$backup_dir/$(basename "$FILE").bak"

  TMP_OUT=$(mktemp)
  head -n $((MATCH_START - 1)) "$FILE" > "$TMP_OUT"
  cat "$AFTER_BLOCK_FILE" >> "$TMP_OUT"
  tail -n +"$((MATCH_END + 1))" "$FILE" >> "$TMP_OUT"
  mv "$TMP_OUT" "$FILE"

  FILES_REPLACED+=("$(realpath "$FILE")")
done

echo
echo "[COMPLETE] 모든 파일 처리 완료"

{
  echo "1. '변경 전 블록'이 존재하지 않는 파일 개수: ${#FILES_NOT_FOUND[@]} 개"
  for f in "${FILES_NOT_FOUND[@]}"; do echo " - $f"; done
  echo
  echo "2. '변경 전 블록'가 다른 파일 개수: ${#FILES_DIFFERENT[@]} 개"
  for f in "${FILES_DIFFERENT[@]}"; do echo " - $f"; done
  echo
  echo "3. '변경 전 블록'이 '변경 후 블록'으로 변경된 파일 개수: ${#FILES_REPLACED[@]} 개"
  for f in "${FILES_REPLACED[@]}"; do echo " - $f"; done
  echo
} >> "$LOG_FILE"

printf "\n"
printf "1. '변경 전 블록'이 존재하지 않는 파일 개수: %'d 개\n" "${#FILES_NOT_FOUND[@]}"
printf "2. '변경 전 블록'가 다른 파일 개수: %'d 개\n" "${#FILES_DIFFERENT[@]}"
printf "3. '변경 전 블록'이 '변경 후 블록'으로 변경된 파일 개수: %'d 개\n" "${#FILES_REPLACED[@]}"
echo
echo "[LOG] 작업 결과 로그 저장됨: $(realpath "$LOG_FILE")"


