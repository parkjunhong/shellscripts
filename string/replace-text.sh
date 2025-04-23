#!/usr/bin/env bash

help() {
  local script_name
  script_name=$(basename "$0")
  echo "Usage: $script_name -t <target> -r <replace> [options]"
  echo ""
  echo "Required:"
  echo "  -t, --target             검색할 문자열"
  echo "  -r, --replace            치환할 문자열 (빈 문자열 = 삭제)"
  echo ""
  echo "Optional:"
  echo "  -d, --dir <dir>          검색 시작 디렉토리 (기본: 현재 디렉토리)"
  echo "  -f, --filename <rule>    파일명 매칭 (접두어: ^, 접미어: \$, 포함: 기본)"
  echo "  -x, --exclude <path>     제외할 디렉토리 (glob 허용)"
  echo "  -b, --backup             변경 전 백업 (.bak)"
  echo "      --dry-run            변경 없이 대상만 출력"
  echo "      --summary            요약 통계 출력"
  echo "      --log-output <file>  로그 저장 파일"
  echo "      --log-format <type>  로그 형식: plain (기본), json"
  echo "      --confirm-before-change  변경 전 사용자 확인"
  echo "  -h, --help               도움말"
  exit 1
}

filter_excludes() {
  local -n input_excludes=$1
  local temp=() filtered=()
  for path in "${input_excludes[@]}"; do
    skip=false
    for added in "${temp[@]}"; do
      if [[ "$path" == "$added"* ]]; then
        echo "[INFO] '$path' 는 '$added' 에 포함됩니다. 제외합니다."
        skip=true; break
      elif [[ "$added" == "$path"* ]]; then
        echo "[INFO] '$added' 는 '$path' 에 포함됩니다. 제외합니다."
        temp=("${temp[@]/$added}"); break
      elif [[ "$added" == "$path" ]]; then
        echo "[WARN] 중복된 exclude 경로: '$path'"; skip=true; break
      fi
    done
    $skip || temp+=("$path")
  done
  filtered_excludes=("${temp[@]}")
}

replace_in_files() {
  local search_dir="$1"
  local target="$2"
  local replacement="$3"
  local -n __filename_rules="$4"
  local -n __excludes="$5"
  local backup="$6"
  local dry_run="$7"
  local confirm="$8"
  local log_output="$9"
  local log_format="${10}"
  local summary="${11}"

  local esc_target esc_replacement
  esc_target=$(printf '%s\n' "$target" | sed -e 's/[\/&]/\\&/g')
  esc_replacement=$(printf '%s\n' "$replacement" | sed -e 's/[\/&]/\\&/g')

  local find_cmd=(find "$search_dir" -type f)
  for exclude in "${__excludes[@]}"; do
    find_cmd+=(! -path "$exclude*")
  done

  local count_total=0 count_modified=0 count_backup=0
  local plain_logs="" json_logs="["

  eval "${find_cmd[@]}" | while read -r file; do
    count_total=$((count_total + 1))
    local filename=$(basename "$file")
    local matched=false

    if [[ ${#__filename_rules[@]} -eq 0 ]]; then
      matched=true
    else
      for rule in "${__filename_rules[@]}"; do
        [[ "$rule" == ^* ]] && [[ "$filename" == "${rule#^}"* ]] && matched=true && break
        [[ "$rule" == *\$ ]] && [[ "$filename" == *"${rule%\$}" ]] && matched=true && break
        [[ "$filename" == *"$rule"* ]] && matched=true && break
      done
    fi

    if $matched && grep -q -- "$target" "$file"; then
      count_modified=$((count_modified + 1))
      echo "[MATCHED] $file"

      # 컬러 강조된 grep 결과 출력
      grep --color=always -n -- "$target" "$file" | while IFS=: read -r lineno linecontent; do
        echo "$file | $lineno | $linecontent"
      done

      if [[ "$dry_run" == "false" ]]; then
        if [[ "$confirm" == "true" ]]; then
          read -rp "Replace in $file? [y/N] " yn
          [[ ! "$yn" =~ ^[Yy]$ ]] && continue
        fi
        [[ "$backup" == "true" ]] && cp "$file" "$file.bak" && echo "[BACKUP] $file" && count_backup=$((count_backup + 1))
        sed -i "s/${esc_target}/${esc_replacement}/g" "$file"
      fi

      if [[ "$log_format" == "plain" ]]; then
        grep -n -- "$target" "$file" | while IFS=: read -r lineno linecontent; do
          plain_logs+="$file | $lineno | $linecontent"$'\n'
        done
      elif [[ "$log_format" == "json" ]]; then
        local matches=""
        matches=$(grep -n -- "$target" "$file" | sed 's/"/\\"/g' | awk -F: '{printf "{\"line\":%s,\"content\":\"%s\"},", $1, $2}')
        matches="[${matches%,}]"
        json_logs+=$(printf '{"file":"%s","backup":%s,"changed":true,"matches":%s},' "$file" "$backup" "$matches")
      fi
    fi
  done

  [[ "$log_format" == "json" ]] && json_logs="${json_logs%,}]"
  [[ -n "$log_output" ]] && echo "${log_format/plain/$plain_logs}${log_format/json/$json_logs}" > "$log_output" && echo "[INFO] 로그 저장됨: $log_output"

  [[ "$summary" == "true" ]] && {
    echo "[SUMMARY] 총 파일 수: $count_total"
    echo "[SUMMARY] 대상 파일 수: $count_modified"
    echo "[SUMMARY] 백업된 파일 수: $count_backup"
  }
}

main() {
  local search_dir="" target="" replacement=""
  local filename_rules=() excludes=()
  local backup=false dry_run=false confirm=false summary=false
  local log_output="" log_format="plain"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dir) search_dir="$2"; shift 2 ;;
      -t|--target) target="$2"; shift 2 ;;
      -r|--replace) replacement="$2"; shift 2 ;;
      -f|--filename) filename_rules+=("$2"); shift 2 ;;
      -x|--exclude) excludes+=("$2"); shift 2 ;;
      -b|--backup) backup=true; shift ;;
      --dry-run) dry_run=true; shift ;;
      --summary) summary=true; shift ;;
      --confirm-before-change) confirm=true; shift ;;
      --log-output) log_output="$2"; shift 2 ;;
      --log-format) log_format="$2"; shift 2 ;;
      -h|--help) help ;;
      *) echo "[ERROR] Unknown argument: $1"; help ;;
    esac
  done

  [[ -z "$search_dir" ]] && search_dir="." && echo "[INFO] 디렉토리가 설정되지 않아 현재 디렉토리(.)를 사용합니다."
  [[ -z "$target" || -z "$replacement" ]] && echo "[ERROR] 필수 인자 누락 (-t -r)" && help
  [[ ! -d "$search_dir" ]] && echo "[ERROR] 디렉토리 존재하지 않음: $search_dir" && exit 1

  filter_excludes excludes
  replace_in_files "$search_dir" "$target" "$replacement" filename_rules filtered_excludes "$backup" "$dry_run" "$confirm" "$log_output" "$log_format" "$summary"
}

main "$@"
exit 0

