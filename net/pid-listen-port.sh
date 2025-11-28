#!/usr/bin/env bash

set -Euo pipefail

help() {
  local me
  me="$(basename "$0")"
  cat <<EOF
Usage: sudo $me [--match <pattern> | <pattern>] [--net-state <state>] [--json [--pretty|--raw]] [-h|--help]

프로세스 커맨드라인에 <pattern> 이 포함된 PID를 찾아, 해당 PID들의 포트를 출력합니다.

옵션:
  -h, --help             이 도움말 출력
  --match <pattern>      프로세스 커맨드라인에 포함될 패턴(리터럴 문자열)
  --net-state, -ns <st>  netstat/ss 출력에서 상태 필터 (생략 시 모든 상태 출력)
                         → 접두어만 입력해도 매칭됨 (예: LIST, EST, ESTAB 등)
  --json                 JSON 형식으로 출력 (배열)
  --pretty               (--json과 함께) 들여쓰기된 JSON
  --raw                  (--json과 함께) compact JSON (기본값)

예시:
  sudo $me --match "nginx" --net-state ESTAB
  sudo $me "postgres" -ns LIST
  sudo $me --json --pretty --match "java"
EOF
}

##
# 커맨드라인에 pattern 이 포함된 프로세스의 PID 목록을 찾는다.
#
# @param $1 {string} pattern
# @return echo newline-separated PIDs
##
find_pids_by_cmdline() {
  local pattern="${1:-}"
  ps -aefww | grep -F -- "$pattern" | grep -v "[g]rep" | awk '{print $2}' || true
}

##
# 특정 PID의 netstat/ss 라인에서 원하는 state만 출력한다.
#
# @param $1 {string} pid
# @return echo filtered lines
##
gather_lines_for_pid() {
  local pid="$1"
  [[ -z "$pid" ]] && return 0

  if command -v netstat >/dev/null 2>&1; then
    netstat -napt 2>/dev/null | awk -v pid="$pid" -v sp="$NET_STATE" '
      NR>2 && $0 ~ pid {
        if (sp == "") { print $0 }
        else if ($6 ~ ("^" sp)) { print $0 }
      }
    '
  elif command -v ss >/dev/null 2>&1; then
    ss -lntp 2>/dev/null | awk -v pid="$pid" -v sp="$NET_STATE" '
      NR>1 && $0 ~ pid {
        if (sp == "") { print $0 }
        else if ($1 ~ ("^" sp)) { print $0 }
      }
    '
  else
    echo "ERROR: Neither netstat nor ss is available." >&2
    return 2
  fi
}

print_header() {
  if command -v netstat >/dev/null 2>&1; then
    netstat -napt 2>/dev/null | head -n 2
  elif command -v ss >/dev/null 2>&1; then
    ss -lntp 2>/dev/null | head -n 1
  fi
}

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

print_json() {
  local pretty="${1:-0}"
  local IND1 IND2 NL
  if [[ "$pretty" -eq 1 ]]; then IND1="  "; IND2="    "; NL=$'\n'; else IND1=""; IND2=""; NL=""; fi

  [[ "$pretty" -eq 1 ]] && printf '['"$NL" || printf '['
  local first_item=1
  for pid in "${PIDS[@]}"; do
    mapfile -t LINES < <(gather_lines_for_pid "$pid" || true)
    [[ $first_item -eq 0 ]] && { printf ','; [[ "$pretty" -eq 1 ]] && printf "$NL"; }
    [[ "$pretty" -eq 1 ]] && printf '%s{"pid":"%s","lines":[' "$IND1" "$(json_escape "$pid")" \
                          || printf '{"pid":"%s","lines":[' "$(json_escape "$pid")"
    local first_line=1
    for line in "${LINES[@]}"; do
      [[ $first_line -eq 0 ]] && printf ','
      if [[ "$pretty" -eq 1 ]]; then
        printf "$NL%s\"%s\"" "$IND2" "$(json_escape "$line")"
      else
        printf "\"%s\"" "$(json_escape "$line")"
      fi
      first_line=0
    done
    [[ "$pretty" -eq 1 ]] && { [[ "${#LINES[@]}" -gt 0 ]] && printf "$NL%s]" "$IND1" || printf ']'; printf '}'; } \
                          || printf ']}'
    first_item=0
  done
  [[ "$pretty" -eq 1 ]] && printf "$NL"
  printf ']\n'
}

# --- 옵션 처리 ---
JSON_OUTPUT=0
PRETTY_MODE=0
MATCH_PATTERN=""
NET_STATE=""

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) help; exit 0 ;;
    --json) JSON_OUTPUT=1; shift ;;
    --pretty) PRETTY_MODE=1; shift ;;
    --raw) PRETTY_MODE=0; shift ;;
    --match) shift; [[ $# -eq 0 ]] && { echo "ERROR: --match requires <pattern>." >&2; help; exit 1; }; MATCH_PATTERN="$1"; shift ;;
    --net-state|-ns) shift; [[ $# -eq 0 ]] && { echo "ERROR: --net-state requires <state>." >&2; help; exit 1; }; NET_STATE="$1"; shift ;;
    --*) echo "Unknown option: $1" >&2; help; exit 1 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

# positional argument → 패턴으로 사용
if [[ -z "$MATCH_PATTERN" && "${#POSITIONAL[@]}" -gt 0 ]]; then
  MATCH_PATTERN="${POSITIONAL[0]}"
fi

# --- 루트 권한 ---
if [[ "$EUID" -ne 0 ]]; then
  echo "Required 'root' privilige'."
  help
  exit 1
fi

# --- 필수 파라미터 검사 ---
if [[ -z "$MATCH_PATTERN" ]]; then
  echo "ERROR: Pattern is required (use --match <pattern> or positional argument)." >&2
  help
  exit 1
fi

# --- PID 조회 ---
readarray -t PIDS < <(find_pids_by_cmdline "$MATCH_PATTERN")
if [[ "${#PIDS[@]}" -eq 0 ]]; then
  echo "ERROR: No process found matching pattern: $MATCH_PATTERN" >&2
  exit 1
fi

# --- 출력 ---
if [[ "$JSON_OUTPUT" -eq 1 ]]; then
  print_json "$PRETTY_MODE"
else
  print_header
  echo "------:------:------:-----------------------:-----------------------:-----------:---------------"
  for pid in "${PIDS[@]}"; do
    if ! gather_lines_for_pid "$pid"; then
      echo "  (no ${NET_STATE:-ANY} lines or error for PID $pid)" >&2
    fi
  done
fi

exit 0

