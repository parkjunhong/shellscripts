#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-09-08
# @desc : support macOS 11.2.3 or higher, Ubuntu 18.04 or higher, RHEL 7 or higher, Oracle Linux 7 or higher, RockyOS 8 or higher, CentOS 7 or higher
# @installation : 
# 1. insert 'source <path>/add-vlan-routes.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/add-vlan-routes.sh' into etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

##
# 오류 발생 시 디버깅을 위한 콜스택 및 도움말 메시지를 출력합니다.
#
# @param $1 {string} 에러 원인 (Cause)
# @param $2 {int} 에러 발생 라인 번호 (Line)
#
# @return 도움말 및 디버깅 가이드 출력
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
  echo "사용법: ./$FILENAME [옵션]"
  echo ""
  echo "[옵션 (Options)]"
  echo "  -h, --help                  도움말 메시지를 출력하고 종료합니다."
  echo "  -d, --dry-run               실제 시스템에 반영하지 않고 예정된 구성을 출력합니다."
  echo "  -a, --add-vlan-networks     추가할 대상 VLAN 대역 (CIDR, 콤마 구분)"
  echo "  -r, --remove-vlan-networks  제거할 대상 VLAN 대역 (CIDR, 콤마 구분)"
  echo ""
  echo "[설명]"
  echo "  본 스크립트는 서버가 속한 물리 인터페이스를 자동 식별하고,"
  echo "  목적지 VLAN 대역으로 향하는 영구(Permanent) 정적 라우팅을 제어합니다."
  echo "  지원 OS: Ubuntu, RHEL 계열(Rocky, CentOS, Oracle Linux), macOS (Apple Silicon M1-M4 포함)"
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

# 전역 상태 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
DRY_RUN=false
ADD_VLAN_INPUT=""
REMOVE_VLAN_INPUT=""
HAS_A_FLAG=false
HAS_R_FLAG=false

IFACE=""
CUR_SUBNET=""
TRUNK_GW=""
OS_TYPE=""

##
# 지정된 명령어의 절대경로를 동적으로 추적하고 존재 유무를 검증합니다.
#
# @param $1 {string} 검색할 명령어 이름
#
# @return {string} 확인된 명령어의 절대경로
##
resolve_command() {
  local cmd_name="$1"
  local cmd_path=""

  cmd_path="$(command -v "$cmd_name" 2>/dev/null || true)"

  if [ -z "$cmd_path" ]; then
    help "필수 시스템 유틸리티 '$cmd_name'을(를) 찾을 수 없습니다." "$LINENO"
    exit 1
  fi
  echo "$cmd_path"
}

##
# sudo 명령어 사용 가능 여부 및 권한을 사전 검증합니다.
#
# @param 없음
#
# @return (검증 실패 시 에러 출력 후 exit 1)
##
check_sudo() {
  local cmd_sudo=""
  cmd_sudo="$(command -v sudo 2>/dev/null || true)"

  if [ -z "$cmd_sudo" ]; then
    help "시스템에 sudo 명령어가 설치되어 있지 않습니다." "$LINENO"
    exit 1
  fi

  if [ "$DRY_RUN" = false ]; then
    if ! "$cmd_sudo" -n true 2>/dev/null; then
      echo "🔐 [AUTH] 네트워크 설정 변경을 위해 sudo 인증이 필요합니다."
      "$cmd_sudo" -v || {
        help "현재 사용자에게 sudo 권한이 없거나 인증에 실패했습니다." "$LINENO"
        exit 1
      }
    fi
  fi
}

##
# 운영체제 종류를 식별합니다 (ubuntu, rhel, macos).
#
# @param 없음
#
# @return {string} 감지된 OS 식별자
##
detect_os() {
  local uname_str=""
  uname_str="$(uname -s 2>/dev/null || true)"

  if [ "$uname_str" == "Darwin" ]; then
    echo "macos"
    return 0
  fi

  if [ -f /etc/os-release ]; then
    local id=""
    local id_like=""
    id="$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || true)"
    id_like="$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"' || true)"

    if [[ "$id" == "ubuntu" || "$id_like" == *"ubuntu"* || "$id" == "debian" ]]; then
      echo "ubuntu"
      return 0
    elif [[ "$id" =~ ^(rhel|rocky|ol|centos|almalinux|fedora)$ || "$id_like" == *"rhel"* || "$id_like" == *"fedora"* ]]; then
      echo "rhel"
      return 0
    fi
  fi

  echo "unknown"
}

##
# 입력된 CIDR 포맷의 유효성을 정밀 검증합니다.
#
# @param $1 {string} 검증할 CIDR (예: 10.11.0.0/16)
#
# @return (유효하지 않을 경우 exit 1)
##
validate_cidr() {
  local target_cidr="$1"
  local cidr_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$'

  if [[ ! "$target_cidr" =~ $cidr_regex ]]; then
    help "입력한 대역('$target_cidr')이 올바른 CIDR IPv4 형식이 아닙니다." "$LINENO"
    exit 1
  fi

  local ip_part="${target_cidr%/*}"
  local prefix_part="${target_cidr#*/}"

  local o1 o2 o3 o4
  IFS=. read -r o1 o2 o3 o4 <<< "$ip_part"

  if (( o1 > 255 || o2 > 255 || o3 > 255 || o4 > 255 || prefix_part > 32 )); then
    help "입력한 CIDR('$target_cidr')의 옥텟 또는 프리픽스 범위를 초과했습니다." "$LINENO"
    exit 1
  fi
}

##
# IP와 Prefix(CIDR)를 바탕으로 옥텟 단위 마스킹을 수행하여 정확한 네트워크 대역을 추출합니다.
#
# @param $1 {string} IP/CIDR (예: 10.11.1.14/16)
#
# @return {string} 네트워크 대역 주소 (예: 10.11.0.0/16)
##
get_network_address() {
  local ip_cidr="$1"
  local ip="${ip_cidr%/*}"
  local mask="${ip_cidr#*/}"

  local rem=$mask
  local -a octet_masks=()
  local i=0

  for (( i=0; i<4; i++ )); do
    if (( rem >= 8 )); then
      octet_masks+=(255)
      (( rem -= 8 )) || true
    elif (( rem > 0 )); then
      octet_masks+=( $(( 256 - (1 << (8 - rem)) )) )
      rem=0
    else
      octet_masks+=(0)
    fi
  done

  local o1 o2 o3 o4
  IFS=. read -r o1 o2 o3 o4 <<< "$ip"

  local n1=$(( o1 & octet_masks[0] ))
  local n2=$(( o2 & octet_masks[1] ))
  local n3=$(( o3 & octet_masks[2] ))
  local n4=$(( o4 & octet_masks[3] ))

  echo "$n1.$n2.$n3.$n4/$mask"
}

##
# 16진수 Netmask 문자열을 CIDR Prefix 숫자로 변환합니다 (macOS용).
#
# @param $1 {string} 16진수 Netmask (예: 0xffffff00)
#
# @return {int} 계산된 Prefix 자릿수 (예: 24)
##
hex_netmask_to_prefix() {
  local hex_mask="$1"
  hex_mask="${hex_mask#0x}"
  local dec_mask=$(( 16#$hex_mask ))
  local prefix=0

  while (( dec_mask > 0 )); do
    (( prefix += dec_mask & 1 )) || true
    (( dec_mask >>= 1 )) || true
  done

  echo "$prefix"
}

##
# 콤마 구분자 문자열을 파싱하여 정제된 목록으로 반환합니다.
#
# @param $1 {string} 원본 입력 문자열
#
# @return {string} 공백으로 구분된 CIDR 문자열
##
parse_networks() {
  local input="$1"
  local out_string=""

  if [ -n "$input" ]; then
    local -a raw_networks=()
    IFS=',' read -r -a raw_networks <<< "$input"
    local net=""
    for net in "${raw_networks[@]}"; do
      local trimmed=""
      trimmed="$(echo "$net" | tr -d '[:space:]')"
      if [ -n "$trimmed" ]; then
        validate_cidr "$trimmed"
        out_string+="$trimmed "
      fi
    done
  fi
  echo "$out_string"
}

##
# 시스템 내 활성 네트워크 물리 인터페이스 목록을 수집합니다.
#
# @param $1 {string} 운영체제 유형 ('macos', 'ubuntu', 'rhel')
#
# @return {string} 줄바꿈으로 구분된 인터페이스 이름 목록
##
collect_interfaces() {
  local os="$1"

  if [ "$os" == "macos" ]; then
    ifconfig -l | tr ' ' '\n' | grep -vE '^(lo|bridge|utun|p2p|awdl|llw|gif|stf|vmenet|anpi)' | while IFS= read -r ifc; do
      if [ -n "$ifc" ] && ifconfig "$ifc" 2>/dev/null | grep -qw "inet"; then
        echo "$ifc"
      fi
    done
  else
    ip -4 -o addr show | awk '{print $2}' | grep -vE '^(lo|docker|br-|veth|virbr|tun|tap)' | sort -u
  fi
}

##
# 대상 인터페이스에 바인딩된 IPv4 CIDR 정보를 획득합니다.
#
# @param $1 {string} 인터페이스 명칭
# @param $2 {string} 운영체제 유형
#
# @return {string} IPv4/CIDR 문자열 (예: 192.168.1.10/24)
##
extract_interface_cidr() {
  local ifc="$1"
  local os="$2"

  if [ "$os" == "macos" ]; then
    local inet_line=""
    inet_line="$(ifconfig "$ifc" 2>/dev/null | awk '/inet / {print $2, $4}' | head -n1)"
    local ip_addr=""
    local hex_mask=""
    read -r ip_addr hex_mask <<< "$inet_line"

    if [ -n "$ip_addr" ] && [ -n "$hex_mask" ]; then
      local prefix=""
      prefix="$(hex_netmask_to_prefix "$hex_mask")"
      echo "${ip_addr}/${prefix}"
    fi
  else
    ip -4 addr show dev "$ifc" 2>/dev/null | awk '/inet / {print $2}' | head -n1
  fi
}

##
# 지정된 인터페이스의 기본 게이트웨이 주소를 추적합니다.
#
# @param $1 {string} 인터페이스 명칭
# @param $2 {string} 운영체제 유형
#
# @return {string} 감지된 기본 게이트웨이 IP
##
extract_base_gateway() {
  local ifc="$1"
  local os="$2"
  local gw=""

  if [ "$os" == "macos" ]; then
    gw="$(netstat -nr -f inet 2>/dev/null | awk -v dev="$ifc" '$1 == "default" && ($4 == dev || $6 == dev) {print $2; exit}')"
    if [ -z "$gw" ]; then
      gw="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')"
    fi
  else
    gw="$(ip -4 route show default dev "$ifc" 2>/dev/null | awk '{print $3}' | head -n1)"
  fi

  echo "$gw"
}

##
# 현재 시스템의 정적 라우팅 적용 상태 및 서브넷 정보를 화면에 정렬하여 출력합니다.
#
# @param $1 {string} 대상 인터페이스명
# @param $2 {string} 서버의 소속 네트워크 대역
# @param $3 {string} 운영체제 유형
#
# @return 라우팅 테이블 콘솔 출력
##
show_current_routes() {
  local iface="$1"
  local cur_subnet="$2"
  local os="$3"

  echo ""
  echo "================================================================================"
  echo "💡 [정보] 현재 설정된 시스템 정적 라우팅 상태 (인터페이스: $iface)"
  echo "   - 서버 소속 네트워크(Netmask) : $cur_subnet"
  echo "--------------------------------------------------------------------------------"

  if [ "$os" == "macos" ]; then
    local mac_routes=""
    mac_routes="$(netstat -rn -f inet 2>/dev/null | grep -E "(default|$iface)" || true)"
    if [ -n "$mac_routes" ]; then
      echo "$mac_routes" | awk '{printf "   > %-20s %-18s %-8s %-8s\n", $1, $2, $3, $6}'
    else
      echo "   > 추가된 정적 라우팅 없음"
    fi
  else
    local routes=""
    routes="$(ip -4 route show dev "$iface" 2>/dev/null | grep "via" || echo "추가된 정적 라우팅 없음")"
    if [ "$routes" == "추가된 정적 라우팅 없음" ]; then
      echo "   > $routes"
    else
      echo "$routes" | awk '{printf "   > %-18s %-4s %-15s %-6s %-7s %-7s %-5s\n", $1, $2, $3, $4, $5, $6, $7}'
    fi
  fi
  echo "================================================================================"
  echo ""
}

##
# 우분투 환경을 대상으로 단일 네트워크 파일 삭제 로직을 수행합니다.
#
# @param $1 {string} 삭제할 대상 VLAN 대역
#
# @return (Netplan 설정 파일 제거)
##
configure_ubuntu_remove() {
  local target_subnet="$1"
  local subnet_safe=""
  subnet_safe="$(echo "$target_subnet" | tr '/' '_')"
  local target_file="/etc/netplan/90-route-${subnet_safe}.yaml"

  local cmd_sudo cmd_rm
  cmd_sudo="$(resolve_command "sudo")"
  cmd_rm="$(resolve_command "rm")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] 삭제 에뮬레이션: $target_file"
  else
    if [ -f "$target_file" ]; then
      "$cmd_sudo" "$cmd_rm" -f "$target_file"
      echo "   ✅ [삭제 완료] $target_subnet ($target_file)"
    else
      echo "   ⏭️  [건너뜀] 대상 설정 파일이 존재하지 않음: $target_subnet"
    fi
  fi
}

##
# 우분투 환경을 대상으로 단일 네트워크 1:1 파일 생성 로직을 수행합니다.
#
# @param $1 {string} 물리 인터페이스 이름
# @param $2 {string} 추가할 대상 VLAN 대역
# @param $3 {string} Trunk Gateway IP 주소
#
# @return (Netplan 설정 파일 생성)
##
configure_ubuntu_add() {
  local iface="$1"
  local target_subnet="$2"
  local gateway="$3"

  local subnet_safe=""
  subnet_safe="$(echo "$target_subnet" | tr '/' '_')"
  local target_file="/etc/netplan/90-route-${subnet_safe}.yaml"

  local cmd_sudo cmd_mktemp cmd_mv cmd_chmod
  cmd_sudo="$(resolve_command "sudo")"
  cmd_mktemp="$(resolve_command "mktemp")"
  cmd_mv="$(resolve_command "mv")"
  cmd_chmod="$(resolve_command "chmod")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] 추가 에뮬레이션: $target_subnet via $gateway -> $target_file"
  else
    if [ -f "$target_file" ]; then
      echo "   ⏭️  [건너뜀] 이미 동일 대역의 설정 파일이 존재함: $target_subnet"
      return 0
    fi

    local tmp_file=""
    tmp_file="$("$cmd_mktemp" "${TMPDIR:-/tmp}/netplan_route_XXXXXX.yaml")"

    cat << EOF > "$tmp_file"
network:
  version: 2
  ethernets:
    $iface:
      routes:
        - to: $target_subnet
          via: $gateway
EOF

    "$cmd_sudo" "$cmd_mv" "$tmp_file" "$target_file"
    "$cmd_sudo" "$cmd_chmod" 600 "$target_file"
    echo "   ✅ [추가 완료] $target_subnet ($target_file 생성됨)"
  fi
}

##
# 우분투 시스템의 변경된 Netplan 구성을 적용합니다.
#
# @param 없음
#
# @return (netplan apply 실행)
##
apply_ubuntu() {
  if [ "$DRY_RUN" = false ]; then
    local cmd_sudo cmd_netplan
    cmd_sudo="$(resolve_command "sudo")"
    cmd_netplan="$(resolve_command "netplan")"
    echo ""
    echo "🔄 [시스템 반영 중] netplan apply 커맨드를 호출합니다..."
    "$cmd_sudo" "$cmd_netplan" apply
    echo "✨ Netplan 변경 사항이 시스템에 안전하게 반영되었습니다."
  fi
}

##
# RHEL/nmcli 환경을 대상으로 단일 라우팅 제거 로직을 수행합니다.
#
# @param $1 {string} Connection 프로파일 UUID 또는 명칭
# @param $2 {string} 삭제할 대상 VLAN 대역
# @param $3 {string} 계산된 Gateway IP
#
# @return (nmcli 라우팅 삭제)
##
configure_rhel_remove() {
  local conn_target="$1"
  local target_subnet="$2"
  local gateway="$3"

  local cmd_sudo cmd_nmcli
  cmd_sudo="$(resolve_command "sudo")"
  cmd_nmcli="$(resolve_command "nmcli")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] 삭제: $cmd_sudo $cmd_nmcli connection modify \"$conn_target\" -ipv4.routes \"$target_subnet $gateway\""
  else
    "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_target" -ipv4.routes "$target_subnet $gateway" 2>/dev/null || true
    echo "   ✅ [삭제 완료] $target_subnet"
  fi
}

##
# RHEL/nmcli 환경을 대상으로 단일 라우팅 추가 로직을 수행합니다.
#
# @param $1 {string} Connection 프로파일 UUID 또는 명칭
# @param $2 {string} 추가할 대상 VLAN 대역
# @param $3 {string} 계산된 Gateway IP
#
# @return (nmcli 라우팅 추가)
##
configure_rhel_add() {
  local conn_target="$1"
  local target_subnet="$2"
  local gateway="$3"

  local cmd_sudo cmd_nmcli
  cmd_sudo="$(resolve_command "sudo")"
  cmd_nmcli="$(resolve_command "nmcli")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] 추가: $cmd_sudo $cmd_nmcli connection modify \"$conn_target\" +ipv4.routes \"$target_subnet $gateway\""
  else
    "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_target" +ipv4.routes "$target_subnet $gateway"
    echo "   ✅ [추가 완료] $target_subnet"
  fi
}

##
# macOS 환경을 대상으로 단일 라우팅 제거 및 LaunchDaemon 설정을 정리합니다.
#
# @param $1 {string} 삭제할 대상 VLAN 대역
# @param $2 {string} Trunk Gateway IP 주소
#
# @return (route delete 및 LaunchDaemon 삭제)
##
configure_macos_remove() {
  local target_subnet="$1"
  local gateway="$2"

  local subnet_safe=""
  subnet_safe="$(echo "$target_subnet" | tr '/' '_')"
  local plist_file="/Library/LaunchDaemons/com.network.route.${subnet_safe}.plist"

  local cmd_sudo cmd_route cmd_rm
  cmd_sudo="$(resolve_command "sudo")"
  cmd_route="$(resolve_command "route")"
  cmd_rm="$(resolve_command "rm")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] macOS 커널 라우트 삭제: $cmd_sudo $cmd_route -n delete -net $target_subnet $gateway"
    echo "   🧪 [DRY-RUN] 영구 데몬 파일 제거: $plist_file"
  else
    "$cmd_sudo" "$cmd_route" -n delete -net "$target_subnet" "$gateway" 2>/dev/null || true

    if [ -f "$plist_file" ]; then
      local cmd_launchctl
      cmd_launchctl="$(resolve_command "launchctl")"
      "$cmd_sudo" "$cmd_launchctl" unload "$plist_file" 2>/dev/null || true
      "$cmd_sudo" "$cmd_rm" -f "$plist_file"
      echo "   ✅ [삭제 완료] $target_subnet (커널 라우트 및 영구 LaunchDaemon 해제됨)"
    else
      echo "   ✅ [삭제 완료] $target_subnet (커널 라우트 해제됨)"
    fi
  fi
}

##
# macOS 환경을 대상으로 단일 라우팅 추가 및 LaunchDaemon 영구화를 등록합니다.
#
# @param $1 {string} 추가할 대상 VLAN 대역
# @param $2 {string} Trunk Gateway IP 주소
#
# @return (route add 및 LaunchDaemon 생성)
##
configure_macos_add() {
  local target_subnet="$1"
  local gateway="$2"

  local subnet_safe=""
  subnet_safe="$(echo "$target_subnet" | tr '/' '_')"
  local plist_file="/Library/LaunchDaemons/com.network.route.${subnet_safe}.plist"

  local cmd_sudo cmd_route cmd_launchctl cmd_mktemp cmd_mv cmd_chmod cmd_chown
  cmd_sudo="$(resolve_command "sudo")"
  cmd_route="$(resolve_command "route")"
  cmd_launchctl="$(resolve_command "launchctl")"
  cmd_mktemp="$(resolve_command "mktemp")"
  cmd_mv="$(resolve_command "mv")"
  cmd_chmod="$(resolve_command "chmod")"
  cmd_chown="$(resolve_command "chown")"

  if [ "$DRY_RUN" = true ]; then
    echo "   🧪 [DRY-RUN] macOS 커널 라우트 즉시 추가: $cmd_sudo $cmd_route -n add -net $target_subnet $gateway"
    echo "   🧪 [DRY-RUN] 영구 LaunchDaemon 데몬 생성: $plist_file"
  else
    # 1. 커널 라우팅 테이블 즉시 적용
    "$cmd_sudo" "$cmd_route" -n add -net "$target_subnet" "$gateway" >/dev/null 2>&1 || \
      "$cmd_sudo" "$cmd_route" -n change -net "$target_subnet" "$gateway" >/dev/null 2>&1 || true

    # 2. 재부팅 시에도 영속되도록 LaunchDaemon plist 등록
    local tmp_plist=""
    tmp_plist="$("$cmd_mktemp" "${TMPDIR:-/tmp}/com.network.route.XXXXXX.plist")"

    cat << EOF > "$tmp_plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.network.route.${subnet_safe}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/sbin/route</string>
        <string>-n</string>
        <string>add</string>
        <string>-net</string>
        <string>${target_subnet}</string>
        <string>${gateway}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

    "$cmd_sudo" "$cmd_mv" "$tmp_plist" "$plist_file"
    "$cmd_sudo" "$cmd_chown" root:wheel "$plist_file"
    "$cmd_sudo" "$cmd_chmod" 644 "$plist_file"
    "$cmd_sudo" "$cmd_launchctl" load -w "$plist_file" 2>/dev/null || true

    echo "   ✅ [추가 완료] $target_subnet (커널 라우트 반영 및 LaunchDaemon 영구화 완료)"
  fi
}

# --- 파라미터 파싱 파이프라인 ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help "" ""
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -a|--add-vlan-networks)
      HAS_A_FLAG=true
      if [[ -n "${2:-}" && "$2" != -* ]]; then
        ADD_VLAN_INPUT="$2"
        shift 2
      else
        shift 1
      fi
      ;;
    -r|--remove-vlan-networks)
      HAS_R_FLAG=true
      if [[ -n "${2:-}" && "$2" != -* ]]; then
        REMOVE_VLAN_INPUT="$2"
        shift 2
      else
        shift 1
      fi
      ;;
    *)
      help "알 수 없는 옵션입니다 -> $1" "$LINENO"
      exit 1
      ;;
  esac
done

# --- 메인 비즈니스 로직 런타임 ---

check_sudo

OS_TYPE="$(detect_os)"
if [ "$OS_TYPE" == "unknown" ]; then
  help "지원하지 않는 운영체제 환경입니다. 관리자에게 문의하세요." "$LINENO"
  exit 1
fi

# [단계 1] Bash 3.2 호환 방식으로 네트워크 물리 인터페이스 수집
CANDIDATES=()
while IFS= read -r line; do
  if [ -n "$line" ]; then
    CANDIDATES+=("$line")
  fi
done < <(collect_interfaces "$OS_TYPE")

if [ ${#CANDIDATES[@]} -eq 0 ]; then
  help "시스템에서 IPv4가 할당된 유효한 물리 인터페이스를 찾을 수 없습니다." "$LINENO"
  exit 1
elif [ ${#CANDIDATES[@]} -eq 1 ]; then
  IFACE="${CANDIDATES[0]}"
else
  echo "================================================================================"
  echo "⚙️  [설정] 다중 네트워크 감지: VLAN 라우팅을 담당할 내부망 인터페이스를 선택하세요."

  idx=1
  for cand in "${CANDIDATES[@]}"; do
    cand_info=""
    if [ "$OS_TYPE" == "macos" ]; then
      cand_info="$(ifconfig "$cand" 2>/dev/null | awk '/inet / {print $2, "netmask", $4}')"
    else
      cand_info="$(ip -4 route show dev "$cand" 2>/dev/null | grep 'scope link' | head -n 1 || true)"
      [ -z "$cand_info" ] && cand_info="$(ip -4 route show dev "$cand" 2>/dev/null | head -n 1 || true)"
    fi
    printf "%d) %s: %s\n" "$idx" "$cand" "${cand_info:-네트워크 정보 없음}"
    ((idx++)) || true
  done

  while true; do
    read -r -p " ├─▶ 인터페이스 번호를 입력하세요: " sel_idx
    if [[ "$sel_idx" =~ ^[0-9]+$ ]] && (( sel_idx >= 1 && sel_idx <= ${#CANDIDATES[@]} )); then
      IFACE="${CANDIDATES[$((sel_idx-1))]}"
      break
    else
      echo "   ❌ 올바른 번호를 선택해 주세요."
    fi
  done
  echo "================================================================================"
  echo ""
fi

# 선택된 인터페이스 기반 서브넷 대역 도출
IP_CIDR="$(extract_interface_cidr "$IFACE" "$OS_TYPE")"
if [ -z "$IP_CIDR" ]; then
  help "인터페이스 '$IFACE'에서 IPv4 주소 정보를 추출할 수 없습니다." "$LINENO"
  exit 1
fi
CUR_SUBNET="$(get_network_address "$IP_CIDR")"

# Base Gateway 추출 및 Trunk GW (+1) 연산
BASE_GW="$(extract_base_gateway "$IFACE" "$OS_TYPE")"

if [ -z "$BASE_GW" ]; then
  IFS=. read -r n1 n2 n3 n4 <<< "${CUR_SUBNET%/*}"
  BASE_GW="$n1.$n2.$n3.$((n4 + 1))"
fi

IFS=. read -r g1 g2 g3 g4 <<< "$BASE_GW"
CALC_GW_OCTET=$(( g4 + 1 ))

if (( CALC_GW_OCTET > 254 )); then
  echo "⚠️  [주의] 자동 계산된 Trunk Gateway 옥텟($CALC_GW_OCTET)이 유효 호스트 범위를 초과합니다."
  TRUNK_GW="$BASE_GW"
else
  TRUNK_GW="${g1}.${g2}.${g3}.${CALC_GW_OCTET}"
fi

# [단계 2] 프리플라이트 상태 점검 출력
show_current_routes "$IFACE" "$CUR_SUBNET" "$OS_TYPE"

# [단계 3] 목적지 넥스트 홉(Gateway) IP 대화형 입력 및 검증
echo "⚙️  [설정] 목적지 넥스트 홉(Gateway) IP 지정"
echo "   자동 계산된 기본 Trunk Gateway IP는 [$TRUNK_GW] 입니다."
echo "   다른 IP를 사용하려면 아래에 입력하시고, 기본값을 유지하려면 Enter 키를 누르세요."
read -r -p " ╰─▶ Next-hop Gateway IP [$TRUNK_GW]: " INPUT_GW
INPUT_GW="$(echo "$INPUT_GW" | tr -d '[:space:]')"

if [ -n "$INPUT_GW" ]; then
  if [[ "$INPUT_GW" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    TRUNK_GW="$INPUT_GW"
  else
    help "입력한 Gateway IP('$INPUT_GW') 형식이 올바른 IPv4 주소가 아닙니다." "$LINENO"
    exit 1
  fi
fi
echo ""

# [단계 4] 추가/삭제 대상 입력 대화형 프롬프트 및 인자 유효성 검증
if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = true ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
  help "-a 옵션과 -r 옵션을 인자 없이 동시에 사용할 수 없습니다." "$LINENO"
  exit 1
fi

if [ "$HAS_A_FLAG" = false ] && [ "$HAS_R_FLAG" = false ] && [ -z "$ADD_VLAN_INPUT" ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
  HAS_A_FLAG=true
fi

if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = false ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
  echo "⚙️  [설정] 네트워크 추가/삭제 대역 지정 (자신이 속한 대역 제외)"
  echo "   - CIDR Notation, 여러 개인 경우 콤마(,)로 구분"
  echo "   - 예시: 10.11.0.0/16,10.12.0.0/16"
  read -r -p " ├─▶ Add VLAN Networks (추가할 대역, 없으면 Enter): " ADD_VLAN_INPUT
  read -r -p " ╰─▶ Remove VLAN Networks (삭제할 대역, 없으면 Enter): " REMOVE_VLAN_INPUT
  echo ""
else
  if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ]; then
    echo "⚙️  [설정] 네트워크 추가 대역 지정 (자신이 속한 대역 제외)"
    read -r -p " ╰─▶ Add VLAN Networks (CIDR, 콤마 구분): " ADD_VLAN_INPUT
    echo ""
  fi

  if [ "$HAS_R_FLAG" = true ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    echo "⚙️  [설정] 네트워크 삭제 대역 지정 (자신이 속한 대역 제외)"
    read -r -p " ╰─▶ Remove VLAN Networks (CIDR, 콤마 구분): " REMOVE_VLAN_INPUT
    echo ""
  fi
fi

if [ -z "$(echo "$ADD_VLAN_INPUT$REMOVE_VLAN_INPUT" | tr -d '[:space:]')" ]; then
  help "추가 또는 삭제할 VLAN 네트워크가 지정되지 않았습니다. 작업을 취소합니다." "$LINENO"
  exit 1
fi

ADD_NETWORKS=()
REMOVE_NETWORKS=()

if [ -n "$ADD_VLAN_INPUT" ]; then
  read -r -a ADD_NETWORKS <<< "$(parse_networks "$ADD_VLAN_INPUT")"
fi

if [ -n "$REMOVE_VLAN_INPUT" ]; then
  read -r -a REMOVE_NETWORKS <<< "$(parse_networks "$REMOVE_VLAN_INPUT")"
fi

echo "🚀 [실행] 네트워크 라우팅 변경 작업 시작"
printf "   - 가동 모드            :"
if [ "$DRY_RUN" = true ]; then
  echo " 🧪 DRY-RUN (시뮬레이션 모드)"
else
  echo " ⚡ RUN (실제 시스템 반영 모드)"
fi
echo "   - 감지된 OS 유형       : $OS_TYPE"
echo "   - 할당 물리 인터페이스 : $IFACE"
echo "   - 서버 자동 식별 대역  : $CUR_SUBNET"
echo "   - 목적지 넥스트 홉(GW) : $TRUNK_GW"
echo "--------------------------------------------------------------------------------"

# NetworkManager (nmcli) 활성화 여부 식별 (Linux 계열 전용)
USE_NMCLI=false
CONN_TARGET=""

if [ "$OS_TYPE" != "macos" ]; then
  if command -v nmcli >/dev/null 2>&1; then
    if nmcli device status 2>/dev/null | awk '{print $1, $3}' | grep -iq "^${IFACE} connected"; then
      USE_NMCLI=true
      CMD_NMCLI="$(resolve_command "nmcli")"

      CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -g GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1 || true)"
      if [ -z "$CONN_TARGET" ]; then
        CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1 || true)"
      fi
      if [ -z "$CONN_TARGET" ]; then
        CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CONNECTION device show "$IFACE" 2>/dev/null | head -n1 || true)"
      fi
      [ -z "$CONN_TARGET" ] && CONN_TARGET="$IFACE"

      if [ "$OS_TYPE" == "ubuntu" ]; then
        echo "   💡 [감지] 우분투 환경이나 NetworkManager가 활성화되어 있습니다. nmcli 제어로 우회합니다."
      fi
    fi
  fi

  if [ "$OS_TYPE" == "rhel" ] && [ "$USE_NMCLI" = false ]; then
    USE_NMCLI=true
    CMD_NMCLI="$(resolve_command "nmcli")"

    CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -g GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1 || true)"
    if [ -z "$CONN_TARGET" ]; then
      CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1 || true)"
    fi
    if [ -z "$CONN_TARGET" ]; then
      CONN_TARGET="$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CONNECTION device show "$IFACE" 2>/dev/null | head -n1 || true)"
    fi
    [ -z "$CONN_TARGET" ] && CONN_TARGET="$IFACE"
  fi
fi

# [단계 5] 삭제(Remove) 파이프라인 진행
if [ ${#REMOVE_NETWORKS[@]} -gt 0 ]; then
  echo " 🗑️  [1단계] 라우팅 제거 작업 진행"
  for subnet in "${REMOVE_NETWORKS[@]}"; do
    if [ "$subnet" != "$CUR_SUBNET" ]; then
      if [ "$OS_TYPE" == "macos" ]; then
        configure_macos_remove "$subnet" "$TRUNK_GW"
      elif [ "$USE_NMCLI" = true ]; then
        configure_rhel_remove "$CONN_TARGET" "$subnet" "$TRUNK_GW"
      elif [ "$OS_TYPE" == "ubuntu" ]; then
        configure_ubuntu_remove "$subnet"
      fi
    else
      echo "   ⏭️  [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
    fi
  done
  echo ""
fi

# [단계 6] 추가(Add) 파이프라인 진행
if [ ${#ADD_NETWORKS[@]} -gt 0 ]; then
  echo " ➕ [2단계] 라우팅 추가 작업 진행"
  for subnet in "${ADD_NETWORKS[@]}"; do
    if [ "$subnet" != "$CUR_SUBNET" ]; then
      if [ "$OS_TYPE" == "macos" ]; then
        configure_macos_add "$subnet" "$TRUNK_GW"
      elif [ "$USE_NMCLI" = true ]; then
        configure_rhel_add "$CONN_TARGET" "$subnet" "$TRUNK_GW"
      elif [ "$OS_TYPE" == "ubuntu" ]; then
        configure_ubuntu_add "$IFACE" "$subnet" "$TRUNK_GW"
      fi
    else
      echo "   ⏭️  [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
    fi
  done
  echo ""
fi

# OS별 변경 사항 영구 반영 데몬 리로드 처리
if [ "$OS_TYPE" == "macos" ]; then
  if [ "$DRY_RUN" = false ]; then
    echo "✨ macOS 커널 라우팅 및 LaunchDaemon 등록이 안전하게 완료되었습니다."
  fi
elif [ "$USE_NMCLI" = true ]; then
  if [ "$DRY_RUN" = false ]; then
    CMD_SUDO="$(resolve_command "sudo")"
    echo ""
    echo "🔄 [시스템 반영 중] nmcli connection up 커맨드를 호출합니다..."
    "$CMD_SUDO" "$CMD_NMCLI" connection up "$CONN_TARGET"
    echo "✨ NetworkManager 변경 사항이 시스템에 안전하게 반영되었습니다."
  fi
elif [ "$OS_TYPE" == "ubuntu" ]; then
  apply_ubuntu
fi

echo "================================================================================"
echo "🎉 모든 라우팅 변경 라이프사이클 작업이 완료되었습니다."
exit 0
