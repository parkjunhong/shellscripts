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

draw_progress_bar() {
  local current=$1
  local total=$2

  local cols=$(tput cols)
  local label="[처리 중: $(printf '%06d' "$current") / $(printf '%06d' "$total")]"
  local label_width=${#label}
  local bar_width=$((cols - label_width - 10)) # extra buffer for padding

  (( bar_width < 10 )) && bar_width=10

  local percent=$((current * bar_width / total))
  local done=$(printf "%0.s*" $(seq 1 $percent))
  local left=$(printf "%0.s " $(seq 1 $((bar_width - percent))))

  # 줄 덮어쓰기 (\r) + \033[0K: 줄 끝까지 삭제
  echo -ne "\r\033[0K$label [$done$left]"
}

# Default values
TARGET_DIR=""
TARGET_NAME=""
BEFORE_FILE=""
AFTER_FILE=""
DRY_RUN=false
DIFF_ONLY=false
ROLLBACK_DIR=""
LOG_FILE="$(pwd)/replace-codeblocks.log"

# Option parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET_DIR="$2"; shift ;;
    --target-name) TARGET_NAME="$2"; shift ;;
    --before) BEFORE_FILE="$2"; shift ;;
    --after) AFTER_FILE="$2"; shift ;;
    --dry-run) DRY_RUN=true ;;
    --diff-only) DIFF_ONLY=true ;;
    --rollback) ROLLBACK_DIR="$2"; shift ;;
    -h|--help) help; exit 0 ;;
    *) help "[ERROR] Unknown option: $1" "$LINENO"; exit 1 ;;
  esac
  shift
done

# Validation
if [[ -n "$ROLLBACK_DIR" ]]; then
  [[ ! -d "$ROLLBACK_DIR" ]] && help "[ERROR] Rollback directory not found: $ROLLBACK_DIR" "$LINENO" && exit 1
else
  [[ -z "$TARGET_DIR" || -z "$TARGET_NAME" || -z "$BEFORE_FILE" || -z "$AFTER_FILE" ]] && help "[ERROR] Missing required arguments." "$LINENO" && exit 1
  [[ ! -d "$TARGET_DIR" ]] && help "[ERROR] Target directory not found: $TARGET_DIR" "$LINENO" && exit 1
  [[ ! -f "$BEFORE_FILE" ]] && help "[ERROR] Before file not found: $BEFORE_FILE" "$LINENO" && exit 1
  [[ ! -f "$AFTER_FILE" ]] && help "[ERROR] After file not found: $AFTER_FILE" "$LINENO" && exit 1
fi

# Prepare blocks
[[ -z "$ROLLBACK_DIR" ]] && BEFORE_BLOCK=$(<"$BEFORE_FILE") && AFTER_BLOCK=$(<"$AFTER_FILE")

# Discover files
if [[ -n "$ROLLBACK_DIR" ]]; then
  mapfile -t FILES < <(find "$TARGET_DIR" -type f -name "$TARGET_NAME" -exec test -f "$ROLLBACK_DIR/{}" \; -print)
else
  mapfile -t FILES < <(find "$TARGET_DIR" -type f -name "$TARGET_NAME")
fi

TOTAL=${#FILES[@]}
CURRENT=0
NO_MATCH=0
DIFF_MATCH=0
MODIFIED=0

LOG_PATHS=()

for FILE in "${FILES[@]}"; do
  ((CURRENT++))
  draw_progress_bar "$CURRENT" "$TOTAL"

  if [[ -n "$ROLLBACK_DIR" ]]; then
    ORIG="$FILE"
    BACKUP="$ROLLBACK_DIR/$FILE"
    [[ -f "$BACKUP" ]] && cp "$BACKUP" "$ORIG"
    continue
  fi

  if ! grep -Fq "$BEFORE_BLOCK" "$FILE"; then
    ((NO_MATCH++))
    LOG_PATHS+=("1:$FILE")
    continue
  fi

  if ! grep -Fx "$BEFORE_BLOCK" "$FILE" > /dev/null; then
    ((DIFF_MATCH++))
    LOG_PATHS+=("2:$FILE")
    continue
  fi

  if [[ "$DRY_RUN" == false && "$DIFF_ONLY" == false ]]; then
    BACKUP_DIR="$(dirname "$FILE")/.rollback_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$FILE" "$BACKUP_DIR/$(basename "$FILE").bak"
    awk -v before="$BEFORE_BLOCK" -v after="$AFTER_BLOCK" '
      BEGIN { RS = ORS = ""; subed=0 }
      {
        if (index($0, before)) {
          sub(before, after)
          subed=1
        }
        print
      }
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    ((MODIFIED++))
    LOG_PATHS+=("3:$FILE")
  fi
done

echo
echo "[COMPLETE] 모든 파일 처리 완료"
echo
echo "1. '변경 전 블록'이 존재하지 않는 파일 개수: $NO_MATCH 개"
echo "2. '변경 전 블록'가 다른 파일 개수: $DIFF_MATCH 개"
echo "3. '변경 전 블록'이 '변경 후 블록'으로 변경된 파일 개수: $MODIFIED 개"
echo
echo "[LOG] 작업 결과 로그 저장됨: $LOG_FILE"

# Save to log
{
  echo "[TARGET] $TARGET_DIR"
  echo "[PATTERN] $TARGET_NAME"
  echo "[DATE] $(date '+%Y-%m-%d %H:%M:%S')"
  echo "======================================"
  for path in "${LOG_PATHS[@]}"; do
    case "$path" in
      1:*) echo "[NO_MATCH] ${path#1:}" ;;
      2:*) echo "[DIFF]     ${path#2:}" ;;
      3:*) echo "[MODIFIED] ${path#3:}" ;;
    esac
  done
} > "$LOG_FILE"

