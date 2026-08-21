#!/usr/bin/env bash
set -Eeuo pipefail

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : firewall-cmd zone info wrapper.
# @license  : Apache License 2.0
# @since    : 2026-08-21
# @desc     : support RHEL 7+, Oracle Linux 7+, Ubuntu 18.04+, RockyOS 8+, CentOS 7+
# @installation : 
#   1. insert 'source <path>/fwc-cli.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/fwc-cli.sh' into /etc/bashrc for all users.
# =======================================

readonly FILENAME=$(basename "$0")

##
# 스크립트의 사용법을 출력하거나 오류 발생 시 콜스택을 출력합니다.
#
# @param $1 {string}
# @param $2 {string}
#
# @return 사용법 문구 및 콜스택 출력
##
help(){
  if [ -n "${1:-}" ];
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
      printf "$formatr" "[$idx]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: $FILENAME [옵션]"
  echo "옵션:"
  echo "  --zone=<zone 이름>           정보를 조회/수정할 zone 이름 (여러 번 사용 가능)"
  echo "  --active-zone                활성화된 모든 zone의 정보 조회"
  echo "  --active-zone=<zone>[,<zone>] 지정한 zone이 활성화되어 있는지 확인 및 정보 조회 (콤마 구분)"
  echo "  --reload                     방화벽 설정 리로드 및 활성화된 zone 정보 조회"
  echo "  --permanent                  설정을 영구적(permanent)으로 적용"
  echo "  --clear-all                  지정된 zone의 모든 규칙 항목을 일괄 삭제 (가장 먼저 수행되며 개별 remove 무시)"
  echo "  --add-<항목>=<값>            지정된 zone에 규칙 추가 (콤마 구분)."
  echo "                               지원항목: sources, services, ports, protocols, forward-ports, source-ports,"
  echo "                                         icmp-blocks, rich-rules, interfaces"
  echo "  --remove-<항목>[=<값>]       지정된 zone에서 규칙 삭제 (콤마 구분). 값 생략 시 해당 항목의 모든 규칙 삭제"
  echo "                               지원항목: sources, services, ports, protocols, forward-ports, source-ports,"
  echo "                                         icmp-blocks, rich-rules, interfaces"
  echo "  -h, --help                   도움말 출력"
}

##
# 터미널 창의 너비에 맞춰 최대 70자까지 등호(=) 구분선을 동적으로 출력합니다.
#
# @return 등호(=) 구분선 문자열 출력
##
print_separator() {
  local cols=70
  if [ -t 1 ]; then
    cols=$(tput cols 2>/dev/null || echo "${COLUMNS:-70}")
  else
    cols="${COLUMNS:-70}"
  fi

  if ! [[ "$cols" =~ ^[0-9]+$ ]] || [ "$cols" -le 0 ]; then
    cols=70
  fi

  local sep_len=$(( cols < 70 ? cols : 70 ))
  local line
  printf -v line '%*s' "$sep_len" ''
  echo "${line// /=}"
}

##
# firewalld 데몬의 실행 상태를 검증합니다.
#
# @return 오류 시 프로그램 종료
##
check_firewalld() {
  if ! command -v firewall-cmd >/dev/null 2>&1; then
    help "firewall-cmd 명령어를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi

  if ! firewall-cmd --state >/dev/null 2>&1 && ! sudo firewall-cmd --state >/dev/null 2>&1; then
    help "firewalld 서비스가 실행 중이 아닙니다." "$LINENO"
    exit 1
  fi
}

##
# 콤마로 구분된 입력 문자열을 파싱하고 공백을 제거한 뒤 배열에 저장합니다.
#
# @param $1 {string} 파싱할 문자열 (콤마로 구분됨)
# @param $2 {string} 결과값을 저장할 대상 배열 이름
#
# @return 파싱된 데이터를 대상 배열에 할당
##
parse_and_store() {
  local input="${1:-}"
  local arr_name="${2:-}"
  if [ -z "$input" ]; then return 0; fi
  
  local items
  IFS=',' read -ra items <<< "$input"
  local item
  for item in "${items[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    if [ -n "$item" ]; then
      eval "$arr_name+=(\"\$item\")"
    fi
  done
}

##
# 시스템에 현재 활성화된 모든 zone 목록을 조회합니다.
#
# @return 활성화된 zone 이름 목록 출력 (줄바꿈 구분)
##
get_active_zones() {
  sudo firewall-cmd --get-active-zones 2>/dev/null | awk '!/^[ \t]/{print $1}'
}

##
# 지정된 zone의 상세 정보를 방화벽 데몬에 질의하여 출력합니다.
#
# @param $1 {string} 조회할 대상 zone 이름
#
# @return zone 상세 정보 문자열 출력
##
print_zone_info() {
  local zone_name="${1:-}"
  if [ -z "$zone_name" ]; then return 0; fi

  print_separator
  echo "🛡️  Zone: $zone_name"
  print_separator
  
  if ! sudo firewall-cmd --zone="$zone_name" --list-all 2>/dev/null; then
    echo ""
    echo "⚠️  '$zone_name' zone을 찾을 수 없거나 정보를 조회할 수 없습니다."
  fi
}

# -----------------------------------------------------------------------------
# 공용 추가/삭제 함수 정의
# -----------------------------------------------------------------------------

##
# 대상 zone에 여러 항목을 일괄 추가 또는 삭제하는 방화벽 명령을 실행합니다.
#
# @param $1 {string} 타겟 zone 이름
# @param $2 {string} 실행할 액션 옵션 (예: --add-source, --remove-port)
# @param $@ {array} 적용할 항목 값들의 목록
#
# @return 명령 실행 후 적용된 항목 정보 출력
##
apply_items() {
  local target_zone="${1:-}"
  local action="${2:-}"
  shift 2 || true
  if [ -z "$target_zone" ] || [ -z "$action" ]; then return 0; fi

  local item
  for item in "$@"; do
    if [ -n "$item" ]; then
      echo " - [$target_zone] $action: $item"
      "${local_cmd[@]}" --zone="$target_zone" "$action=$item" >/dev/null
    fi
  done
}

##
# 대상 zone의 특정 카테고리에 속한 모든 방화벽 규칙을 일괄 삭제합니다.
#
# @param $1 {string} 타겟 zone 이름
# @param $2 {string} 조회할 액션 리스트 옵션 (예: --list-sources)
# @param $3 {string} 삭제할 액션 옵션 (예: --remove-source)
#
# @return 일괄 삭제된 항목 리스트 출력
##
remove_all_items() {
  local target_zone="${1:-}"
  local action_list="${2:-}"
  local action_remove="${3:-}"
  
  local list_cmd=(sudo firewall-cmd --zone="$target_zone")
  [ "$PERMANENT_FLAG" == "true" ] && list_cmd+=("--permanent")

  if [ "$action_list" == "--list-rich-rules" ]; then
    while IFS= read -r rule; do
      rule="${rule#"${rule%%[![:space:]]*}"}"
      rule="${rule%"${rule##*[![:space:]]}"}"
      if [ -n "$rule" ]; then
        echo " - [$target_zone] $action_remove (전체): $rule"
        "${local_cmd[@]}" --zone="$target_zone" "$action_remove=$rule" >/dev/null
      fi
    done < <("${list_cmd[@]}" "$action_list" 2>/dev/null)
  else
    local raw_output
    raw_output=$("${list_cmd[@]}" "$action_list" 2>/dev/null || true)
    local item
    for item in $raw_output; do
      if [ -n "$item" ]; then
        echo " - [$target_zone] $action_remove (전체): $item"
        "${local_cmd[@]}" --zone="$target_zone" "$action_remove=$item" >/dev/null
      fi
    done
  fi
}

# -----------------------------------------------------------------------------
# 메인 로직 시작
# -----------------------------------------------------------------------------

check_firewalld

# 스크립트 실행 제어 플래그 선언
declare -a TARGET_ZONES=()
ACTIVE_ZONE_ALL="false"
declare -a ACTIVE_ZONE_TARGETS=()
RELOAD_FLAG="false"
PERMANENT_FLAG="false"
CLEAR_ALL_FLAG="false"
has_modification="false"

# 데이터 저장을 위한 명시적 배열 초기화
declare -a ADD_SOURCES=() ADD_SERVICES=() ADD_PORTS=() ADD_PROTOCOLS=()
declare -a ADD_FWD_PORTS=() ADD_SRC_PORTS=() ADD_ICMP_BLOCKS=() ADD_RICH_RULES=() ADD_INTERFACES=()

declare -a REM_SOURCES=() REM_SERVICES=() REM_PORTS=() REM_PROTOCOLS=()
declare -a REM_FWD_PORTS=() REM_SRC_PORTS=() REM_ICMP_BLOCKS=() REM_RICH_RULES=() REM_INTERFACES=()

# "모두 삭제" 플래그 초기화
REM_ALL_SOURCES="false"
REM_ALL_SERVICES="false"
REM_ALL_PORTS="false"
REM_ALL_PROTOCOLS="false"
REM_ALL_FWD_PORTS="false"
REM_ALL_SRC_PORTS="false"
REM_ALL_ICMP_BLOCKS="false"
REM_ALL_RICH_RULES="false"
REM_ALL_INTERFACES="false"

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --zone=*) TARGET_ZONES+=("${1#*=}"); shift ;;
    --active-zone) ACTIVE_ZONE_ALL="true"; shift ;;
    --active-zone=*) parse_and_store "${1#*=}" "ACTIVE_ZONE_TARGETS"; shift ;;
    --reload) RELOAD_FLAG="true"; shift ;;
    --permanent) PERMANENT_FLAG="true"; shift ;;
    --clear-all) CLEAR_ALL_FLAG="true"; has_modification="true"; shift ;;
    
    # Add 옵션
    --add-sources=*) parse_and_store "${1#*=}" "ADD_SOURCES"; has_modification="true"; shift ;;
    --add-services=*) parse_and_store "${1#*=}" "ADD_SERVICES"; has_modification="true"; shift ;;
    --add-ports=*) parse_and_store "${1#*=}" "ADD_PORTS"; has_modification="true"; shift ;;
    --add-protocols=*) parse_and_store "${1#*=}" "ADD_PROTOCOLS"; has_modification="true"; shift ;;
    --add-forward-ports=*) parse_and_store "${1#*=}" "ADD_FWD_PORTS"; has_modification="true"; shift ;;
    --add-source-ports=*) parse_and_store "${1#*=}" "ADD_SRC_PORTS"; has_modification="true"; shift ;;
    --add-icmp-blocks=*) parse_and_store "${1#*=}" "ADD_ICMP_BLOCKS"; has_modification="true"; shift ;;
    --add-rich-rules=*) parse_and_store "${1#*=}" "ADD_RICH_RULES"; has_modification="true"; shift ;;
    --add-interfaces=*) parse_and_store "${1#*=}" "ADD_INTERFACES"; has_modification="true"; shift ;;
    
    # Remove 옵션
    --remove-sources) REM_ALL_SOURCES="true"; has_modification="true"; shift ;;
    --remove-sources=*) parse_and_store "${1#*=}" "REM_SOURCES"; has_modification="true"; shift ;;
    --remove-services) REM_ALL_SERVICES="true"; has_modification="true"; shift ;;
    --remove-services=*) parse_and_store "${1#*=}" "REM_SERVICES"; has_modification="true"; shift ;;
    --remove-ports) REM_ALL_PORTS="true"; has_modification="true"; shift ;;
    --remove-ports=*) parse_and_store "${1#*=}" "REM_PORTS"; has_modification="true"; shift ;;
    --remove-protocols) REM_ALL_PROTOCOLS="true"; has_modification="true"; shift ;;
    --remove-protocols=*) parse_and_store "${1#*=}" "REM_PROTOCOLS"; has_modification="true"; shift ;;
    --remove-forward-ports) REM_ALL_FWD_PORTS="true"; has_modification="true"; shift ;;
    --remove-forward-ports=*) parse_and_store "${1#*=}" "REM_FWD_PORTS"; has_modification="true"; shift ;;
    --remove-source-ports) REM_ALL_SRC_PORTS="true"; has_modification="true"; shift ;;
    --remove-source-ports=*) parse_and_store "${1#*=}" "REM_SRC_PORTS"; has_modification="true"; shift ;;
    --remove-icmp-blocks) REM_ALL_ICMP_BLOCKS="true"; has_modification="true"; shift ;;
    --remove-icmp-blocks=*) parse_and_store "${1#*=}" "REM_ICMP_BLOCKS"; has_modification="true"; shift ;;
    --remove-rich-rules) REM_ALL_RICH_RULES="true"; has_modification="true"; shift ;;
    --remove-rich-rules=*) parse_and_store "${1#*=}" "REM_RICH_RULES"; has_modification="true"; shift ;;
    --remove-interfaces) REM_ALL_INTERFACES="true"; has_modification="true"; shift ;;
    --remove-interfaces=*) parse_and_store "${1#*=}" "REM_INTERFACES"; has_modification="true"; shift ;;
    
    -h|--help) help; exit 0 ;;
    *) help "알 수 없는 옵션입니다: $1" "$LINENO"; exit 1 ;;
  esac
done

if [ "$has_modification" == "true" ] && [ ${#TARGET_ZONES[@]} -eq 0 ]; then
  help "오류: --add-*, --remove-*, --clear-all 옵션을 사용할 때는 반드시 --zone=<이름> 옵션을 한 개 이상 지정해야 합니다." "$LINENO"
  exit 1
fi

if [ ${#TARGET_ZONES[@]} -eq 0 ] && [ "$ACTIVE_ZONE_ALL" == "false" ] && [ ${#ACTIVE_ZONE_TARGETS[@]} -eq 0 ] && [ "$RELOAD_FLAG" == "false" ] && [ "$has_modification" == "false" ]; then
  help "조회할 대상(--zone=<이름> 등) 또는 동작(--reload, --add-*, --remove-*, --clear-all)을 입력해 주세요." "$LINENO"
  exit 1
fi

# 0. 규칙 추가/삭제 처리
if [ "$has_modification" == "true" ]; then
  print_separator
  echo "🛡️  방화벽 규칙 변경 적용 중..."
  print_separator
  
  local_cmd=(sudo firewall-cmd)
  if [ "$PERMANENT_FLAG" == "true" ]; then
    local_cmd+=("--permanent")
    echo " 💾 [Permanent Mode] 설정이 영구적으로 저장/조회됩니다."
  fi

  for zone in "${TARGET_ZONES[@]}"; do
    if [ "$CLEAR_ALL_FLAG" == "true" ]; then
      echo " 🧹 [$zone] --clear-all: 모든 방화벽 규칙 항목을 삭제합니다..."
      remove_all_items "$zone" "--list-sources" "--remove-source"
      remove_all_items "$zone" "--list-services" "--remove-service"
      remove_all_items "$zone" "--list-ports" "--remove-port"
      remove_all_items "$zone" "--list-protocols" "--remove-protocol"
      remove_all_items "$zone" "--list-forward-ports" "--remove-forward-port"
      remove_all_items "$zone" "--list-source-ports" "--remove-source-port"
      remove_all_items "$zone" "--list-icmp-blocks" "--remove-icmp-block"
      remove_all_items "$zone" "--list-rich-rules" "--remove-rich-rule"
      remove_all_items "$zone" "--list-interfaces" "--remove-interface"
    else
      if [ "$REM_ALL_SOURCES" == "true" ]; then remove_all_items "$zone" "--list-sources" "--remove-source"; elif [ ${#REM_SOURCES[@]} -gt 0 ]; then apply_items "$zone" "--remove-source" "${REM_SOURCES[@]}"; fi
      if [ "$REM_ALL_SERVICES" == "true" ]; then remove_all_items "$zone" "--list-services" "--remove-service"; elif [ ${#REM_SERVICES[@]} -gt 0 ]; then apply_items "$zone" "--remove-service" "${REM_SERVICES[@]}"; fi
      if [ "$REM_ALL_PORTS" == "true" ]; then remove_all_items "$zone" "--list-ports" "--remove-port"; elif [ ${#REM_PORTS[@]} -gt 0 ]; then apply_items "$zone" "--remove-port" "${REM_PORTS[@]}"; fi
      if [ "$REM_ALL_PROTOCOLS" == "true" ]; then remove_all_items "$zone" "--list-protocols" "--remove-protocol"; elif [ ${#REM_PROTOCOLS[@]} -gt 0 ]; then apply_items "$zone" "--remove-protocol" "${REM_PROTOCOLS[@]}"; fi
      if [ "$REM_ALL_FWD_PORTS" == "true" ]; then remove_all_items "$zone" "--list-forward-ports" "--remove-forward-port"; elif [ ${#REM_FWD_PORTS[@]} -gt 0 ]; then apply_items "$zone" "--remove-forward-port" "${REM_FWD_PORTS[@]}"; fi
      if [ "$REM_ALL_SRC_PORTS" == "true" ]; then remove_all_items "$zone" "--list-source-ports" "--remove-source-port"; elif [ ${#REM_SRC_PORTS[@]} -gt 0 ]; then apply_items "$zone" "--remove-source-port" "${REM_SRC_PORTS[@]}"; fi
      if [ "$REM_ALL_ICMP_BLOCKS" == "true" ]; then remove_all_items "$zone" "--list-icmp-blocks" "--remove-icmp-block"; elif [ ${#REM_ICMP_BLOCKS[@]} -gt 0 ]; then apply_items "$zone" "--remove-icmp-block" "${REM_ICMP_BLOCKS[@]}"; fi
      if [ "$REM_ALL_RICH_RULES" == "true" ]; then remove_all_items "$zone" "--list-rich-rules" "--remove-rich-rule"; elif [ ${#REM_RICH_RULES[@]} -gt 0 ]; then apply_items "$zone" "--remove-rich-rule" "${REM_RICH_RULES[@]}"; fi
      if [ "$REM_ALL_INTERFACES" == "true" ]; then remove_all_items "$zone" "--list-interfaces" "--remove-interface"; elif [ ${#REM_INTERFACES[@]} -gt 0 ]; then apply_items "$zone" "--remove-interface" "${REM_INTERFACES[@]}"; fi
    fi

    [ ${#ADD_SOURCES[@]} -gt 0 ] && apply_items "$zone" "--add-source" "${ADD_SOURCES[@]}"
    [ ${#ADD_SERVICES[@]} -gt 0 ] && apply_items "$zone" "--add-service" "${ADD_SERVICES[@]}"
    [ ${#ADD_PORTS[@]} -gt 0 ] && apply_items "$zone" "--add-port" "${ADD_PORTS[@]}"
    [ ${#ADD_PROTOCOLS[@]} -gt 0 ] && apply_items "$zone" "--add-protocol" "${ADD_PROTOCOLS[@]}"
    [ ${#ADD_FWD_PORTS[@]} -gt 0 ] && apply_items "$zone" "--add-forward-port" "${ADD_FWD_PORTS[@]}"
    [ ${#ADD_SRC_PORTS[@]} -gt 0 ] && apply_items "$zone" "--add-source-port" "${ADD_SRC_PORTS[@]}"
    [ ${#ADD_ICMP_BLOCKS[@]} -gt 0 ] && apply_items "$zone" "--add-icmp-block" "${ADD_ICMP_BLOCKS[@]}"
    [ ${#ADD_RICH_RULES[@]} -gt 0 ] && apply_items "$zone" "--add-rich-rule" "${ADD_RICH_RULES[@]}"
    [ ${#ADD_INTERFACES[@]} -gt 0 ] && apply_items "$zone" "--add-interface" "${ADD_INTERFACES[@]}"

  done
  echo ""
  
  if [ "$PERMANENT_FLAG" == "true" ] && [ "$RELOAD_FLAG" == "false" ]; then
    echo "💡 안내: --permanent 옵션이 사용되었습니다. 즉시 적용하려면 --reload 옵션을 함께 사용하시기 바랍니다."
    echo ""
  fi
fi

# 1. --reload 처리
if [ "$RELOAD_FLAG" == "true" ]; then
  echo "🔄 Reloading firewall list..."
  sudo firewall-cmd --reload
  echo ""
  ACTIVE_ZONE_ALL="true"
fi

# 2. Zone 수집
declare -A UNIQUE_ZONES=()

if [ "$ACTIVE_ZONE_ALL" == "true" ] || [ ${#ACTIVE_ZONE_TARGETS[@]} -gt 0 ]; then
  raw_active_zones=$(get_active_zones)
  
  if [ "$ACTIVE_ZONE_ALL" == "true" ]; then
    while IFS= read -r z; do
      if [ -n "$z" ]; then
        UNIQUE_ZONES["$z"]=1
      fi
    done <<< "$raw_active_zones"
  fi

  if [ ${#ACTIVE_ZONE_TARGETS[@]} -gt 0 ]; then
    for target_z in "${ACTIVE_ZONE_TARGETS[@]}"; do
      if [ -z "$target_z" ]; then continue; fi
      is_active="false"
      while IFS= read -r z; do
        if [ -n "$z" ] && [ "$target_z" == "$z" ]; then
          is_active="true"
          break
        fi
      done <<< "$raw_active_zones"

      if [ "$is_active" == "true" ]; then
        UNIQUE_ZONES["$target_z"]=1
      else
        echo "⚠️ '$target_z' zone은(는) 현재 활성화되어 있지 않습니다."
      fi
    done
  fi
fi

if [ ${#TARGET_ZONES[@]} -gt 0 ]; then
  for z in "${TARGET_ZONES[@]}"; do
    if [ -n "$z" ]; then
      UNIQUE_ZONES["$z"]=1
    fi
  done
fi

# 3. 출력 제어
PRINT_FLAG="false"
if [ "$has_modification" == "false" ]; then
  PRINT_FLAG="true"
elif [ "$RELOAD_FLAG" == "true" ] || [ "$ACTIVE_ZONE_ALL" == "true" ] || [ ${#ACTIVE_ZONE_TARGETS[@]} -gt 0 ]; then
  PRINT_FLAG="true"
fi

if [ "$PRINT_FLAG" == "true" ]; then
  if [ ${#UNIQUE_ZONES[@]} -eq 0 ]; then
    echo "⚠️ 조회할 대상 zone이 없습니다."
    exit 0
  fi

  mapfile -t sorted_zones < <(printf "%s\n" "${!UNIQUE_ZONES[@]}" | sort)

  for z in "${sorted_zones[@]}"; do
    if [ -n "$z" ]; then
      print_zone_info "$z"
    fi
  done
else
  echo "💡 안내: 규칙 변경이 완료되었습니다. (현재 런타임 상태 출력 생략)"
  echo "   - 새로 적용된 최신 상태를 확인하시려면 --reload 옵션과 함께 실행하시거나,"
  echo "   - 순수하게 대상 zone만 지정(--zone=...)하여 다시 조회해 주시기 바랍니다."
fi

echo ""
echo "✨ 모든 작업이 완료되었습니다!"
exit 0
