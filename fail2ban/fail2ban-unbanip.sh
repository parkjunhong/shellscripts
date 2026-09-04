#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-09-03
# @desc : support RHEL 7 or higher, Oracle Linux 7 or higher, Ubuntu 18.04 or higher, RockyOS 8 or higher, CentOS 7 or higher
# @installation : 
# 1. insert 'source <path>/fail2ban-unbanip.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/fail2ban-unbanip.sh' into /etc/bashrc for all users.
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
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack"
    local idx=1
    for func in "${FUNCNAME[@]:1}"
    do
      printf "$formatr" "["$idx"]" "$func"
      ((idx++)) || true
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi
  echo
  echo "사용법 (Usage): ./$FILENAME [옵션]"
  echo ""
  echo "[설명]"
  echo "  Fail2ban 감옥(Jail)에 차단된 특정 IP를 안전하게 해제(unbanip)합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --jail <감옥명>   Fail2ban 감옥(Jail) 이름 (필수)"
  echo "  --ip <IP주소>     차단 해제할 대상 IP 주소 (IPv4 또는 IPv6, 필수)"
  echo "  --help            도움말을 출력하고 종료합니다."
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

# 전역 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
JAIL_NAME=""
TARGET_IP=""

FAIL2BAN_CMD=()

##
# 시스템의 Fail2ban 바이너리 존재 및 데몬 소켓 통신 상태를 검증합니다.
#
# @param 없음
#
# @return (전역 배열 FAIL2BAN_CMD 초기화)
##
ensure_fail2ban_engine() {
  if ! command -v fail2ban-client >/dev/null 2>&1; then
    help "Fail2ban 바이너리(fail2ban-client)가 시스템에 설치되어 있지 않습니다." "$LINENO"
    exit 1
  fi

  if (( EUID == 0 )); then
    FAIL2BAN_CMD=(fail2ban-client)
  else
    if ! command -v sudo >/dev/null 2>&1; then
      help "Fail2ban 제어를 위해 sudo 명령어가 필요하나 시스템에 존재하지 않습니다." "$LINENO"
      exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
      echo "🔐 [AUTH] Fail2ban 데몬 제어를 위해 sudo 권한 확인이 필요합니다."
      sudo -v || {
        help "sudo 권한 인증에 실패했습니다." "$LINENO"
        exit 1
      }
    fi
    FAIL2BAN_CMD=(sudo fail2ban-client)
  fi

  local ping_response=""
  ping_response="$("${FAIL2BAN_CMD[@]}" ping 2>&1 || true)"
  if [[ "$ping_response" != *"Server replied: pong"* ]]; then
    help "Fail2ban 데몬이 실행 중이지 않거나 소켓에 접근할 수 없습니다 -> $ping_response" "$LINENO"
    exit 1
  fi
}

##
# 지정된 Jail이 Fail2ban에 실제로 활성화되어 있는지 검증합니다.
#
# @param $1 {string} 검증할 Jail 이름
#
# @return (유효하지 않을 경우 exit 1)
##
validate_jail_exists() {
  local target_jail="$1"
  local status_output=""

  status_output="$("${FAIL2BAN_CMD[@]}" status "$target_jail" 2>&1 || true)"
  if [[ "$status_output" == *"Sorry, but the jail"* ]] || [[ "$status_output" == *"does not exist"* ]]; then
    help "지정한 Jail이 존재하지 않거나 활성화되어 있지 않습니다 -> '$target_jail'" "$LINENO"
    exit 1
  fi
}

##
# 입력받은 IP 주소가 올바른 IPv4 또는 IPv6 형식인지 정규식으로 검증합니다.
#
# @param $1 {string} 검증할 IP 주소 문자열
#
# @return (유효하지 않을 경우 exit 1)
##
validate_ip_address() {
  local ip="$1"

  # IPv4 표준 정규식 (각 옥텟 0~255)
  local ipv4_regex='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
  # IPv6 표준 및 축약형 정규식
  local ipv6_regex='^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,7}:$|^([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|^::$|^([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|^([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|^([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}$|^([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}$|^[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})$'

  if [[ "$ip" =~ $ipv4_regex ]] || [[ "$ip" =~ $ipv6_regex ]]; then
    return 0
  fi

  help "유효한 IPv4 또는 IPv6 주소 형식이 아닙니다 -> '$ip'" "$LINENO"
  exit 1
}

##
# 대상 IP가 해당 Jail에 현재 차단되어 있는지 확인합니다.
#
# @param $1 {string} Jail 이름
# @param $2 {string} 대상 IP
#
# @return {integer} 차단 중이면 0, 아니면 1
##
is_ip_banned() {
  local jail="$1"
  local ip="$2"
  local banned_ips=""

  banned_ips="$("${FAIL2BAN_CMD[@]}" status "$jail" 2>/dev/null | grep -E 'Banned IP list:' | sed -E 's/.*Banned IP list:[[:space:]]*//' || true)"

  local b_ip=""
  for b_ip in $banned_ips; do
    if [[ "$b_ip" == "$ip" ]]; then
      return 0
    fi
  done

  return 1
}

##
# Fail2ban 명령을 호출하여 차단 해제를 수행합니다.
#
# @param $1 {string} 대상 Jail 명칭
# @param $2 {string} 차단 해제할 IP
#
# @return (해제 결과 콘솔 출력)
##
execute_unbanip() {
  local jail="$1"
  local ip="$2"

  echo "================================================================================"
  echo "🚀 [START] Fail2ban 차단 IP 해제(unbanip) 작업을 시작합니다..."
  echo "  - 대상 Jail : $jail"
  echo "  - 대상 IP   : $ip"
  echo "================================================================================"

  echo "🔍 [CHECK] 현재 감옥 내 차단 상태를 조회 중입니다..."
  if ! is_ip_banned "$jail" "$ip"; then
    echo ""
    echo "ℹ️  [NOTICE] 대상 IP '$ip' 는 현재 '$jail' 감옥에 차단되어 있지 않습니다."
    echo "✅ [SUCCESS] 추가 조치 없이 안전하게 종료합니다."
    echo "================================================================================"
    return 0
  fi

  echo "⏳ [PROCESSING] 차단 해제 명령을 전송합니다 (fail2ban-client set $jail unbanip $ip) ..."
  local result=""
  result="$("${FAIL2BAN_CMD[@]}" set "$jail" unbanip "$ip" 2>&1)"

  echo ""
  if [[ "$result" == "1" ]] || [[ "$result" == "$ip" ]]; then
    echo "🎉 [SUCCESS] IP 차단이 성공적으로 해제되었습니다!"
    echo "  - 결과: $ip (Jail: $jail)"
  elif [[ "$result" == "0" ]]; then
    echo "ℹ️  [NOTICE] 차단 해제 대상이 없거나 이미 해제되었습니다 (결과: 0)."
  else
    echo "⚠️  [RESULT] 실행 결과: $result"
  fi
  echo "================================================================================"
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 명령줄 인자 배열
#
# @return (없음)
##
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -j|--jail)
        if [[ -z "${2:-}" || "$2" == -* ]]; then
          help "--jail 파라미터는 대상 Jail 이름을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        JAIL_NAME="$2"
        shift 2
        ;;
      -i|--ip)
        if [[ -z "${2:-}" || "$2" == -* ]]; then
          help "--ip 파라미터는 대상 IP 주소를 지정해야 합니다." "$LINENO"
          exit 1
        fi
        TARGET_IP="$2"
        shift 2
        ;;
      -h|--help)
        help "" ""
        exit 0
        ;;
      -*)
        help "지원하지 않는 옵션입니다 -> $1" "$LINENO"
        exit 1
        ;;
      *)
        help "잘못된 파라미터 형식입니다 -> $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  if [ -z "$JAIL_NAME" ]; then
    help "--jail 옵션을 통해 대상 Jail 이름을 반드시 지정해야 합니다." "$LINENO"
    exit 1
  fi

  if [ -z "$TARGET_IP" ]; then
    help "--ip 옵션을 통해 해제할 대상 IP 주소를 반드시 지정해야 합니다." "$LINENO"
    exit 1
  fi

  validate_ip_address "$TARGET_IP"
  ensure_fail2ban_engine
  validate_jail_exists "$JAIL_NAME"

  execute_unbanip "$JAIL_NAME" "$TARGET_IP"
}

main "$@"
exit 0
