#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : add vlan routes.
# @license : Apache License 2.0
# @since : 2026-07-23
# @desc : support Ubuntu 20+, RHEL 8+, CentOS 7+, Rocky Linux 9+, Oracle Linux 9+
# @installation :
# 1. insert 'source <path>/<파일명>' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")
DRY_RUN=false
ADD_VLAN_INPUT=""
REMOVE_VLAN_INPUT=""
HAS_A_FLAG=false
HAS_R_FLAG=false

##
# 오류 발생 시 디버깅을 위한 콜스택 및 도움말 메시지를 출력합니다.
#
# @param $1 {string} 에러 원인 (Cause)
# @param $2 {int} 에러 발생 라인 번호 (Line)
#
# @returns 도움말 및 디버깅 가이드 출력
##
help(){
    if [ ! -z "$1" ]; then
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
            printf "$formatr" "["$idx"]" $func
            ((idx++))
        done
        printf "$formatl" "cause" "$1"
        echo "================================================================================"
    fi
    echo
    echo "Usage: ./$FILENAME [OPTIONS]"
    echo "Options:"
    echo "  -h, --help                  도움말 메시지를 출력합니다."
    echo "  -d, --dry-run               실제 시스템에 반영하지 않고 예정된 구성 설정을 화면에 출력합니다."
    echo "  -a, --add-vlan-networks     추가할 대상 VLAN 대역 (CIDR, 콤마 구분)"
    echo "  -r, --remove-vlan-networks  제거할 대상 VLAN 대역 (CIDR, 콤마 구분)"
    echo
    echo "설명:"
    echo "  본 스크립트는 서버가 속한 물리 인터페이스를 자동 식별하고,"
    echo "  목적지 VLAN 대역으로 향하는 영구(Permanent) 정적 라우팅을 제어합니다."
}

# 파라미터 옵션 처리 파이프라인 (안전한 플래그 및 값 매핑 도입)
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -a|--add-vlan-networks)
            HAS_A_FLAG=true
            if [[ -n "$2" && "$2" != -* ]]; then
                ADD_VLAN_INPUT="$2"
                shift 2
            else
                shift 1
            fi
            ;;
        -r|--remove-vlan-networks)
            HAS_R_FLAG=true
            if [[ -n "$2" && "$2" != -* ]]; then
                REMOVE_VLAN_INPUT="$2"
                shift 2
            else
                shift 1
            fi
            ;;
        *)
            help "알 수 없는 옵션입니다: $1" "$LINENO"
            exit 1
            ;;
    esac
done

##
# 지정된 명령어의 절대경로를 동적으로 추적하고 존재 유무를 검증합니다.
#
# @param $1 {string} 절대경로를 검색할 명령어 이름
#
# @returns {string} 확인된 명령어의 동적 절대경로
##
resolve_command() {
    local cmd_name="$1"
    local cmd_path

    cmd_path=$(command -v "$cmd_name" 2>/dev/null)

    if [ -z "$cmd_path" ]; then
        help "필수 시스템 유틸리티 '$cmd_name'을(를) 찾을 수 없습니다." "$LINENO"
        exit 1
    fi
    echo "$cmd_path"
}

##
# sudo 명령어 사용 가능 여부 및 권한을 검증합니다.
#
# @returns sudo 권한 없을 경우 에러 메시지와 함께 스크립트 종료
##
check_sudo() {
    local cmd_sudo
    cmd_sudo=$(command -v sudo 2>/dev/null)

    if [ -z "$cmd_sudo" ]; then
        help "시스템에 sudo 명령어가 설치되어 있지 않습니다." "$LINENO"
        exit 1
    fi

    if [ "$DRY_RUN" = false ]; then
        if ! "$cmd_sudo" -v 2>/dev/null; then
            help "현재 사용자에게 sudo 실행 권한이 없거나 패스워드 인증에 실패했습니다." "$LINENO"
            exit 1
        fi
    fi
}

##
# 시스템의 배포판 종류를 분석하여 Ubuntu 계열과 RHEL 계열을 판별합니다.
#
# @returns {string} "ubuntu" 또는 "rhel" 형식으로 표준 출력
##
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]; then
            echo "ubuntu"
        elif [[ "$ID" == "rocky" || "$ID" == "rhel" || "$ID" == "ol" || "$ID" == "centos" || "$ID_LIKE" == *"rhel"* ]]; then
            echo "rhel"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

##
# IP 주소와 Prefix(CIDR)를 바탕으로 비트 연산을 수행하여 정확한 네트워크 대역을 추출합니다.
#
# @param $1 {string} IP/CIDR (예: 10.11.1.14/16)
#
# @returns {string} 네트워크 주소 (예: 10.11.0.0/16)
##
get_network_address() {
    local ip_cidr="$1"
    local ip="${ip_cidr%/*}"
    local mask="${ip_cidr#*/}"

    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    local ip_num=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
    local mask_num=$(( 0xFFFFFFFF << (32 - mask) ))
    local net_num=$(( ip_num & mask_num ))

    local n1=$(( (net_num >> 24) & 0xFF ))
    local n2=$(( (net_num >> 16) & 0xFF ))
    local n3=$(( (net_num >> 8) & 0xFF ))
    local n4=$(( net_num & 0xFF ))

    echo "$n1.$n2.$n3.$n4/$mask"
}

##
# 콤마(,) 구분자를 파싱하고 공백을 Trim 처리하여 배열로 반환합니다.
#
# @param $1 {string} 원본 입력 문자열
# @param $2 {array} 결과를 저장할 배열 참조명
##
parse_networks() {
    local input="$1"
    local -n out_array=$2
    out_array=()
    if [ ! -z "$input" ]; then
        IFS=',' read -r -a raw_networks <<< "$input"
        for net in "${raw_networks[@]}"; do
            local trimmed
            trimmed=$(echo "$net" | tr -d '[:space:]')
            if [ ! -z "$trimmed" ]; then
                out_array+=("$trimmed")
            fi
        done
    fi
}

##
# 현재 시스템의 정적 라우팅 적용 상태 및 서브넷 정보를 화면에 정렬하여 출력합니다.
#
# @param $1 {string} 대상 물리 인터페이스명
# @param $2 {string} 서버의 소속 네트워크 대역 (Netmask 포함)
##
show_current_routes() {
    local iface="$1"
    local cur_subnet="$2"
    echo
    echo "================================================================================"
    echo "💡 [정보] 현재 설정된 시스템 정적 라우팅 상태 (인터페이스: $iface)"
    echo "   - 서버 소속 네트워크(Netmask) : $cur_subnet"
    echo "--------------------------------------------------------------------------------"
    local routes
    routes=$(ip -4 route show dev "$iface" 2>/dev/null | grep "via" || echo "추가된 정적 라우팅 없음")
    
    if [ "$routes" == "추가된 정적 라우팅 없음" ]; then
        echo "   > $routes"
    else
        echo "$routes" | awk '{printf "   > %-18s %-4s %-15s %-6s %-7s %-7s %-5s\n", $1, $2, $3, $4, $5, $6, $7}'
    fi
    echo "================================================================================"
    echo
}

##
# 우분투 환경을 대상으로 단일 네트워크 파일 삭제 로직을 수행합니다.
#
# @param $1 {string} 삭제할 대상 VLAN 대역
##
configure_ubuntu_remove() {
    local target_subnet="$1"
    local subnet_safe
    subnet_safe=$(echo "$target_subnet" | tr '/' '_')
    local target_file="/etc/netplan/90-route-${subnet_safe}.yaml"

    local cmd_sudo
    local cmd_rm
    cmd_sudo=$(resolve_command "sudo")
    cmd_rm=$(resolve_command "rm")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 삭제 에뮬레이션: $target_file"
    else
        if [ -f "$target_file" ]; then
            "$cmd_sudo" "$cmd_rm" -f "$target_file"
            echo "   ✅ [삭제 완료] $target_subnet ($target_file)"
        else
            echo "   ⏭️ [건너뜀] 대상 설정 파일이 존재하지 않음: $target_subnet"
        fi
    fi
}

##
# 우분투 환경을 대상으로 단일 네트워크 1:1 파일 생성 로직을 수행합니다.
#
# @param $1 {string} 물리 인터페이스 이름
# @param $2 {string} 추가할 대상 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
##
configure_ubuntu_add() {
    local iface="$1"
    local target_subnet="$2"
    local gateway="$3"
    
    local subnet_safe
    subnet_safe=$(echo "$target_subnet" | tr '/' '_')
    local target_file="/etc/netplan/90-route-${subnet_safe}.yaml"

    local cmd_sudo
    local cmd_mktemp
    local cmd_mv
    local cmd_chmod
    cmd_sudo=$(resolve_command "sudo")
    cmd_mktemp=$(resolve_command "mktemp")
    cmd_mv=$(resolve_command "mv")
    cmd_chmod=$(resolve_command "chmod")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 추가 에뮬레이션: $target_subnet via $gateway → $target_file"
    else
        if [ -f "$target_file" ]; then
            echo "   ⏭️ [건너뜀] 이미 동일 대역의 설정 파일이 존재함: $target_subnet"
            return 0
        fi

        local tmp_file
        tmp_file=$("$cmd_mktemp" /tmp/netplan_route_XXXXXX.yaml)

        echo "network:" > "$tmp_file"
        echo "  version: 2" >> "$tmp_file"
        echo "  ethernets:" >> "$tmp_file"
        echo "    $iface:" >> "$tmp_file"
        echo "      routes:" >> "$tmp_file"
        echo "        - to: $target_subnet" >> "$tmp_file"
        echo "          via: $gateway" >> "$tmp_file"

        "$cmd_sudo" "$cmd_mv" "$tmp_file" "$target_file"
        "$cmd_sudo" "$cmd_chmod" 600 "$target_file"
        echo "   ✅ [추가 완료] $target_subnet ($target_file 생성됨)"
    fi
}

##
# 우분투 시스템의 변경된 Netplan 구성을 즉시 적용(Apply)합니다.
##
apply_ubuntu() {
    if [ "$DRY_RUN" = false ]; then
        local cmd_sudo
        local cmd_netplan
        cmd_sudo=$(resolve_command "sudo")
        cmd_netplan=$(resolve_command "netplan")
        echo
        echo "🔄 [시스템 반영 중] netplan apply 커맨드를 호출합니다..."
        "$cmd_sudo" "$cmd_netplan" apply
        echo "✨ Netplan 변경 사항이 시스템에 안전하게 반영되었습니다."
    fi
}

##
# RHEL/nmcli 환경을 대상으로 단일 라우팅 제거 로직을 수행합니다.
#
# @param $1 {string} NetworkManager 커넥션 프로파일 명/UUID
# @param $2 {string} 삭제할 대상 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
##
configure_rhel_remove() {
    local conn_target="$1"
    local target_subnet="$2"
    local gateway="$3"

    local cmd_sudo
    local cmd_nmcli
    cmd_sudo=$(resolve_command "sudo")
    cmd_nmcli=$(resolve_command "nmcli")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 삭제: $cmd_sudo $cmd_nmcli connection modify \"$conn_target\" -ipv4.routes \"$target_subnet $gateway\""
    else
        "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_target" -ipv4.routes "$target_subnet $gateway" 2>/dev/null
        echo "   ✅ [삭제 완료] $target_subnet"
    fi
}

##
# RHEL/nmcli 환경을 대상으로 단일 라우팅 추가 로직을 수행합니다.
#
# @param $1 {string} NetworkManager 커넥션 프로파일 명/UUID
# @param $2 {string} 추가할 대상 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
##
configure_rhel_add() {
    local conn_target="$1"
    local target_subnet="$2"
    local gateway="$3"

    local cmd_sudo
    local cmd_nmcli
    cmd_sudo=$(resolve_command "sudo")
    cmd_nmcli=$(resolve_command "nmcli")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 추가: $cmd_sudo $cmd_nmcli connection modify \"$conn_target\" +ipv4.routes \"$target_subnet $gateway\""
    else
        "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_target" +ipv4.routes "$target_subnet $gateway"
        echo "   ✅ [추가 완료] $target_subnet"
    fi
}

# --- 메인 비즈니스 로직 제어 런타임 ---

check_sudo

OS_TYPE=$(detect_os)
if [ "$OS_TYPE" == "unknown" ]; then
    help "지원하지 않는 운영체제 환경입니다. 관리자에게 문의하세요." "$LINENO"
    exit 1
fi

# [단계 1] 시스템 내 통신 가능한 물리 인터페이스 자가 진단 및 대화형 선택
mapfile -t CANDIDATES < <(ip -4 -o addr show | awk '{print $2}' | grep -vE '^(lo|docker|br-|veth|virbr)' | sort -u)

if [ ${#CANDIDATES[@]} -eq 0 ]; then
    help "시스템에서 IPv4가 할당된 유효한 물리 인터페이스를 찾을 수 없습니다." "$LINENO"
    exit 1
elif [ ${#CANDIDATES[@]} -eq 1 ]; then
    IFACE="${CANDIDATES[0]}"
else
    echo "================================================================================"
    echo "⚙️ [설정] 다중 네트워크 감지: VLAN 라우팅을 담당할 내부망 인터페이스를 선택하세요."
    
    # [인라인 UX 패치] 사용자가 선택할 메뉴 번호와 함께 해당 인터페이스의 "0.0.0.0" 게이트웨이 라우팅 정보를 즉시 병합 출력
    idx=1
    for cand in "${CANDIDATES[@]}"; do
        if command -v route >/dev/null 2>&1; then
            # 게이트웨이가 0.0.0.0 (또는 *) 인 직접 연결 라우팅 정보를 우선 추출
            ROUTE_INFO=$(route -4 2>/dev/null | awk -v iface="$cand" '$NF == iface && ($2 == "0.0.0.0" || $2 == "*") {print $0}' | head -n 1)
            # 조건에 맞는 라우팅이 없다면 해당 인터페이스의 임의 라우팅 출력
            [ -z "$ROUTE_INFO" ] && ROUTE_INFO=$(route -4 2>/dev/null | awk -v iface="$cand" '$NF == iface {print $0}' | head -n 1)
        else
            # route 명령어 부재 시 ip route 툴로 fallback
            ROUTE_INFO=$(ip -4 route show dev "$cand" 2>/dev/null | grep 'scope link' | head -n 1)
            [ -z "$ROUTE_INFO" ] && ROUTE_INFO=$(ip -4 route show dev "$cand" 2>/dev/null | head -n 1)
        fi
        
        printf "%d) %s: %s\n" "$idx" "$cand" "${ROUTE_INFO:-라우팅 정보 없음}"
        ((idx++))
    done
    
    # 커스텀 입력을 통해 번호를 받아 배열 인덱스로 매핑
    while true; do
        read -p " ├─▶ 인터페이스 번호를 입력하세요: " sel_idx
        if [[ "$sel_idx" =~ ^[0-9]+$ ]] && [ "$sel_idx" -ge 1 ] && [ "$sel_idx" -le "${#CANDIDATES[@]}" ]; then
            IFACE="${CANDIDATES[$((sel_idx-1))]}"
            break
        else
            echo "   ❌ 올바른 번호를 선택해 주세요."
        fi
    done
    echo "================================================================================"
    echo
fi

# 선택된 인터페이스를 바탕으로 서브넷 및 기본 게이트웨이 파생
IP_CIDR=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet / {print $2}' | head -n1)
CUR_SUBNET=$(get_network_address "$IP_CIDR")

# 기존 라우팅 테이블에서 해당 인터페이스를 통해 나가는 게이트웨이 탐색
DEF_GW=$(ip -4 route show dev "$IFACE" 2>/dev/null | grep -v 'scope link' | grep 'via' | awk '{print $3}' | head -n1)

# 게이트웨이가 없다면 네트워크 대역 IP의 마지막 자리에 1을 더하여 추정(Trunk GW 후보)
if [ ! -z "$DEF_GW" ]; then
    TRUNK_GW="$DEF_GW"
else
    IFS=. read -r n1 n2 n3 n4 <<< "${CUR_SUBNET%/*}"
    TRUNK_GW="$n1.$n2.$n3.$((n4 + 1))"
fi

# [단계 2] 프리플라이트 상태 점검 출력
show_current_routes "$IFACE" "$CUR_SUBNET"

# [단계 3] 'vlan route gateway ip' 대화형 입력 및 검증 파이프라인
echo "⚙️ [설정] 목적지 넥스트 홉(Gateway) IP 지정"
echo "   스크립트가 자동 계산한 기본 Trunk Gateway IP는 [$TRUNK_GW] 입니다."
echo "   다른 IP를 사용하려면 아래에 입력하시고, 기본값을 유지하려면 Enter 키를 누르세요."
read -p " ╰─▶ Next-hop Gateway IP [$TRUNK_GW]: " INPUT_GW
INPUT_GW=$(echo "$INPUT_GW" | tr -d '[:space:]')

if [ ! -z "$INPUT_GW" ]; then
    if [[ "$INPUT_GW" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        TRUNK_GW="$INPUT_GW"
    else
        help "입력한 Gateway IP($INPUT_GW) 형식이 올바른 IPv4 주소가 아닙니다." "$LINENO"
        exit 1
    fi
fi
echo

# [단계 4] 추가/삭제 대상 입력 대화형 프롬프트 및 인자 유효성 검증
if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = true ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    help "-a 옵션과 -r 옵션을 인자 없이 동시에 사용할 수 없습니다." "$LINENO"
    exit 1
fi

if [ "$HAS_A_FLAG" = false ] && [ "$HAS_R_FLAG" = false ] && [ -z "$ADD_VLAN_INPUT" ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    HAS_A_FLAG=true
fi

if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = false ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    echo "⚙️ [설정] 네트워크 추가/삭제 대역 지정 (자신이 속한 대역 제외)"
    echo "   - CIDR Notation, 여러 개인 경우 콤마(,)로 구분"
    echo "   - 예시: 10.11.0.0/16,10.12.0.0/16"
    read -p " ├─▶ Add VLAN Networks (추가할 대역, 없으면 Enter): " ADD_VLAN_INPUT
    read -p " ╰─▶ Remove VLAN Networks (삭제할 대역, 없으면 Enter): " REMOVE_VLAN_INPUT
    echo
else
    if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ]; then
        echo "⚙️ [설정] 네트워크 추가 대역 지정 (자신이 속한 대역 제외)"
        read -p " ╰─▶ Add VLAN Networks (CIDR, 콤마 구분): " ADD_VLAN_INPUT
        echo
    fi
    
    if [ "$HAS_R_FLAG" = true ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
        echo "⚙️ [설정] 네트워크 삭제 대역 지정 (자신이 속한 대역 제외)"
        read -p " ╰─▶ Remove VLAN Networks (CIDR, 콤마 구분): " REMOVE_VLAN_INPUT
        echo
    fi
fi

if [ -z "$(echo "$ADD_VLAN_INPUT$REMOVE_VLAN_INPUT" | tr -d '[:space:]')" ]; then
    help "추가 또는 삭제할 VLAN 네트워크가 지정되지 않았습니다. 작업을 취소합니다." "$LINENO"
    exit 1
fi

ADD_NETWORKS=()
REMOVE_NETWORKS=()
parse_networks "$ADD_VLAN_INPUT" ADD_NETWORKS
parse_networks "$REMOVE_VLAN_INPUT" REMOVE_NETWORKS

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

# NetworkManager(nmcli) 활성화 여부 식별 및 UUID 기반 완벽 제어
USE_NMCLI=false
if command -v nmcli >/dev/null 2>&1; then
    if nmcli device status 2>/dev/null | awk '{print $1, $3}' | grep -iq "^${IFACE} connected"; then
        USE_NMCLI=true
        CMD_NMCLI=$(resolve_command "nmcli")
        
        CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -g GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1)
        if [ -z "$CONN_TARGET" ]; then
            CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1)
        fi
        if [ -z "$CONN_TARGET" ]; then
            CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CONNECTION device show "$IFACE" 2>/dev/null | head -n1)
        fi
        [ -z "$CONN_TARGET" ] && CONN_TARGET="$IFACE"
        
        if [ "$OS_TYPE" == "ubuntu" ]; then
            echo "   💡 [감지] 우분투 환경이나 NetworkManager가 활성화되어 있습니다. nmcli 제어로 우회합니다."
        fi
    fi
fi

if [ "$OS_TYPE" == "rhel" ] && [ "$USE_NMCLI" = false ]; then
    USE_NMCLI=true
    CMD_NMCLI=$(resolve_command "nmcli")
    
    CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -g GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1)
    if [ -z "$CONN_TARGET" ]; then
        CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CON-UUID device show "$IFACE" 2>/dev/null | head -n1)
    fi
    if [ -z "$CONN_TARGET" ]; then
        CONN_TARGET=$(LC_ALL=C "$CMD_NMCLI" -t -f GENERAL.CONNECTION device show "$IFACE" 2>/dev/null | head -n1)
    fi
    [ -z "$CONN_TARGET" ] && CONN_TARGET="$IFACE"
fi

# [단계 5] 삭제(Remove) 파이프라인 진행
if [ ${#REMOVE_NETWORKS[@]} -gt 0 ]; then
    echo " 🗑️ [1단계] 라우팅 제거 작업 진행"
    for subnet in "${REMOVE_NETWORKS[@]}"; do
        if [ "$subnet" != "$CUR_SUBNET" ]; then
            if [ "$USE_NMCLI" = true ]; then
                configure_rhel_remove "$CONN_TARGET" "$subnet" "$TRUNK_GW"
            elif [ "$OS_TYPE" == "ubuntu" ]; then
                configure_ubuntu_remove "$subnet"
            fi
        else
            echo "   ⏭️ [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
        fi
    done
    echo
fi

# [단계 6] 추가(Add) 파이프라인 진행
if [ ${#ADD_NETWORKS[@]} -gt 0 ]; then
    echo " ➕ [2단계] 라우팅 추가 작업 진행"
    for subnet in "${ADD_NETWORKS[@]}"; do
        if [ "$subnet" != "$CUR_SUBNET" ]; then
            if [ "$USE_NMCLI" = true ]; then
                configure_rhel_add "$CONN_TARGET" "$subnet" "$TRUNK_GW"
            elif [ "$OS_TYPE" == "ubuntu" ]; then
                configure_ubuntu_add "$IFACE" "$subnet" "$TRUNK_GW"
            fi
        else
            echo "   ⏭️ [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
        fi
    done
    echo
fi

# OS 및 매니저별 최종 리로드 데몬 처리
if [ "$USE_NMCLI" = true ]; then
    if [ "$DRY_RUN" = false ]; then
        CMD_SUDO=$(resolve_command "sudo")
        echo
        echo "🔄 [시스템 반영 중] nmcli connection up 커맨드를 호출합니다..."
        "$CMD_SUDO" "$CMD_NMCLI" connection up "$CONN_TARGET"
        echo "✨ NetworkManager 변경 사항이 시스템에 안전하게 반영되었습니다."
    fi
elif [ "$OS_TYPE" == "ubuntu" ]; then
    apply_ubuntu
fi

echo "================================================================================"
echo "🎉 모든 라이프사이클 작업이 안전하게 완료되었습니다."
exit 0

