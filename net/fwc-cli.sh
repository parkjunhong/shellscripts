#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : firewall-cmd zone info wrapper.
# @license  : Apache License 2.0
# @since    : 2026-06-01
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/fwc-cli.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/fwc-cli.sh' into /etc/bashrc for all users.
# =======================================

readonly FILENAME=$(basename "$0")

##
# 스크립트의 사용법을 출력하거나 오류 발생 시 콜스택을 출력합니다.
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
      printf "$formatr" "["$idx"]" "$func"
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: $FILENAME [옵션]"
  echo "옵션:"
  echo "  --zone=<zone 이름>     정보를 조회/수정할 zone 이름 (여러 번 사용 가능)"
  echo "  --active-zone          활성화된 모든 zone의 정보 조회"
  echo "  --reload               방화벽 설정 리로드 및 활성화된 zone 정보 조회"
  echo "  --permanent            설정을 영구적(permanent)으로 적용"
  echo "  --clear-all            지정된 zone의 모든 규칙 항목을 일괄 삭제 (가장 먼저 수행되며 개별 remove 무시)"
  echo "  --add-<항목>=<값>      지정된 zone에 규칙 추가 (콤마 구분)."
  echo "                         지원항목: sources, services, ports, protocols, forward-ports, source-ports,"
  echo "                                   icmp-blocks, rich-rules, interfaces"
  echo "  --remove-<항목>[=<값>] 지정된 zone에서 규칙 삭제 (콤마 구분). 값 생략 시 해당 항목의 모든 규칙 삭제"
  echo "                         지원항목: sources, services, ports, protocols, forward-ports, source-ports,"
  echo "                                   icmp-blocks, rich-rules, interfaces"
  echo "  -h, --help             도움말 출력"
}

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

parse_and_store() {
  local input="$1"
  local arr_name="$2"
  IFS=',' read -ra items <<< "$input"
  for item in "${items[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    if [ -n "$item" ]; then
      eval "$arr_name+=(\"\$item\")"
    fi
  done
}

get_active_zones() {
  sudo firewall-cmd --get-active-zones | awk '!/^[ \t]/{print $1}'
}

print_zone_info() {
  local zone_name="$1"
  echo "================================================================================"
  echo "🛡️  Zone: $zone_name"
  echo "================================================================================"
  
  if ! sudo firewall-cmd --zone="$zone_name" --list-all 2>/dev/null; then
    echo ""
    echo "⚠️  '$zone_name' zone을 찾을 수 없거나 정보를 조회할 수 없습니다."
  fi
}

# -----------------------------------------------------------------------------
# 공용 추가/삭제 함수 정의
# -----------------------------------------------------------------------------
apply_items() {
  local target_zone="$1"
  local action="$2"
  shift 2
  for item in "$@"; do
    echo " - [$target_zone] $action: $item"
    "${local_cmd[@]}" --zone="$target_zone" "$action=$item" >/dev/null
  done
}

remove_all_items() {
  local target_zone="$1"
  local action_list="$2"
  local action_remove="$3"
  
  # 조회 전용 명령어 조합 (영구 모드일 땐 영구 목록에서 조회)
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
    raw_output=$("${list_cmd[@]}" "$action_list" 2>/dev/null)
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

TARGET_ZONES=()
ACTIVE_ZONE_FLAG="false"
RELOAD_FLAG="false"
PERMANENT_FLAG="false"
CLEAR_ALL_FLAG="false"

# 추가 배열 선언
declare -a ADD_SOURCES ADD_SERVICES ADD_PORTS ADD_PROTOCOLS
declare -a ADD_FWD_PORTS ADD_SRC_PORTS ADD_ICMP_BLOCKS ADD_RICH_RULES ADD_INTERFACES

# 삭제 배열 선언
declare -a REM_SOURCES REM_SERVICES REM_PORTS REM_PROTOCOLS
declare -a REM_FWD_PORTS REM_SRC_PORTS REM_ICMP_BLOCKS REM_RICH_RULES REM_INTERFACES

# "모두 삭제" 플래그
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
    --active-zone) ACTIVE_ZONE_FLAG="true"; shift ;;
    --reload) RELOAD_FLAG="true"; shift ;;
    --permanent) PERMANENT_FLAG="true"; shift ;;
    --clear-all) CLEAR_ALL_FLAG="true"; shift ;;
    
    # Add 옵션
    --add-sources=*) parse_and_store "${1#*=}" "ADD_SOURCES"; shift ;;
    --add-services=*) parse_and_store "${1#*=}" "ADD_SERVICES"; shift ;;
    --add-ports=*) parse_and_store "${1#*=}" "ADD_PORTS"; shift ;;
    --add-protocols=*) parse_and_store "${1#*=}" "ADD_PROTOCOLS"; shift ;;
    --add-forward-ports=*) parse_and_store "${1#*=}" "ADD_FWD_PORTS"; shift ;;
    --add-source-ports=*) parse_and_store "${1#*=}" "ADD_SRC_PORTS"; shift ;;
    --add-icmp-blocks=*) parse_and_store "${1#*=}" "ADD_ICMP_BLOCKS"; shift ;;
    --add-rich-rules=*) parse_and_store "${1#*=}" "ADD_RICH_RULES"; shift ;;
    --add-interfaces=*) parse_and_store "${1#*=}" "ADD_INTERFACES"; shift ;;
    
    # Remove 옵션
    --remove-sources) REM_ALL_SOURCES="true"; shift ;;
    --remove-sources=*) parse_and_store "${1#*=}" "REM_SOURCES"; shift ;;
    --remove-services) REM_ALL_SERVICES="true"; shift ;;
    --remove-services=*) parse_and_store "${1#*=}" "REM_SERVICES"; shift ;;
    --remove-ports) REM_ALL_PORTS="true"; shift ;;
    --remove-ports=*) parse_and_store "${1#*=}" "REM_PORTS"; shift ;;
    --remove-protocols) REM_ALL_PROTOCOLS="true"; shift ;;
    --remove-protocols=*) parse_and_store "${1#*=}" "REM_PROTOCOLS"; shift ;;
    --remove-forward-ports) REM_ALL_FWD_PORTS="true"; shift ;;
    --remove-forward-ports=*) parse_and_store "${1#*=}" "REM_FWD_PORTS"; shift ;;
    --remove-source-ports) REM_ALL_SRC_PORTS="true"; shift ;;
    --remove-source-ports=*) parse_and_store "${1#*=}" "REM_SRC_PORTS"; shift ;;
    --remove-icmp-blocks) REM_ALL_ICMP_BLOCKS="true"; shift ;;
    --remove-icmp-blocks=*) parse_and_store "${1#*=}" "REM_ICMP_BLOCKS"; shift ;;
    --remove-rich-rules) REM_ALL_RICH_RULES="true"; shift ;;
    --remove-rich-rules=*) parse_and_store "${1#*=}" "REM_RICH_RULES"; shift ;;
    --remove-interfaces) REM_ALL_INTERFACES="true"; shift ;;
    --remove-interfaces=*) parse_and_store "${1#*=}" "REM_INTERFACES"; shift ;;
    
    -h|--help) help; exit 0 ;;
    *) help "알 수 없는 옵션입니다: $1" "$LINENO"; exit 1 ;;
  esac
done

# 변경 사항 확인
has_modification="false"
if [ ${#ADD_SOURCES[@]} -gt 0 ] || [ ${#ADD_SERVICES[@]} -gt 0 ] || [ ${#ADD_PORTS[@]} -gt 0 ] || [ ${#ADD_PROTOCOLS[@]} -gt 0 ] || \
   [ ${#ADD_FWD_PORTS[@]} -gt 0 ] || [ ${#ADD_SRC_PORTS[@]} -gt 0 ] || [ ${#ADD_ICMP_BLOCKS[@]} -gt 0 ] || [ ${#ADD_RICH_RULES[@]} -gt 0 ] || [ ${#ADD_INTERFACES[@]} -gt 0 ] || \
   [ ${#REM_SOURCES[@]} -gt 0 ] || [ ${#REM_SERVICES[@]} -gt 0 ] || [ ${#REM_PORTS[@]} -gt 0 ] || [ ${#REM_PROTOCOLS[@]} -gt 0 ] || \
   [ ${#REM_FWD_PORTS[@]} -gt 0 ] || [ ${#REM_SRC_PORTS[@]} -gt 0 ] || [ ${#REM_ICMP_BLOCKS[@]} -gt 0 ] || [ ${#REM_RICH_RULES[@]} -gt 0 ] || [ ${#REM_INTERFACES[@]} -gt 0 ] || \
   [ "$REM_ALL_SOURCES" == "true" ] || [ "$REM_ALL_SERVICES" == "true" ] || [ "$REM_ALL_PORTS" == "true" ] || [ "$REM_ALL_PROTOCOLS" == "true" ] || \
   [ "$REM_ALL_FWD_PORTS" == "true" ] || [ "$REM_ALL_SRC_PORTS" == "true" ] || [ "$REM_ALL_ICMP_BLOCKS" == "true" ] || [ "$REM_ALL_RICH_RULES" == "true" ] || [ "$REM_ALL_INTERFACES" == "true" ] || \
   [ "$CLEAR_ALL_FLAG" == "true" ]; then
  has_modification="true"
fi

if [ "$has_modification" == "true" ] && [ ${#TARGET_ZONES[@]} -eq 0 ]; then
  help "오류: --add-*, --remove-*, --clear-all 옵션을 사용할 때는 반드시 --zone=<이름> 옵션을 한 개 이상 지정해야 합니다." "$LINENO"
  exit 1
fi

if [ ${#TARGET_ZONES[@]} -eq 0 ] && [ "$ACTIVE_ZONE_FLAG" == "false" ] && [ "$RELOAD_FLAG" == "false" ] && [ "$has_modification" == "false" ]; then
  help "조회할 대상(--zone=<이름> 등) 또는 동작(--reload, --add-*, --remove-*, --clear-all)을 입력해 주세요." "$LINENO"
  exit 1
fi

# 0. 규칙 추가/삭제 처리
if [ "$has_modification" == "true" ]; then
  echo "================================================================================"
  echo "🛡️  방화벽 규칙 변경 적용 중..."
  echo "================================================================================"
  
  local_cmd=(sudo firewall-cmd)
  if [ "$PERMANENT_FLAG" == "true" ]; then
    local_cmd+=("--permanent")
    echo " 💾 [Permanent Mode] 설정이 영구적으로 저장/조회됩니다."
  fi

  for zone in "${TARGET_ZONES[@]}"; do
    
    # ---------------------------------------------------------
    # [우선순위 1] 항목들 삭제 처리 (Clear-all 우선 또는 개별 삭제)
    # ---------------------------------------------------------
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
      if [ "$REM_ALL_SOURCES" == "true" ]; then remove_all_items "$zone" "--list-sources" "--remove-source"; else apply_items "$zone" "--remove-source" "${REM_SOURCES[@]}"; fi
      if [ "$REM_ALL_SERVICES" == "true" ]; then remove_all_items "$zone" "--list-services" "--remove-service"; else apply_items "$zone" "--remove-service" "${REM_SERVICES[@]}"; fi
      if [ "$REM_ALL_PORTS" == "true" ]; then remove_all_items "$zone" "--list-ports" "--remove-port"; else apply_items "$zone" "--remove-port" "${REM_PORTS[@]}"; fi
      if [ "$REM_ALL_PROTOCOLS" == "true" ]; then remove_all_items "$zone" "--list-protocols" "--remove-protocol"; else apply_items "$zone" "--remove-protocol" "${REM_PROTOCOLS[@]}"; fi
      if [ "$REM_ALL_FWD_PORTS" == "true" ]; then remove_all_items "$zone" "--list-forward-ports" "--remove-forward-port"; else apply_items "$zone" "--remove-forward-port" "${REM_FWD_PORTS[@]}"; fi
      if [ "$REM_ALL_SRC_PORTS" == "true" ]; then remove_all_items "$zone" "--list-source-ports" "--remove-source-port"; else apply_items "$zone" "--remove-source-port" "${REM_SRC_PORTS[@]}"; fi
      if [ "$REM_ALL_ICMP_BLOCKS" == "true" ]; then remove_all_items "$zone" "--list-icmp-blocks" "--remove-icmp-block"; else apply_items "$zone" "--remove-icmp-block" "${REM_ICMP_BLOCKS[@]}"; fi
      if [ "$REM_ALL_RICH_RULES" == "true" ]; then remove_all_items "$zone" "--list-rich-rules" "--remove-rich-rule"; else apply_items "$zone" "--remove-rich-rule" "${REM_RICH_RULES[@]}"; fi
      if [ "$REM_ALL_INTERFACES" == "true" ]; then remove_all_items "$zone" "--list-interfaces" "--remove-interface"; else apply_items "$zone" "--remove-interface" "${REM_INTERFACES[@]}"; fi
    fi

    # ---------------------------------------------------------
    # [우선순위 2] 항목들 추가 처리 (삭제 완료 후 추가 진행)
    # ---------------------------------------------------------
    apply_items "$zone" "--add-source" "${ADD_SOURCES[@]}"
    apply_items "$zone" "--add-service" "${ADD_SERVICES[@]}"
    apply_items "$zone" "--add-port" "${ADD_PORTS[@]}"
    apply_items "$zone" "--add-protocol" "${ADD_PROTOCOLS[@]}"
    apply_items "$zone" "--add-forward-port" "${ADD_FWD_PORTS[@]}"
    apply_items "$zone" "--add-source-port" "${ADD_SRC_PORTS[@]}"
    apply_items "$zone" "--add-icmp-block" "${ADD_ICMP_BLOCKS[@]}"
    apply_items "$zone" "--add-rich-rule" "${ADD_RICH_RULES[@]}"
    apply_items "$zone" "--add-interface" "${ADD_INTERFACES[@]}"

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
  ACTIVE_ZONE_FLAG="true"
fi

declare -A UNIQUE_ZONES

# 2. --active-zone 처리
if [ "$ACTIVE_ZONE_FLAG" == "true" ]; then
  active_zones=$(get_active_zones)
  for z in $active_zones; do
    UNIQUE_ZONES["$z"]=1
  done
fi

# 3. --zone 처리
for z in "${TARGET_ZONES[@]}"; do
  UNIQUE_ZONES["$z"]=1
done

# 4. 결과 출력 로직 개선 (변경 사항이 있으면 --reload시에만 출력)
PRINT_FLAG="false"
if [ "$has_modification" == "false" ]; then
  PRINT_FLAG="true" # 단순 조회일 경우 항상 출력
elif [ "$RELOAD_FLAG" == "true" ] || [ "$ACTIVE_ZONE_FLAG" == "true" ]; then
  PRINT_FLAG="true" # 수정 사항이 반영된 최신 런타임을 확인할 명시적 요청이 있을 때 출력
fi

if [ "$PRINT_FLAG" == "true" ]; then
  if [ ${#UNIQUE_ZONES[@]} -eq 0 ]; then
    echo "⚠️ 조회할 대상 zone이 없습니다."
    exit 0
  fi

  mapfile -t sorted_zones < <(printf "%s\n" "${!UNIQUE_ZONES[@]}" | sort)

  for z in "${sorted_zones[@]}"; do
    print_zone_info "$z"
  done
else
  # 수정을 진행했지만, --reload 등을 하지 않아 화면 출력만 생략하는 경우
  echo "💡 안내: 규칙 변경이 완료되었습니다. (현재 런타임 상태 출력 생략)"
  echo "   - 새로 적용된 최신 상태를 확인하시려면 --reload 옵션과 함께 실행하시거나,"
  echo "   - 순수하게 대상 zone만 지정(--zone=...)하여 다시 조회해 주시기 바랍니다."
fi

echo ""
echo "✨ 모든 작업이 완료되었습니다!"
exit 0
