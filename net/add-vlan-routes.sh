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
# 커널 라우팅 테이블(ip route)을 직접 조회하여 물리 인터페이스와 소속 서브넷을 스스로 식별합니다.
#
# @returns {string} "인터페이스명 현재대역(CIDR) 기본게이트웨이 Trunk게이트웨이" 형태로 출력
##
find_vlan_interface() {
    local def_gw
    def_gw=$(ip -4 route show default 2>/dev/null | awk '{print $3}' | head -n1)
    
    local trunk_gw=""
    if [ ! -z "$def_gw" ]; then
        IFS=. read -r g1 g2 g3 g4 <<< "$def_gw"
        trunk_gw="${g1}.${g2}.${g3}.$((g4 + 1))"
    fi

    local default_iface
    default_iface=$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -n1)

    if [ ! -z "$default_iface" ] && [ -d "/sys/class/net/$default_iface/device" ]; then
        local ip_cidr
        ip_cidr=$(ip -4 addr show dev "$default_iface" 2>/dev/null | awk '/inet / {print $2}' | head -n1)
        if [ ! -z "$ip_cidr" ]; then
            local subnet
            subnet=$(get_network_address "$ip_cidr")
            echo "$default_iface $subnet $def_gw $trunk_gw"
            return 0
        fi
    fi

    return 1
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
        echo "   🧪 [DRY-RUN] 추가 에뮬레이션: $target_subnet via $gateway &rarr; $target_file"
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
# RHEL 환경을 대상으로 nmcli 기반 단일 라우팅 제거 로직을 수행합니다.
#
# @param $1 {string} NetworkManager 커넥션 프로파일 명
# @param $2 {string} 삭제할 대상 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
##
configure_rhel_remove() {
    local conn_name="$1"
    local target_subnet="$2"
    local gateway="$3"

    local cmd_sudo
    local cmd_nmcli
    cmd_sudo=$(resolve_command "sudo")
    cmd_nmcli=$(resolve_command "nmcli")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 삭제: $cmd_sudo $cmd_nmcli connection modify \"$conn_name\" -ipv4.routes \"$target_subnet $gateway\""
    else
        "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_name" -ipv4.routes "$target_subnet $gateway" 2>/dev/null
        echo "   ✅ [삭제 완료] $target_subnet"
    fi
}

##
# RHEL 환경을 대상으로 nmcli 기반 단일 라우팅 추가 로직을 수행합니다.
#
# @param $1 {string} NetworkManager 커넥션 프로파일 명
# @param $2 {string} 추가할 대상 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
##
configure_rhel_add() {
    local conn_name="$1"
    local target_subnet="$2"
    local gateway="$3"

    local cmd_sudo
    local cmd_nmcli
    cmd_sudo=$(resolve_command "sudo")
    cmd_nmcli=$(resolve_command "nmcli")

    if [ "$DRY_RUN" = true ]; then
        echo "   🧪 [DRY-RUN] 추가: $cmd_sudo $cmd_nmcli connection modify \"$conn_name\" +ipv4.routes \"$target_subnet $gateway\""
    else
        "$cmd_sudo" "$cmd_nmcli" connection modify "$conn_name" +ipv4.routes "$target_subnet $gateway"
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

# [단계 1] 커널 정보를 바탕으로 물리 인터페이스 및 서버 소속망 자가 진단
VLAN_INFO=$(find_vlan_interface)
if [ $? -ne 0 ] || [ -z "$VLAN_INFO" ]; then
    help "시스템 라우팅 테이블에서 통신 가능한 물리 인터페이스와 서브넷을 식별하지 못했습니다." "$LINENO"
    exit 1
fi

IFACE=$(echo "$VLAN_INFO" | awk '{print $1}')
CUR_SUBNET=$(echo "$VLAN_INFO" | awk '{print $2}')
DEF_GW=$(echo "$VLAN_INFO" | awk '{print $3}')
TRUNK_GW=$(echo "$VLAN_INFO" | awk '{print $4}')

# [단계 2] 프리플라이트 상태 점검 출력 (Netmask 정보 포함, 정렬 강화)
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

# 6. -a 와 -r 이 모두 인자 없이 단독으로 쓰인 경우 허용하지 않음
if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = true ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    help "-a 옵션과 -r 옵션을 인자 없이 동시에 사용할 수 없습니다." "$LINENO"
    exit 1
fi

# 3. 아무 옵션이 없을 경우 -a 와 동일하게 간주
if [ "$HAS_A_FLAG" = false ] && [ "$HAS_R_FLAG" = false ] && [ -z "$ADD_VLAN_INPUT" ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    HAS_A_FLAG=true
fi

# 2 & 3. -a 가 단독으로 쓰였을 때 (또는 옵션이 없을 때) 기존처럼 양쪽 모두 프롬프트 제공
if [ "$HAS_A_FLAG" = true ] && [ -z "$ADD_VLAN_INPUT" ] && [ "$HAS_R_FLAG" = false ] && [ -z "$REMOVE_VLAN_INPUT" ]; then
    echo "⚙️ [설정] 네트워크 추가/삭제 대역 지정 (자신이 속한 대역 제외)"
    echo "   - CIDR Notation, 여러 개인 경우 콤마(,)로 구분"
    echo "   - 예시: 10.11.0.0/16,10.12.0.0/16"
    read -p " ├─▶ Add VLAN Networks (추가할 대역, 없으면 Enter): " ADD_VLAN_INPUT
    read -p " ╰─▶ Remove VLAN Networks (삭제할 대역, 없으면 Enter): " REMOVE_VLAN_INPUT
    echo
else
    # 5. -r 이 단독으로 쓰이거나, 한쪽에만 값이 비어있을 때 각각 개별 프롬프트 제공
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

# 유효성 최종 확인 (추가 및 삭제 정보가 모두 비어있는 경우)
if [ -z "$(echo "$ADD_VLAN_INPUT$REMOVE_VLAN_INPUT" | tr -d '[:space:]')" ]; then
    help "추가 또는 삭제할 VLAN 네트워크가 지정되지 않았습니다. 작업을 취소합니다." "$LINENO"
    exit 1
fi

# 입력된 콤마 문자열들을 정제하여 배열로 적재
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

# RHEL 계열 공통 Connection Name 추출
if [ "$OS_TYPE" == "rhel" ]; then
    CMD_NMCLI=$(resolve_command "nmcli")
    CONN_NAME=$(LC_ALL=C "$CMD_NMCLI" device show "$IFACE" 2>/dev/null | grep "GENERAL.CONNECTION:" | awk '{print $2}')
    if [ -z "$CONN_NAME" ]; then
        CONN_NAME=$(LC_ALL=C "$CMD_NMCLI" connection show --active 2>/dev/null | grep "$IFACE" | head -n1 | awk '{print $1}')
        [ -z "$CONN_NAME" ] && CONN_NAME="$IFACE"
    fi
fi

# [단계 5] 삭제(Remove) 파이프라인 진행
if [ ${#REMOVE_NETWORKS[@]} -gt 0 ]; then
    echo " 🗑️ [1단계] 라우팅 제거 작업 진행"
    for subnet in "${REMOVE_NETWORKS[@]}"; do
        if [ "$subnet" != "$CUR_SUBNET" ]; then
            if [ "$OS_TYPE" == "ubuntu" ]; then
                configure_ubuntu_remove "$subnet"
            elif [ "$OS_TYPE" == "rhel" ]; then
                configure_rhel_remove "$CONN_NAME" "$subnet" "$TRUNK_GW"
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
            if [ "$OS_TYPE" == "ubuntu" ]; then
                configure_ubuntu_add "$IFACE" "$subnet" "$TRUNK_GW"
            elif [ "$OS_TYPE" == "rhel" ]; then
                configure_rhel_add "$CONN_NAME" "$subnet" "$TRUNK_GW"
            fi
        else
            echo "   ⏭️ [건너뜀] 현재 서버의 소속 대역과 동일한 입력 정보는 작업 대상에서 제외됩니다: $subnet"
        fi
    done
    echo
fi

# OS별 최종 리로드 데몬 처리
if [ "$OS_TYPE" == "ubuntu" ]; then
    apply_ubuntu
elif [ "$OS_TYPE" == "rhel" ]; then
    if [ "$DRY_RUN" = false ]; then
        CMD_SUDO=$(resolve_command "sudo")
        echo
        echo "🔄 [시스템 반영 중] nmcli connection up 커맨드를 호출합니다..."
        "$CMD_SUDO" "$CMD_NMCLI" connection up "$CONN_NAME"
        echo "✨ NetworkManager 변경 사항이 시스템에 안전하게 반영되었습니다."
    fi
fi

echo "================================================================================"
echo "🎉 모든 라이프사이클 작업이 안전하게 완료되었습니다."
exit 0
