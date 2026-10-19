#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : Docker network management CLI.
# @license : Apache License 2.0
# @since : 2026-10-19
# @desc : support RHEL 7+, Oracle Linux 7+, Ubuntu 18.04+, RockyOS 8+, CentOS 7+
# @installation : 
# 1. insert 'source <path>/dknetcli.sh.completion' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/dknetcli.sh' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

SUDO_CMD=()
DOCKER_CMD=()

COMMAND_ACTION=""
NET_NAME=""
NET_BRIDGE=""
NET_GATEWAY=""
NET_SUBNET=""
OPT_CONTAINERS=false

##
# 스크립트 실행 오류 시 진단 정보와 함께 사용법(Usage)을 표준 출력으로 안내합니다.
#
# @param $1 {string} 실패 원인 메시지
# @param $2 {number} 오류 발생 라인 번호
#
# @return 사용법 화면 출력
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
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi 
  echo 
  echo "사용법:"
  echo "  $FILENAME network create --name <network-name> --bridge <bridge-name> --gateway <network-gateway> --subnet <network-subnet>"
  echo "  $FILENAME network delete --name <network-name>"
  echo "  $FILENAME network inspect [--name <network-name>] [--containers]"
  echo "  $FILENAME --help"
  echo
  echo "서브커맨드:"
  echo "  network create   Docker 브릿지 네트워크 생성"
  echo "  network delete   Docker 브릿지 네트워크 삭제"
  echo "  network inspect  Docker 브릿지 네트워크 및 연결된 컨테이너 정보 조회"
  echo
  echo "옵션 상세:"
  echo "  --name        <network-name>     대상 Docker 네트워크 이름"
  echo "  --bridge      <bridge-name>      호스트 커널에 바인딩할 브릿지 인터페이스 이름 (최대 15자, create 전용)"
  echo "  --gateway     <network-gateway>  네트워크 게이트웨이 IPv4 주소 (예: 172.31.255.1, create 전용)"
  echo "  --subnet      <network-subnet>   CIDR 포맷의 서브넷 대역 (예: 172.31.255.0/24, create 전용)"
  echo "  --containers                     네트워크에 연결된 컨테이너 상세 정보 포함 (inspect 전용)"
  echo "  --help                           도움말 출력"
  echo
}

##
# IPv4 주소 문자열을 32비트 부호 없는 정수형으로 변환합니다.
#
# @param $1 {string} 변환할 IPv4 주소 문자열
#
# @return echo를 통한 32비트 정수 출력
##
ip_to_int() {
  local ip="$1"
  local a b c d
  IFS='.' read -r a b c d <<< "$ip"
  echo "$(( (a << 24) + (b << 16) + (c << 8) + d ))"
}

##
# 주어진 문자열이 표준 IPv4 형식(0.0.0.0 -> 255.255.255.255)에 부합하는지 검증합니다.
#
# @param $1 {string} 검증 대상 IP 문자열
#
# @return 유효한 경우 0 반환, 유효하지 않은 경우 1 반환
##
validate_ipv4() {
  local ip="$1"
  local rx='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'

  if [[ ! "$ip" =~ $rx ]]; then
    return 1
  fi

  local octet
  for octet in "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; do
    if (( octet < 0 || octet > 255 )); then
      return 1
    fi
  done

  return 0
}

##
# 주어진 서브넷 문자열이 유효한 IPv4 CIDR 형식인지 검증합니다.
#
# @param $1 {string} 검증 대상 CIDR 문자열
#
# @return 유효한 경우 0 반환, 유효하지 않은 경우 1 반환
##
validate_cidr() {
  local cidr="$1"
  local rx='^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})$'

  if [[ ! "$cidr" =~ $rx ]]; then
    return 1
  fi

  local base_ip="${BASH_REMATCH[1]}"
  local prefix="${BASH_REMATCH[2]}"

  if ! validate_ipv4 "$base_ip"; then
    return 1
  fi

  if (( prefix < 1 || prefix > 30 )); then
    return 1
  fi

  return 0
}

##
# 리눅스 커널의 네트워크 인터페이스 이름 제약 조건(IFNAMSIZ, 최대 15자 영숫자)에 적합한지 검증합니다.
#
# @param $1 {string} 검증 대상 브릿지 이름
#
# @return 유효한 경우 0 반환, 유효하지 않은 경우 1 반환
##
validate_bridge_name() {
  local br="$1"
  if [[ ! "$br" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    return 1
  fi

  if (( ${#br} > 15 )); then
    return 1
  fi

  return 0
}

##
# Docker 네트워크 식별자 이름 규칙에 부합하는지 검증합니다.
#
# @param $1 {string} 검증 대상 네트워크 이름
#
# @return 유효한 경우 0 반환, 유효하지 않은 경우 1 반환
##
validate_network_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    return 1
  fi
  return 0
}

##
# 게이트웨이 IP 주소가 주어진 서브넷 CIDR 대역 범위 내에 포함되는지 비트 연산으로 검증합니다.
#
# @param $1 {string} 서브넷 CIDR 문자열 (예: 172.31.255.0/24)
# @param $2 {string} 게이트웨이 IPv4 문자열 (예: 172.31.255.1)
#
# @return 서브넷 내 포함 시 0 반환, 불일치 시 1 반환
##
validate_gateway_in_subnet() {
  local subnet="$1"
  local gateway="$2"

  local base_ip="${subnet%/*}"
  local prefix="${subnet#*/}"

  local ip_int gw_int mask net_addr gw_net
  ip_int=$(ip_to_int "$base_ip")
  gw_int=$(ip_to_int "$gateway")

  mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
  net_addr=$(( ip_int & mask ))
  gw_net=$(( gw_int & mask ))

  if (( net_addr != gw_net )); then
    return 1
  fi

  return 0
}

##
# CLI 파라미터를 파싱하고 무결성을 전수 검사합니다.
#
# @param $@ {array} 실행 인자 목록
#
# @return 성공 시 0 반환, 검증 실패 시 도움말 출력 후 프로세스 종료
##
parse_arguments() {
  if (( $# == 0 )); then
    help "명령어 파라미터가 지정되지 않았습니다." "$LINENO"
    exit 1
  fi

  if [[ "$1" == "--help" ]]; then
    help "" "$LINENO"
    exit 0
  fi

  if [[ "$1" =~ ^-[a-zA-Z0-9] ]]; then
    help "단축 옵션('$1')은 허용되지 않습니다. 정규 롱 옵션(Full Option)을 사용하십시오." "$LINENO"
    exit 1
  fi

  if [[ "$1" != "network" ]]; then
    help "지원하지 않는 명령 형식이거나 필수 명령어('network')가 올바르지 않습니다: '$1'" "$LINENO"
    exit 1
  fi

  if (( $# < 2 )); then
    help "'network' 뒤에 서브커맨드('create', 'delete', 'inspect')가 지정되지 않았습니다." "$LINENO"
    exit 1
  fi

  if [[ "$2" == "--help" ]]; then
    help "" "$LINENO"
    exit 0
  fi

  case "$2" in
    create)
      COMMAND_ACTION="create"
      ;;
    delete)
      COMMAND_ACTION="delete"
      ;;
    inspect)
      COMMAND_ACTION="inspect"
      ;;
    -*)
      help "단축 옵션 또는 잘못된 옵션('$2')이 서브커맨드 위치에 입력되었습니다." "$LINENO"
      exit 1
      ;;
    *)
      help "지원하지 않는 서브커맨드입니다: '$2' ('create', 'delete', 'inspect' 만 지원합니다)" "$LINENO"
      exit 1
      ;;
  esac

  shift 2

  while (( $# > 0 )); do
    case "$1" in
      --name)
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--name' 옵션에 유효한 네트워크 이름이 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_NAME="$2"
        shift 2
        ;;
      --bridge)
        if [[ "$COMMAND_ACTION" != "create" ]]; then
          help "'--bridge' 옵션은 'network create' 명령에서만 사용할 수 있습니다." "$LINENO"
          exit 1
        fi
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--bridge' 옵션에 유효한 브릿지 이름이 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_BRIDGE="$2"
        shift 2
        ;;
      --gateway)
        if [[ "$COMMAND_ACTION" != "create" ]]; then
          help "'--gateway' 옵션은 'network create' 명령에서만 사용할 수 있습니다." "$LINENO"
          exit 1
        fi
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--gateway' 옵션에 유효한 게이트웨이 주소가 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_GATEWAY="$2"
        shift 2
        ;;
      --subnet)
        if [[ "$COMMAND_ACTION" != "create" ]]; then
          help "'--subnet' 옵션은 'network create' 명령에서만 사용할 수 있습니다." "$LINENO"
          exit 1
        fi
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--subnet' 옵션에 유효한 CIDR 서브넷이 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_SUBNET="$2"
        shift 2
        ;;
      --containers)
        if [[ "$COMMAND_ACTION" != "inspect" ]]; then
          help "'--containers' 옵션은 'network inspect' 명령에서만 사용할 수 있습니다." "$LINENO"
          exit 1
        fi
        OPT_CONTAINERS=true
        shift 1
        ;;
      --help)
        help "" "$LINENO"
        exit 0
        ;;
      -*)
        help "단축 옵션('$1')은 허용되지 않습니다. 정규 롱 옵션(Full Option)을 사용하십시오." "$LINENO"
        exit 1
        ;;
      *)
        help "알 수 없는 파라미터가 입력되었습니다: '$1'" "$LINENO"
        exit 1
        ;;
    esac
  done

  if [[ -n "$NET_NAME" ]]; then
    if ! validate_network_name "$NET_NAME"; then
      help "네트워크 이름('$NET_NAME')이 올바르지 않습니다. (영문/숫자로 시작하며 영문, 숫자, '-', '_', '.' 만 허용)" "$LINENO"
      exit 1
    fi
  fi

  if [[ "$COMMAND_ACTION" == "create" ]]; then
    if [[ -z "$NET_NAME" ]]; then
      help "필수 파라미터 '--name'이 지정되지 않았습니다." "$LINENO"
      exit 1
    fi

    if [[ -z "$NET_BRIDGE" ]]; then
      help "필수 파라미터 '--bridge'가 지정되지 않았습니다." "$LINENO"
      exit 1
    fi

    if [[ -z "$NET_GATEWAY" ]]; then
      help "필수 파라미터 '--gateway'가 지정되지 않았습니다." "$LINENO"
      exit 1
    fi

    if [[ -z "$NET_SUBNET" ]]; then
      help "필수 파라미터 '--subnet'이 지정되지 않았습니다." "$LINENO"
      exit 1
    fi

    if ! validate_bridge_name "$NET_BRIDGE"; then
      help "브릿지 인터페이스 이름('$NET_BRIDGE')은 커널 한계(IFNAMSIZ)로 인해 최대 15자 이하의 영문/숫자/-/_/. 조합이어야 합니다. (현재 길이: ${#NET_BRIDGE}자)" "$LINENO"
      exit 1
    fi

    if ! validate_ipv4 "$NET_GATEWAY"; then
      help "게이트웨이 주소('$NET_GATEWAY')가 올바른 IPv4 형식이 아닙니다." "$LINENO"
      exit 1
    fi

    if ! validate_cidr "$NET_SUBNET"; then
      help "서브넷 주소('$NET_SUBNET')가 올바른 IPv4 CIDR(prefix: 1 -> 30) 형식이 아닙니다." "$LINENO"
      exit 1
    fi

    if ! validate_gateway_in_subnet "$NET_SUBNET" "$NET_GATEWAY"; then
      help "게이트웨이('$NET_GATEWAY')가 지정된 서브넷 대역('$NET_SUBNET')에 포함되지 않습니다." "$LINENO"
      exit 1
    fi
  elif [[ "$COMMAND_ACTION" == "delete" ]]; then
    if [[ -z "$NET_NAME" ]]; then
      help "필수 파라미터 '--name'이 지정되지 않았습니다." "$LINENO"
      exit 1
    fi
  fi
}

##
# 시스템의 Docker 바이너리 및 실행 권한, 소켓 연결 상태를 선행 확인합니다.
#
# @param 없음
#
# @return 전역 배열 SUDO_CMD 및 DOCKER_CMD 초기화
##
ensure_privileges_early() {
  if ! command -v docker >/dev/null 2>&1; then
    help "시스템에 docker 바이너리가 설치되어 있지 않습니다." "$LINENO"
    exit 1
  fi

  if (( EUID == 0 )); then
    SUDO_CMD=()
    DOCKER_CMD=(docker)
  else
    if ! command -v sudo >/dev/null 2>&1; then
      help "루트 권한 작업을 위해 sudo 명령어가 필요하나 시스템에 없습니다." "$LINENO"
      exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
      echo "🔐 [AUTH] 네트워크 제어 및 Docker 관리를 위해 sudo 권한 확인이 필요합니다."
      sudo -v || {
        help "sudo 권한 획득에 실패하여 작업을 진행할 수 없습니다." "$LINENO"
        exit 1
      }
    fi
    SUDO_CMD=(sudo)

    if docker info >/dev/null 2>&1; then
      DOCKER_CMD=(docker)
    else
      DOCKER_CMD=(sudo docker)
    fi
  fi

  if ! "${DOCKER_CMD[@]}" info >/dev/null 2>&1; then
    help "Docker 데몬이 현재 실행 중이지 않거나 소켓 접근이 불가능합니다." "$LINENO"
    exit 1
  fi
}

##
# 단일 Docker bridge network 정보 및 연결된 컨테이너 정보를 출력합니다.
#
# @param $1 {string} Docker 네트워크 식별자 (Name 또는 ID)
# @param $2 {boolean} 컨테이너 정보 포함 여부 (true | false)
#
# @return 정형화된 네트워크 상세 정보 화면 출력
##
inspect_single_network() {
  local target_net="$1"
  local show_containers="$2"

  local net_info
  net_info=$("${DOCKER_CMD[@]}" network inspect "$target_net" --format '{{.Id}}|{{.Name}}|{{.Driver}}|{{.Scope}}|{{range .IPAM.Config}}{{.Subnet}}|{{.Gateway}}{{end}}|{{index .Options "com.docker.network.bridge.name"}}' 2>/dev/null || true)

  if [[ -z "$net_info" ]]; then
    return 1
  fi

  local id name driver scope subnet gateway bridge_dev
  IFS='|' read -r id name driver scope subnet gateway bridge_dev <<< "$net_info"

  echo "================================================================================"
  printf "🌐 NETWORK: %s (ID: %.12s)\n" "$name" "$id"
  echo "--------------------------------------------------------------------------------"
  printf " - %-13s: %s\n" "Driver" "$driver"
  printf " - %-13s: %s\n" "Scope" "$scope"
  printf " - %-13s: %s\n" "Subnet" "${subnet:-N/A}"
  printf " - %-13s: %s\n" "Gateway" "${gateway:-N/A}"
  printf " - %-13s: %s\n" "Bridge Dev" "${bridge_dev:-N/A}"

  if [[ "$show_containers" == "true" ]]; then
    echo " - Containers   :"
    local container_lines
    container_lines=$("${DOCKER_CMD[@]}" network inspect "$target_net" --format '{{range $k, $v := .Containers}}{{$v.Name}}|{{printf "%.12s" $k}}|{{$v.IPv4Address}}|{{$v.MacAddress}}{{"\n"}}{{end}}' 2>/dev/null || true)

    if [[ -z "${container_lines// /}" ]]; then
      echo "     (연결된 컨테이너 없음)"
    else
      local c_name c_id c_ipv4 c_mac
      while IFS='|' read -r c_name c_id c_ipv4 c_mac; do
        if [[ -n "$c_name" ]]; then
          printf "   * [%s] (ID: %s)\n" "$c_name" "$c_id"
          printf "     - %-12s: %s\n" "IPv4 Address" "${c_ipv4:-N/A}"
          printf "     - %-12s: %s\n" "MAC Address" "${c_mac:-N/A}"
        fi
      done <<< "$container_lines"
    fi
  fi
  echo "================================================================================"
  echo
}

##
# 전체 또는 특정 Docker bridge network 및 연결된 컨테이너 정보를 조회합니다.
#
# @param 없음
#
# @return 조회된 결과 화면 출력
##
inspect_docker_networks() {
  if [[ -n "$NET_NAME" ]]; then
    # 특정 네트워크 조회
    if ! "${DOCKER_CMD[@]}" network inspect "$NET_NAME" >/dev/null 2>&1; then
      help "조회할 Docker 네트워크 '$NET_NAME'가 존재하지 않습니다." "$LINENO"
      exit 1
    fi

    local driver
    driver=$("${DOCKER_CMD[@]}" network inspect "$NET_NAME" --format '{{.Driver}}' 2>/dev/null || true)
    if [[ "$driver" != "bridge" ]]; then
      help "네트워크 '$NET_NAME'는 'bridge' 드라이버 네트워크가 아닙니다 (현재 드라이버: '$driver')." "$LINENO"
      exit 1
    fi

    inspect_single_network "$NET_NAME" "$OPT_CONTAINERS"
  else
    # 전체 bridge 네트워크 조회
    local bridge_networks
    bridge_networks=$("${DOCKER_CMD[@]}" network ls --filter "driver=bridge" --format '{{.Name}}' 2>/dev/null || true)

    if [[ -z "${bridge_networks// /}" ]]; then
      echo "ℹ️  시스템에 등록된 Docker bridge 네트워크가 존재하지 않습니다."
      return 0
    fi

    local net
    while read -r net; do
      if [[ -n "$net" ]]; then
        inspect_single_network "$net" "$OPT_CONTAINERS"
      fi
    done <<< "$bridge_networks"
  fi
}

##
# Docker bridge network를 생성하고 호스트 커널 인터페이스 바인딩 및 상태를 정밀 진단합니다.
#
# @param 없음
#
# @return Docker 네트워크 생성 결과 화면 출력
##
setup_docker_network() {
  echo "🌐 [네트워크] Docker 브릿지 네트워크 점검 및 생성 시작..."

  if "${DOCKER_CMD[@]}" network inspect "${NET_NAME}" >/dev/null 2>&1; then
    echo "  ℹ️  [정보] Docker 네트워크 '${NET_NAME}' 가 이미 존재하므로 생성을 건너뜁니다."
    return 0
  fi

  if ip link show dev "${NET_BRIDGE}" >/dev/null 2>&1; then
    help "호스트 커널에 브릿지 인터페이스 이름('${NET_BRIDGE}')을 가진 디바이스가 이미 존재합니다." "$LINENO"
    exit 1
  fi

  echo "  🚀 [생성] Docker 네트워크 '${NET_NAME}' 생성 중..."
  "${DOCKER_CMD[@]}" network create \
    --driver bridge \
    --subnet "${NET_SUBNET}" \
    --gateway "${NET_GATEWAY}" \
    --opt "com.docker.network.bridge.name=${NET_BRIDGE}" \
    "${NET_NAME}"

  echo "  🔍 [검증] 커널 인터페이스 바인딩 확인 중..."
  local retry=0
  local max_retries=10
  while (( retry < max_retries )); do
    if ip link show dev "${NET_BRIDGE}" >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
    ((retry++)) || true
  done

  if ! ip link show dev "${NET_BRIDGE}" >/dev/null 2>&1; then
    help "Docker 브릿지 인터페이스('${NET_BRIDGE}')가 커널에 등록되지 않았습니다." "$LINENO"
    exit 1
  fi

  if ip link show dev "${NET_BRIDGE}" | grep -q "NO-CARRIER"; then
    echo "  ℹ️  [상태] 인터페이스 상태: NO-CARRIER (연결된 활성 컨테이너가 없으므로 라우트의 'linkdown' 표시는 정상입니다)"
  fi

  echo "  ✅ [완료] Docker 네트워크 '${NET_NAME}' (${NET_BRIDGE}) 가 정상 생성되었습니다."
}

##
# 지정된 Docker bridge network를 삭제하고 호스트 커널 리소스를 정리합니다.
#
# @param 없음
#
# @return Docker 네트워크 삭제 결과 화면 출력
##
delete_docker_network() {
  echo "🌐 [네트워크] Docker 네트워크 삭제 작업 시작: '${NET_NAME}'"

  if ! "${DOCKER_CMD[@]}" network inspect "${NET_NAME}" >/dev/null 2>&1; then
    help "삭제할 Docker 네트워크 '${NET_NAME}'가 존재하지 않습니다." "$LINENO"
    exit 1
  fi

  if [[ "$NET_NAME" =~ ^(bridge|host|none)$ ]]; then
    help "기본 Docker 네트워크('${NET_NAME}')는 시스템 보호를 위해 삭제할 수 없습니다." "$LINENO"
    exit 1
  fi

  local connected_containers
  connected_containers=$("${DOCKER_CMD[@]}" network inspect "${NET_NAME}" --format '{{range $k, $v := .Containers}}{{$v.Name}} {{end}}' 2>/dev/null || true)
  if [[ -n "${connected_containers// /}" ]]; then
    help "Docker 네트워크 '${NET_NAME}'에 활성/정지 상태의 컨테이너가 연결되어 있어 삭제할 수 없습니다. (연결된 컨테이너: ${connected_containers})" "$LINENO"
    exit 1
  fi

  local br_name
  br_name=$("${DOCKER_CMD[@]}" network inspect "${NET_NAME}" --format '{{index .Options "com.docker.network.bridge.name"}}' 2>/dev/null || true)

  echo "  🗑️  [삭제] Docker 네트워크 '${NET_NAME}' 삭제 중..."
  "${DOCKER_CMD[@]}" network rm "${NET_NAME}" >/dev/null

  if [[ -n "$br_name" ]]; then
    echo "  🔍 [검증] 커널 인터페이스('${br_name}') 해제 확인 중..."
    local retry=0
    local max_retries=10
    while (( retry < max_retries )); do
      if ! ip link show dev "${br_name}" >/dev/null 2>&1; then
        break
      fi
      sleep 0.5
      ((retry++)) || true
    done

    if ip link show dev "${br_name}" >/dev/null 2>&1; then
      echo "  ⚠️  [경고] Docker 네트워크는 삭제되었으나, 커널 인터페이스('${br_name}')가 호스트에 여전히 남아있습니다."
    fi
  fi

  echo "  ✅ [완료] Docker 네트워크 '${NET_NAME}' 가 정상적으로 삭제되었습니다."
}

##
# 메인 진입점 함수입니다.
#
# @param $@ {array} 스크립트 실행 인자 배열
#
# @return 프로세스 정상 종료 시 0 반환
##
main() {
  parse_arguments "$@"
  ensure_privileges_early
  case "$COMMAND_ACTION" in
    create)
      setup_docker_network
      ;;
    delete)
      delete_docker_network
      ;;
    inspect)
      inspect_docker_networks
      ;;
  esac
}

main "$@"

exit 0
