#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : add vlan routes.
# @license : Apache License 2.0
# @since : 2026-07-20
# @desc : support Rocky Linux 9+, Ubuntu 20+, RHEL 8+, Oracle Linux 9+, CentOS 7+
# @installation :
# 1. insert 'source <path>/<파일명>' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")
DRY_RUN=false
VLAN_INPUT=""

##
# 오류 발생 시 디버깅을 위한 콜스택 및 도움말 메시지를 출력합니다.
#
# @param $1 {string} 에러 원인 (Cause)
# @param $2 {int} 에러 발생 라인 번호 (Line)
#
# @return 도움말 및 디버깅 가이드 출력
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
    echo "Usage: sudo ./$FILENAME [OPTIONS]"
    echo "Options:"
    echo "  -h, --help               도움말 메시지를 출력합니다."
    echo "  -d, --dry-run            실제 시스템에 반영하지 않고 예정된 구성 설정을 화면에 출력합니다."
    echo "  --vlan-networks <CIDR>   쉼표(,)로 구분된 대상 VLAN CIDR 대역 목록을 입력합니다."
    echo "                           (예: 10.10.0.0/16,10.11.0.0/16,10.12.0.0/16)"
    echo
    echo "설명:"
    echo "  본 스크립트는 입력받은 VLAN 대역 중 서버가 속한 물리 인터페이스를 자동 식별한 뒤,"
    echo "  나머지 VLAN 대역으로 향하는 영구(Permanent) 정적 라우팅을 자동 구성합니다."
}

# 파라미터 옵션 처리 파이프라인
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
        --vlan-networks|--vlan-network)
            VLAN_INPUT="$2"
            shift 2
            ;;
        *)
            help "알 수 없는 옵션입니다: $1" "$LINENO"
            exit 1
            ;;
    esac
done

##
# 스크립트 실행을 위한 루트 권한(root/sudo) 여부를 검증합니다.
#
# @return 권한 부족 시 에러 메시지와 함께 스크립트 종료
##
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        help "이 스크립트는 반드시 root 권한 또는 sudo를 사용하여 실행해야 합니다." "$LINENO"
        exit 1
    fi
}

##
# 시스템의 배포판 종류를 분석하여 Ubuntu 계열과 RHEL 계열을 판별합니다.
#
# @return string "ubuntu" 또는 "rhel" 형식으로 표준 출력
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
# 특정 IP 주소가 지정된 CIDR 서브넷 대역에 포함되는지 여부를 비트 연산으로 검증합니다.
#
# @param $1 {string} 확인할 서버 IP 주소 (예: 10.11.1.14)
# @param $2 {string} CIDR 서브넷 대역 (예: 10.11.0.0/16)
#
# @return int 포함 시 0, 미포함 시 1 반환
##
ip_in_subnet() {
    local ip="$1"
    local cidr="$2"
    local net_ip=$(echo "$cidr" | cut -d/ -f1)
    local mask=$(echo "$cidr" | cut -d/ -f2)

    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    IFS=. read -r n1 n2 n3 n4 <<< "$net_ip"

    local ip_num=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
    local net_num=$(( (n1 << 24) + (n2 << 16) + (n3 << 8) + n4 ))
    local box=$(( 0xFFFFFFFF << (32 - mask) ))

    if [ $(( ip_num & box )) -eq $(( net_num & box )) ]; then
        return 0
    fi
    return 1
}

##
# CIDR 대역 정보를 기반으로 Trunk Gateway IP(기본 게이트웨이 IP + 1)를 동적으로 계산합니다.
#
# @param $1 {string} CIDR 네트워크 대역 주소 (예: 10.11.0.0/16)
#
# @return string 계산된 Trunk Gateway IP 주소
##
calculate_trunk_gateway() {
    local cidr="$1"
    local net_ip=$(echo "$cidr" | cut -d/ -f1)

    IFS=. read -r n1 n2 n3 n4 <<< "$net_ip"
    # 네트워크 주소의 마지막 자리에 2를 더하여 Trunk Gateway 생성 (네트워크주소+1=기본GW, 기본GW+1=TrunkGW)
    local trunk_i4=$((n4 + 2))
    echo "$n1.$n2.$n3.$trunk_i4"
}

##
# 가상 브릿지를 제외한 순수 물리 인터페이스 중에서 매칭되는 IP를 확보한 대상을 탐색합니다.
#
# @return string "인터페이스명 현재대역 계산된TrunkGW" 형태로 출력 (실패 시 공백 반환)
##
find_vlan_interface() {
    for net_dir in /sys/class/net/*; do
        local iface=$(basename "$net_dir")
        
        # 가상 브릿지 및 컨테이너 인터페이스 배제 (물리 장치 링크가 존재하는지 검증)
        if [ -d "$net_dir/device" ]; then
            local ip_addresses=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            for ip in $ip_addresses; do
                for subnet in "${VLAN_NETWORKS[@]}"; do
                    if ip_in_subnet "$ip" "$subnet"; then
                        local gw=$(calculate_trunk_gateway "$subnet")
                        echo "$iface $subnet $gw"
                        return 0
                    fi
                done
            done
        fi
    done
    return 1
}

##
# 우분투 환경을 대상으로 영구 라우팅 설정을 처리합니다. Dry-run 활성화 시 표준 출력으로 에뮬레이션합니다.
#
# @param $1 {string} 물리 인터페이스 이름
# @param $2 {string} 현재 서버가 소속된 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
#
# @return Netplan 적용 또는 에뮬레이션 결과 출력
##
configure_ubuntu() {
    local iface="$1"
    local current_subnet="$2"
    local gateway="$3"
    local target_file="/etc/netplan/90-inter-vlan-routes.yaml"

    if [ "$DRY_RUN" = true ]; then
        echo -e "\n--- [DRY-RUN] 생성될 Netplan 드롭인 파일 템플릿 ($target_file) ---"
        echo "network:"
        echo "  version: 2"
        echo "  ethernets:"
        echo "    $iface:"
        echo "      routes:"
        for subnet in "${VLAN_NETWORKS[@]}"; do
            if [ "$subnet" != "$current_subnet" ]; then
                echo "        - to: $subnet"
                echo "          via: $gateway"
            fi
        done
        echo -e "----------------------------------------------------------------------\n"
        echo "[DRY-RUN] 시스템 변경사항이 없으므로 'netplan apply' 프로세스를 생략합니다."
    else
        echo "network:" > "$target_file"
        echo "  version: 2" >> "$target_file"
        echo "  ethernets:" >> "$target_file"
        echo "    $iface:" >> "$target_file"
        echo "      routes:" >> "$target_file"

        for subnet in "${VLAN_NETWORKS[@]}"; do
            if [ "$subnet" != "$current_subnet" ]; then
                echo "        - to: $subnet" >> "$target_file"
                echo "          via: $gateway" >> "$target_file"
            fi
        done

        chmod 600 "$target_file"
        netplan apply
        echo "Netplan 드롭인 라우팅 설정 파일이 시스템에 반영되었습니다."
    fi
}

##
# RHEL 및 CentOS 7+ 환경을 대상으로 영구 정적 라우팅을 반영합니다. 레거시 nmcli 호환 파싱 알고리즘을 사용합니다.
#
# @param $1 {string} 물리 인터페이스 이름
# @param $2 {string} 현재 서버가 소속된 VLAN 대역
# @param $3 {string} 계산된 Trunk Gateway IP 주소
#
# @return nmcli 적용 또는 에뮬레이션 커맨드 출력
##
configure_rhel() {
    local iface="$1"
    local current_subnet="$2"
    local gateway="$3"

    # CentOS 7 구형 nmcli 호환성 및 다국어 로캘 독립성 확보를 위한 파싱 파이프라인
    local conn_name=$(LC_ALL=C nmcli device show "$iface" 2>/dev/null | grep "GENERAL.CONNECTION:" | awk '{print $2}')
    if [ -z "$conn_name" ]; then
        conn_name=$(LC_ALL=C nmcli connection show --active 2>/dev/null | grep "$iface" | head -n1 | awk '{print $1}')
        if [ -z "$conn_name" ]; then
            conn_name="$iface"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "\n--- [DRY-RUN] NetworkManager 실행 예정 명령어 리스트 ---"
        for subnet in "${VLAN_NETWORKS[@]}"; do
            if [ "$subnet" != "$current_subnet" ]; then
                echo " > nmcli connection modify \"$conn_name\" +ipv4.routes \"$subnet $gateway\""
            fi
        done
        echo " > nmcli connection up \"$conn_name\""
        echo -e "----------------------------------------------------------------------\n"
        echo "[DRY-RUN] 시스템 변경사항이 없으므로 커넥션 갱신 프로세스를 생략합니다."
    else
        for subnet in "${VLAN_NETWORKS[@]}"; do
            if [ "$subnet" != "$current_subnet" ]; then
                nmcli connection modify "$conn_name" +ipv4.routes "$subnet $gateway"
            fi
        done
        nmcli connection up "$conn_name"
        echo "NetworkManager 인터페이스 프로파일에 라우팅 이정표가 갱신되었습니다."
    fi
}

##
# 목적지 리스트 출력을 위해 현재 소속 대역을 제외한 필터링 목록을 생성합니다.
#
# @return string 필터링된 목적지 서브넷 목록
##
filter_current_net(){
    local filtered=()
    for network in "${VLAN_NETWORKS[@]}"; do
        [[ "$network" == "$CUR_SUBNET" ]] || filtered+=("$network")
    done
    echo "${filtered[@]}"
}

# --- 메인 비즈니스 로직 제어 런타임 ---

check_privileges

OS_TYPE=$(detect_os)
if [ "$OS_TYPE" == "unknown" ]; then
    help "지원하지 않는 운영체제 환경입니다. 관리자에게 문의하세요." "$LINENO"
    exit 1
fi

# 파라미터가 비어있을 경우 환경변수 조회
if [ -z "$VLAN_INPUT" ]; then
    VLAN_INPUT="$ENV_VLAN_NETWORKS"
fi

# 둘 다 비어있을 경우 가이드 출력 후 즉시 종료
if [ -z "$VLAN_INPUT" ]; then
    help "VLAN 네트워크 목록이 지정되지 않았습니다. --vlan-networks 옵션을 사용하거나 ENV_VLAN_NETWORKS 환경변수를 선언하십시오." "$LINENO"
    exit 1
fi

# 콤마 구분자 파싱 및 공백 Trim 처리 연산
VLAN_NETWORKS=()
IFS=',' read -r -a raw_networks <<< "$VLAN_INPUT"
for net in "${raw_networks[@]}"; do
    trimmed=$(echo "$net" | tr -d '[:space:]')
    if [ ! -z "$trimmed" ]; then
        VLAN_NETWORKS+=("$trimmed")
    fi
done

VLAN_INFO=$(find_vlan_interface)
if [ $? -ne 0 ] || [ -z "$VLAN_INFO" ]; then
    help "입력된 VLAN 대역 IP를 정상적으로 확보한 물리 인터페이스를 검색하지 못했습니다." "$LINENO"
    exit 1
fi

IFACE=$(echo "$VLAN_INFO" | awk '{print $1}')
CUR_SUBNET=$(echo "$VLAN_INFO" | awk '{print $2}')
TRUNK_GW=$(echo "$VLAN_INFO" | awk '{print $3}')

echo "================================================================================"
echo " [안내] 가상 인프라 검증 및 인터페이스 식별 완료"
printf "  - 모드                 :"
if [ "$DRY_RUN" = true ]; then
    echo " DRY-RUN (시뮬레이션 모드)"
else
    echo " RUN (실제 시스템 반영 모드)"
fi
echo "  - 감지된 OS 유형       : $OS_TYPE"
echo "  - 할당 물리 인터페이스 : $IFACE"
echo "  - 서버 소속 VLAN 대역  : $CUR_SUBNET"
echo "  - 목적지 넥스트 홉(GW) : $TRUNK_GW"
echo "  - 목적지 VLAN 목록     : $(filter_current_net)"
echo "================================================================================"

if [ "$OS_TYPE" == "ubuntu" ]; then
    configure_ubuntu "$IFACE" "$CUR_SUBNET" "$TRUNK_GW"
elif [ "$OS_TYPE" == "rhel" ]; then
    configure_rhel "$IFACE" "$CUR_SUBNET" "$TRUNK_GW"
fi

echo "작업이 안전하게 완료되었습니다."
exit 0

