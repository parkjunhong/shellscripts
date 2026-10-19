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

NET_NAME=""
NET_BRIDGE=""
NET_GATEWAY=""
NET_SUBNET=""

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
  echo "  $FILENAME --help"
  echo
  echo "옵션 상세:"
  echo "  --name     <network-name>     생성할 Docker 네트워크 이름"
  echo "  --bridge   <bridge-name>      호스트 커널에 바인딩할 브릿지 인터페이스 이름 (최대 15자)"
  echo "  --gateway  <network-gateway>  네트워크 게이트웨이 IPv4 주소 (예: 172.31.255.1)"
  echo "  --subnet   <network-subnet>   CIDR 포맷의 서브넷 대역 (예: 172.31.255.0/24)"
  echo "  --help                        도움말 출력"
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
# CLI 파라미터를 파싱하고 입력값의 유효성을 검사합니다. 단축 옵션은 엄격히 차단됩니다.
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

  if (( $# < 2 )) || [[ "$1" != "network" ]] || [[ "$2" != "create" ]]; then
    help "지원하지 않는 명령 형식이거나 필수 서브커맨드('network create')가 올바르지 않습니다." "$LINENO"
    exit 1
  fi

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
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--bridge' 옵션에 유효한 브릿지 이름이 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_BRIDGE="$2"
        shift 2
        ;;
      --gateway)
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--gateway' 옵션에 유효한 게이트웨이 주소가 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_GATEWAY="$2"
        shift 2
        ;;
      --subnet)
        if (( $# < 2 )) || [[ "$2" =~ ^-- ]]; then
          help "'--subnet' 옵션에 유효한 CIDR 서브넷이 전달되지 않았습니다." "$LINENO"
          exit 1
        fi
        NET_SUBNET="$2"
        shift 2
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
# Docker bridge network를 생성하고 호스트 커널 인터페이스 바인딩을 확인합니다.
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

  echo "  ✅ [완료] Docker 네트워크 '${NET_NAME}' (${NET_BRIDGE}) 가 정상 생성되었습니다."
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
  setup_docker_network
}

main "$@"

exit 0
