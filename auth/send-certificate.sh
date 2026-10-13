#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : wildcard 인증서 변환 및 다중 서비스 배포 스크립트
# @license : Apache License 2.0
# @since : 2026-10-13
# @desc : support RHEL 7 or higher, Oracle Linux 7 or higher, Ubuntu 18.04 or higher, RockyOS 8 or higher, CentOS 7 or higher, macOS 11 or higher
# @installation : 
# 1. insert 'source <path>/send-certificate.sh.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/send-certificate.sh' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
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
  echo "[옵션 (Options)]"
  echo "  --no-send                            실제로 파일을 원격 서버에 전송하지 않습니다."
  echo "  --no-delete                          변환된 인증서 파일들을 삭제하지 않고 보존합니다."
  echo "  --dry-run                            --no-send 및 --no-delete를 동시에 활성화합니다."
  echo "  -sf, --service-files <파일경로>       서비스 목록 파일 경로를 지정합니다. (필수)"
  echo "                                       형식: <type>;<user>@<host>:/absolute/path[;<cli>]"
  echo "  -sk, --ssh-key <파일경로>             SSH 접속에 사용할 개인키 파일 경로를 지정합니다. (필수)"
  echo "  -p12, --p12-pwd <비밀번호>            PKCS12 및 JKS 생성에 사용할 비밀번호를 지정합니다. (필수)"
  echo "  -tc, --target-ca <유형목록>           전송할 인증서 유형을 쉼표로 구분하여 지정합니다. (기본값: 전체)"
  echo "                                       허용 값: pem,sslca,pkcs12,jks"
  echo "  -wd, --wildcard-domain <도메인>       Wildcard 기준 도메인을 지정합니다. (예: ymtech.co.kr, 필수)"
  echo "  -h, --help                           이 도움말을 출력하고 종료합니다."
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR

# 전역 설정 플래그 및 기본 변수 선언
NO_SEND=0
NO_DELETE=0
TYPE=("pem" "sslca" "pkcs12" "jks")
WILDCARD_DOMAIN=""
TARGET_CA_LIST=()
SERVICES_LIST=""
SSH_PRI_KEY=""
P12_PWD=""
DEST_CONFS=()
LETSENC_ROOT=""

##
# Let's Encrypt 도구 설치 경로 환경변수(LETSENC_INSTDIR)를 검증하고 설정합니다.
#
# @param 없음
#
# @return (검증 성공 시 LETSENC_ROOT 설정, 실패 시 exit 1)
##
validate_env() {
  LETSENC_ROOT="${LETSENC_INSTDIR:-}"

  if [[ -z "${LETSENC_ROOT}" || ! -d "${LETSENC_ROOT}" ]]; then
    echo "❌ Let's Encrypt 도구가 설치된 디렉터리 경로를 찾을 수 없습니다." >&2
    echo "   echo \"\$LETSENC_INSTDIR\"=${LETSENC_ROOT}" >&2
    help "유효하지 않은 LETSENC_INSTDIR 환경변수입니다." "$LINENO"
    exit 1
  fi
}

##
# 경로 문자열을 정규화하여 절대 경로로 변환합니다.
#
# @param $1 {string} 변환할 경로
#
# @return {string} 정규화된 절대 경로 (stdout)
##
normalize_path(){
  local p="$1"

  if [ -z "$p" ]; then
    echo ""
    return 0
  fi

  if [[ "$p" == ~* ]]; then
    eval echo "$p"
    return 0
  fi

  if [[ "$p" = /* ]]; then
    echo "$p"
    return 0
  fi

  echo "$PWD/$p"
}

##
# 원격 대상 문자열(user@host:path 또는 user@host)에서 순수 호스트명/IP를 안전하게 추출합니다.
#
# @param $1 {string} 대상 원격 접속 문자열
#
# @return {string} 추출된 순수 호스트명 (stdout)
##
extract_pure_host() {
  local raw_target="$1"
  local host_part="${raw_target%%:*}"
  host_part="${host_part#*@}"
  echo "$host_part"
}

##
# 원격 서버 접속 실패 시 SSH Host Key 변경 오류 여부를 감지하고 known_hosts 캐시를 자동 삭제합니다.
#
# @param $1 {string} 대상 호스트명
# @param $2 {string} 실행 로그 파일 경로
#
# @return 0 (호스트키 삭제 성공 및 재시도 필요), 1 (호스트키 오류 아님)
##
handle_host_key_changed() {
  local host="$1"
  local log_file="$2"

  if grep -Eq 'WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED|Host key verification failed' "$log_file" 2>/dev/null; then
    echo ""
    echo "================================================================================"
    echo "⚠️  [주의] 원격 서버($host)의 SSH 호스트 키 변경(Host Key Changed)이 감지되었습니다."
    echo "   기존 /root/.ssh/known_hosts (또는 ~/.ssh/known_hosts)의 불일치 키를 자동 삭제합니다."
    echo "   실행 명령 -> ssh-keygen -R '$host'"
    echo "================================================================================"
    
    ssh-keygen -R "$host" >/dev/null 2>&1 || true

    # 해시 처리된 known_hosts 백업 파일(.old)도 정리
    local known_hosts_file="${HOME}/.ssh/known_hosts"
    if [ -f "${known_hosts_file}.old" ]; then
      rm -f "${known_hosts_file}.old" 2>/dev/null || true
    fi

    return 0
  fi

  return 1
}

##
# 파일 유효성을 검증합니다.
#
# @param $1 {string} 검증할 파일 경로
#
# @return 0 (성공), 실패 시 exit 1
##
validate_file(){
  local f="$1"
  if [ ! -f "$f" ]; then
    help "인증서 파일이 존재하지 않습니다 -> '$f'" "$LINENO"
    exit 1
  else
    echo " * * * 검증 완료된 파일: $f"
  fi
}

##
# PEM 인증서를 Nginx용 CRT 및 KEY 형식으로 변환합니다.
#
# @param 없음
#
# @return 변환 디렉터리 생성 및 파일 복사 완료
##
convert_pem_to_sslca(){
  echo ""
  echo " ✅  >>> 시작: Nginx용 SSL & CA 파일 변환"

  rm -rf "$SSL_CA_DIR"
  mkdir -p "$SSL_CA_DIR"

  cp -f "$FILE_FULLCHAIN" "$SSL_CA_DIR/${CERT_NAME}.crt"

  printf " * * * "
  openssl pkey -in "$FILE_PRIVKEY" -out "$SSL_CA_DIR/${CERT_NAME}.key"

  echo ""
  ls -al "$SSL_CA_DIR/"
  echo " <<< 종료"
}

##
# PEM 인증서를 PKCS12 (.p12) 형식으로 변환합니다.
#
# @param 없음
#
# @return .p12 파일 생성 완료
##
convert_pem_to_p12(){
  echo ""
  echo " ✅  >>> 시작: PKCS12(.p12) 파일 변환"

  rm -rf "$PKCS12_DIR"
  mkdir -p "$PKCS12_DIR"

  openssl pkcs12 -export \
    -out "${PKCS12_DIR}/${CERT_NAME}.p12" \
    -passout pass:"$P12_PWD" \
    -in "$FILE_FULLCHAIN" \
    -inkey "$FILE_PRIVKEY" \
    -CAfile "$FILE_CHAIN" \
    -caname "$INTER_CERTS_ALIAS_OR_CNAME" \
    -name "$NAME_OR_ALIAS"

  ls -al "${PKCS12_DIR}/${CERT_NAME}.p12"
  echo " <<< 종료"
}

##
# PKCS12 파일을 Java KeyStore (.jks) 형식으로 변환합니다.
#
# @param 없음
#
# @return .jks 파일 생성 완료
##
convert_p12_to_jks(){
  echo ""
  echo " ✅  >>> 시작: Java KeyStore(.jks) 파일 변환"

  if [ ! -f "${PKCS12_DIR}/${CERT_NAME}.p12" ]; then
    echo " ❌❌❌ PKCS12 파일이 존재하지 않습니다. 경로=${PKCS12_DIR}/${CERT_NAME}.p12" >&2
    return 1
  fi

  rm -rf "$JKS_DIR"
  mkdir -p "$JKS_DIR"

  echo " + ✅  'p12' -> 'jks'"
  keytool -importkeystore \
    -deststorepass "$P12_PWD" \
    -destkeypass "$P12_PWD" \
    -destkeystore "${JKS_DIR}/${CERT_NAME}.jks" \
    -srckeystore "${PKCS12_DIR}/${CERT_NAME}.p12" \
    -srcstoretype PKCS12 \
    -srcstorepass "$P12_PWD" \
    -alias "$NAME_OR_ALIAS"

  echo " + ✅  중계(Intermediate) CA 주입"
  keytool -import -trustcacerts \
    -file "$FILE_CHAIN" \
    -keystore "${JKS_DIR}/${CERT_NAME}.jks" \
    -storepass "$P12_PWD" \
    -alias "$INTER_CERTS_ALIAS_OR_CNAME" \
    -noprompt

  echo " + ✅  루트(ROOT) CA 주입"
  keytool -import -trustcacerts \
    -file "$FILE_ROOT" \
    -keystore "${JKS_DIR}/${CERT_NAME}.jks" \
    -storepass "$P12_PWD" \
    -alias "$ROOT_CERTS_ALIAS" \
    -noprompt

  ls -al "${JKS_DIR}/${CERT_NAME}.jks"
  echo " <<< 종료"
}

##
# SCP를 통해 변환된 인증서 파일들을 대상 서버로 전송합니다 (Host Key 변경 시 자동 복구 및 재시도).
#
# @param $1 {string} 소스 디렉터리 경로
# @param $2 {string} 대상 서버 접속 및 목적지 경로 (<user>@<host>:<path>)
#
# @return {number} SCP 실행 종료 코드 (0: 성공)
##
send_files(){
  if [ $# -ne 2 ]; then
    echo " ❌❌❌ 인자가 올바르지 않습니다." >&2
    return 1
  fi

  local src_dir="$1"
  local dst_target="$2"
  local host_only=""
  host_only="$(extract_pure_host "$dst_target")"

  echo "scp -i $SSH_PRI_KEY $src_dir/*.* $dst_target"

  if [ "$NO_SEND" -eq 1 ]; then
    echo " ❗❗❗ '--no-send' 옵션이 활성화되어 실제 전송을 건너뜁니다."
    return 0
  fi

  local temp_log=""
  temp_log="$(mktemp "${TMPDIR:-/tmp}/scp_err_XXXXXX.log")"
  local status=0

  # 1차 전송 시도
  set +e
  scp -i "$SSH_PRI_KEY" "$src_dir"/*.* "$dst_target" 2>&1 | tee "$temp_log"
  status=${PIPESTATUS[0]}
  set -e

  # 호스트 키 변경 오류 발생 시 자동 복구 및 2차 재시도
  if [ "$status" -ne 0 ] && handle_host_key_changed "$host_only" "$temp_log"; then
    echo " 🔄 [재시도] 갱신된 호스트 키를 적용하여 SCP 재전송을 진행합니다..."
    set +e
    scp -i "$SSH_PRI_KEY" \
        -o StrictHostKeyChecking=accept-new \
        "$src_dir"/*.* "$dst_target" 2>&1 | tee "$temp_log"
    status=${PIPESTATUS[0]}
    set -e

    if [ "$status" -eq 0 ]; then
      echo " ✅ [성공] 호스트 키 갱신 후 SCP 재전송이 정상 완료되었습니다."
    fi
  fi

  rm -f "$temp_log"
  return "$status"
}

##
# SSH를 통해 원격 서버에 사후 명령어를 실행합니다 (Host Key 변경 시 자동 복구 및 재시도).
#
# @param $1 {string} 대상 서버 접속 문자열 (<user>@<host>)
# @param $2 {string} 원격 실행할 CLI 명령어
# @param $3 {number} 이전 파일 전송 단계 상태 코드
#
# @return {number} SSH 실행 종료 코드 (0: 성공)
##
exe_cli(){
  local server="$1"
  local cli="$2"
  local prev_status="${3:-0}"

  if [ -z "$cli" ]; then
    return 0
  fi

  if [ "$prev_status" -ne 0 ]; then
    echo " ❗❗❗ 이전 단계가 실패(status=$prev_status)이므로 CLI 실행을 건너뜁니다. server=$server, cli=$cli"
    return "$prev_status"
  fi

  local host_only=""
  host_only="$(extract_pure_host "$server")"

  echo "ssh -i $SSH_PRI_KEY $server \"$cli\""

  if [ "$NO_SEND" -eq 1 ]; then
    echo " ❗❗❗ '--no-send' 옵션이 활성화되어 CLI 실행을 건너뜁니다."
    return 0
  fi

  local temp_log=""
  temp_log="$(mktemp "${TMPDIR:-/tmp}/ssh_err_XXXXXX.log")"
  local status=0

  # 1차 SSH 실행 시도
  set +e
  ssh -i "$SSH_PRI_KEY" "$server" "$cli" 2>&1 | tee "$temp_log"
  status=${PIPESTATUS[0]}
  set -e

  # 호스트 키 변경 오류 발생 시 자동 복구 및 2차 재시도
  if [ "$status" -ne 0 ] && handle_host_key_changed "$host_only" "$temp_log"; then
    echo " 🔄 [재시도] 갱신된 호스트 키를 적용하여 SSH CLI 명령을 재실행합니다..."
    set +e
    ssh -i "$SSH_PRI_KEY" \
        -o StrictHostKeyChecking=accept-new \
        "$server" "$cli" 2>&1 | tee "$temp_log"
    status=${PIPESTATUS[0]}
    set -e

    if [ "$status" -eq 0 ]; then
      echo " ✅ [성공] 호스트 키 갱신 후 SSH 명령 재실행이 정상 완료되었습니다."
    fi
  fi

  rm -f "$temp_log"
  return "$status"
}

##
# 지정한 디렉터리를 재귀적으로 삭제합니다.
#
# @param $1 {string} 삭제할 디렉터리 경로
#
# @return 디렉터리 삭제 완료
##
delete_dir(){
  local d="$1"
  echo "rm -rfv $d"
  if [ "$NO_DELETE" -eq 1 ]; then
    echo " ❗❗❗ '--no-delete' 옵션이 활성화되어 디렉터리 삭제를 건너뜁니다."
  else
    rm -rf "$d"
  fi
}

##
# 생성되었던 임시 변환 파일 디렉터리들을 일괄 정리합니다.
#
# @param 없음
#
# @return 정리 완료
##
delete_converted_files(){
  echo ""
  delete_dir "$SSL_CA_DIR"
  delete_dir "$PKCS12_DIR"
  delete_dir "$JKS_DIR"
}

# ----------------------------------------------------------------------
# 명령줄 옵션 파싱
# ----------------------------------------------------------------------
while [ ! -z "${1:-}" ]; do
  case "$1" in
    --no-send)
      NO_SEND=1
      ;;
    --no-delete)
      NO_DELETE=1
      ;;
    --dry-run)
      NO_SEND=1
      NO_DELETE=1
      ;;
    --service-files|-sf)
      shift
      if [ -z "${1:-}" ]; then
        help "'--service-files|-sf' 옵션에 대한 파일 경로가 전달되지 않았습니다." "$LINENO"
        exit 1
      fi
      SERVICES_LIST="$(normalize_path "$1")"
      ;;
    --ssh-key|-sk)
      shift
      if [ -z "${1:-}" ]; then
        help "'--ssh-key|-sk' 옵션에 SSH 개인키 경로가 전달되지 않았습니다." "$LINENO"
        exit 1
      fi
      SSH_PRI_KEY="$(normalize_path "$1")"
      ;;
    --p12-pwd|-p12)
      shift
      if [ -z "${1:-}" ]; then
        help "'--p12-pwd|-p12' 옵션에 비밀번호가 전달되지 않았습니다." "$LINENO"
        exit 1
      fi
      P12_PWD="$1"
      ;;
    --target-ca|-tc)
      shift
      if [ -z "${1:-}" ]; then
        help "'--target-ca|-tc' 옵션에 대한 값이 전달되지 않았습니다." "$LINENO"
        exit 1
      fi
      IFS=',' read -r -a TARGET_CA_LIST <<< "$1"
      ;;
    --wildcard-domain|-wd)
      shift
      if [ -z "${1:-}" ]; then
        help "'--wildcard-domain|-wd' 옵션에 도메인 값이 전달되지 않았습니다." "$LINENO"
        exit 1
      fi
      WILDCARD_DOMAIN="$1"
      ;;
    -h|--help)
      help "" ""
      exit 0
      ;;
    *)
      help "지원하지 않는 옵션입니다 -> '$1'" "$LINENO"
      exit 1
      ;;
  esac
  shift
done

# ----------------------------------------------------------------------
# 입력값 유효성 검증
# ----------------------------------------------------------------------
if [ -z "$WILDCARD_DOMAIN" ]; then
  help "Wildcard 도메인이 지정되지 않았습니다 (--wildcard-domain|-wd 옵션 필수)." "$LINENO"
  exit 1
fi

if ! echo "$WILDCARD_DOMAIN" | grep -Eq '^[A-Za-z0-9.-]+\.[A-Za-z0-9.-]+$'; then
  help "올바르지 않은 형식의 Wildcard 도메인입니다 -> '$WILDCARD_DOMAIN'" "$LINENO"
  exit 1
fi

if [ ${#TARGET_CA_LIST[@]} -eq 0 ]; then
  TARGET_CA_LIST=("${TYPE[@]}")
fi

for tgt in "${TARGET_CA_LIST[@]}"; do
  valid=0
  for t in "${TYPE[@]}"; do
    if [ "$t" = "$tgt" ]; then
      valid=1
      break
    fi
  done
  if [ $valid -eq 0 ]; then
    help "지원하지 않는 인증서 유형입니다 -> '$tgt' (허용 값: ${TYPE[*]})" "$LINENO"
    exit 1
  fi
done

if [ -z "$P12_PWD" ]; then
  help "PKCS12(JKS) 비밀번호가 지정되지 않았습니다 (--p12-pwd|-p12 옵션 필수)." "$LINENO"
  exit 1
fi

if echo "$P12_PWD" | grep -q "[[:space:]]"; then
  help "PKCS12(JKS) 비밀번호에는 공백 문자를 포함할 수 없습니다." "$LINENO"
  exit 1
fi

if [ ${#P12_PWD} -lt 4 ]; then
  help "PKCS12(JKS) 비밀번호는 최소 4자 이상이어야 합니다." "$LINENO"
  exit 1
fi

if [ -z "$SSH_PRI_KEY" ]; then
  help "SSH 개인키 파일 경로가 지정되지 않았습니다 (--ssh-key|-sk 옵션 필수)." "$LINENO"
  exit 1
fi

if [ ! -f "$SSH_PRI_KEY" ] || [ ! -r "$SSH_PRI_KEY" ]; then
  help "SSH 개인키 파일에 접근할 수 없습니다 -> '$SSH_PRI_KEY'" "$LINENO"
  exit 1
fi

if [ -z "$SERVICES_LIST" ]; then
  help "서비스 목록 파일이 지정되지 않았습니다 (--service-files|-sf 옵션 필수)." "$LINENO"
  exit 1
fi

if [ ! -f "$SERVICES_LIST" ] || [ ! -r "$SERVICES_LIST" ]; then
  help "서비스 목록 파일에 접근할 수 없습니다 -> '$SERVICES_LIST'" "$LINENO"
  exit 1
fi

# 서비스 목록 파일 라인별 검증 및 메모리 로드
while IFS= read -r line || [ -n "$line" ]; do
  line="$(echo "$line" | tr -d '\r' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  
  if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
    continue
  fi

  if ! echo "$line" | grep -Eq '^(pem|sslca|pkcs12|jks);[A-Za-z0-9._-]+@[A-Za-z0-9._-]+:/[^;]+(;.*)?$'; then
    help "service-list.txt 설정 라인 포맷 오류 -> '$line'" "$LINENO"
    exit 1
  fi

  DEST_CONFS+=("$line")
done < "$SERVICES_LIST"

# 환경변수 검증 및 작업 디렉터리 이동
validate_env
pushd . >/dev/null
cd "${LETSENC_ROOT}"

CERT_DIR="./archive/${WILDCARD_DOMAIN}"
SSL_CA_DIR="./archive/${WILDCARD_DOMAIN}/ssl_ca"
PKCS12_DIR="./archive/${WILDCARD_DOMAIN}/pkcs12"
JKS_DIR="./archive/${WILDCARD_DOMAIN}/jks"

CERT_NAME="R3-wildcard.${WILDCARD_DOMAIN}"
NAME_OR_ALIAS="$(echo "$WILDCARD_DOMAIN" | awk -F'.' '{print $1}')"

INTER_CERTS_ALIAS_OR_CNAME="intermediate"
ROOT_CERTS_ALIAS="isrg-root-x1"

# 인증서 원본 파일 무결성 검증
if [ ! -d "$CERT_DIR" ]; then
  help "인증서 원본 디렉터리가 존재하지 않습니다 -> '$CERT_DIR'" "$LINENO"
  exit 1
fi

echo ""
validate_file "$CERT_DIR/cert1.pem"
validate_file "$CERT_DIR/chain1.pem"
validate_file "$CERT_DIR/fullchain1.pem"
validate_file "$CERT_DIR/privkey1.pem"

delete_converted_files

FILE_CERT="$CERT_DIR/cert1.pem"
FILE_CHAIN="$CERT_DIR/chain1.pem"
FILE_FULLCHAIN="$CERT_DIR/fullchain1.pem"
FILE_PRIVKEY="$CERT_DIR/privkey1.pem"
FILE_ROOT="$CERT_DIR/${ROOT_CERTS_ALIAS}.pem"

echo ""
echo " ✅  >>> ISRG ROOT CA 인증서 다운로드 중..."
wget -q https://letsencrypt.org/certs/isrgrootx1.pem -O "$FILE_ROOT"

convert_pem_to_sslca
convert_pem_to_p12
convert_p12_to_jks

echo ""
echo " ✅  >>> 인증서 다중 원격 배포 시작"

declare -A SEND_MAP=()

for dst_conf in "${DEST_CONFS[@]}"; do
  IFS=';' read -r type dst cli <<< "$dst_conf"

  map_key="${type}__cached"
  send_this=0

  if [[ -n "${SEND_MAP[$map_key]:-}" ]]; then
    send_this=${SEND_MAP[$map_key]}
  else
    for tgt in "${TARGET_CA_LIST[@]}"; do
      if [ "$tgt" = "$type" ]; then
        send_this=1
        break
      fi
    done
    SEND_MAP[$map_key]=$send_this
  fi

  if [ "$send_this" -eq 0 ]; then
    echo " - 건너뜀 (전송 대상 CA 유형 아님): $dst_conf"
    echo "---"
    continue
  fi

  server="${dst%%:*}"
  status=0

  case "$type" in
    pem)
      send_files "$CERT_DIR" "$dst"
      status=$?
      ;;
    sslca)
      send_files "$SSL_CA_DIR" "$dst"
      status=$?
      ;;
    pkcs12)
      send_files "$PKCS12_DIR" "$dst"
      status=$?
      ;;
    jks)
      send_files "$JKS_DIR" "$dst"
      status=$?
      ;;
    *)
      echo " ❌❌❌ 올바르지 않은 인증서 유형입니다 -> ${dst_conf}" >&2
      status=1
      ;;
  esac

  if [ -n "$cli" ]; then
    exe_cli "$server" "$cli" "$status"
  fi

  echo "---"
done

echo " <<< 모든 인증서 배포 작업 완료"

echo ""
echo " 임시 ISRG ROOT CA 파일 정리"
rm -f "$FILE_ROOT"

popd >/dev/null

exit 0
