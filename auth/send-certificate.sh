#!/usr/bin/env bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : wildcard 인증서 변환 및 다중 서비스 배포 스크립트
# @license: Apache License 2.0
# @since  : 2025/11/27
# @desc   : support RHEL 7/8/9, Oracle Linux 7/8/9, Ubuntu 18.04/20.04/22.04 LTS,
#           macOS 11+ (with bash >= 4, OpenSSL, wget, OpenSSH, JDK/keytool installed),
#           CentOS 7
# @completion: send-certificate.completion
#            1. insert "source <path>/send-certificate.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#            2. copy the above file to /etc/bash_completion.d/ for all users.
# =======================================

# LETSENC_INSTDIR: Let's Encrypt가 설치된 디렉토리로
# 환경변수로 설정해서 처리
if [[ -z $(echo $LETSENC_INSTDIR) ]]; 
then
  echo
  echo "Let's Encrypt 도구가 설치된 경로가 존재하지 않습니다."
  echo "echo \$LETSENC_INSTDIR=$(echo $LETSENC_INSTDIR)"
  exit 1
fi

if [[ ! -d $(echo $LETSENC_INSTDIR) ]]; 
then
  echo
  echo "Let's Encrypt 도구가 설치된 경로가 존재하지 않습니다."
  echo "echo \$LETSENC_INSTDIR=$(echo $LETSENC_INSTDIR)"
  exit 1
fi

# 안 보내기 
NO_SEND=0
# 유형별 인증서 삭제하지 않기
NO_DELETE=0
# 인증서 유형
TYPE=( "pem" "sslca" "pkcs12" "jks")
# WILDCARD 도메인 (예: mycom.co.kr)
WILDCARD_DOMAIN=""
# 전송할 인증서 유형 리스트 (미지정 시 TYPE 전체 사용)
TARGET_CA_LIST=()
# 서비스 목록 파일 경로
SERVICES_LIST=""
# SSH 개인키 경로 (옵션으로 입력)
SSH_PRI_KEY=""
# PKCS12/JKS 비밀번호 (옵션으로 입력)
P12_PWD=""
# 전송 대상 설정 (service-list.txt 내용)
DEST_CONFS=()

# ----------------------------------------------------------------------
# path normalization helpers
#   - ~ 확장
#   - 상대경로 → 절대경로 변환
# ----------------------------------------------------------------------
normalize_path(){
  local p="$1"

  # 빈 값이면 그대로 반환
  if [ -z "$p" ]; then
    echo ""
    return 0
  fi

  # ~, ~/ 로 시작하는 경우 쉘 확장을 이용
  if [[ "$p" == ~* ]]; then
    eval echo "$p"
    return 0
  fi

  # 절대경로 그대로 사용
  if [[ "$p" = /* ]]; then
    echo "$p"
    return 0
  fi

  # 상대경로는 현재 작업 디렉터리 기준으로 절대경로 변환
  echo "$PWD/$p"
}

FILENAME="$0"

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
  echo
  echo "Usage:"
  echo "./script_name <options>" # 스크립트 이름을 적절하게 수정하세요.
  echo
  echo "Options:"
  echo " --no-send: DO NOT send file to destination."
  echo " --no-delete: DO NOT delete converted files, e.g. ssl, pkcs12, etc."
  echo " -sf | --service-files <file>: Specify service list file."
  echo "  데이터 포맷: <type>;<user>@<host>:/absolute/path[;<cli>]"
  echo "   + type: pem|sslca|pkcs12|jks"
  echo "   + user: 사용자 ID"
  echo "   + host: 서버 접속 정보. IP or Domain"
  echo "   + path: 인증서를 복사할 디렉토리 절대 경로"
  echo "   + cli : 인증서를 복사한 후 실행할 명령어. (optional)"
  echo " -sk | --ssh-key <file>: Specify ssh private key file."
  echo " -tc | --target-ca <types>: Specify target certificate types. (comma separated: pem,sslca,pkcs12,jks)"
  echo " -wd | --wildcard-domain <domain>: Specify wildcard base domain. (e.g. mycom.co.kr)"
  echo " -p12 | --p12-pwd <password>: Specify password for pkcs12/jks."
  echo
}

# ----------------------------------------------------------------------
# 옵션 파싱
# ----------------------------------------------------------------------
while [ ! -z "$1" ];
do
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
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--service-files|-sf' 옵션에 대한 파일 경로가 없습니다."
        echo "     사용 예) $0 --service-files service-list.txt"
        echo
        help "비어 있는 서비스 파일 경로" $FILENO
        exit 1
      fi
      SERVICES_LIST="$(normalize_path "$1")"
      ;;
    --ssh-key|-sk)
      shift
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--ssh-key|-sk' 옵션에 SSH 개인키 파일 경로가 제공되지 않았습니다."
        echo "     사용 예) $0 --ssh-key ~/.ssh/id_rsa.pem"
        echo
        help "비어 있는 SSH 개인키 파일 경로" $FILENO
        exit 1
      fi
      SSH_PRI_KEY="$(normalize_path "$1")"
      ;;
    --p12-pwd|-p12)
      shift
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--p12-pwd|-p12' 옵션에 PKCS12(JKS) 비밀번호가 제공되지 않았습니다."
        echo "     사용 예) $0 --p12-pwd mySecretPwd123"
        echo
        help "비어있는 PKCS12(JKS) 비밀번호" $FILENO
        exit 1
      fi
      P12_PWD="$1"
      ;;
    --target-ca|-tc)
      # 입력받은 문자열은 comma(,)로 분리하여 배열로 설정
      shift
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--target-ca|-tc' 옵션에 대한 값이 없습니다."
        echo "     사용 예) $0 --target-ca pem,sslca,pkcs12,jks"
        echo
        help "비어 있는 인증서 유형" $FILENO
        exit 1
      fi
      IFS=',' read -r -a TARGET_CA_LIST <<< "$1"
      ;;
    --wildcard-domain|-wd)
      # 예: mycom.co.kr
      shift
      if [ -z "$1" ]; then
        echo
        echo " ❌❌❌ '--wildcard-domain|-wd' 옵션에 대한 값이 없습니다."
        echo "     사용 예) $0 --wildcard-domain mycom.co.kr"
        echo
        help "비어있는 않은 wildcard 도메인" $FILENO
        exit 1
      fi
      WILDCARD_DOMAIN="$1"
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      ;;
  esac
  shift
done

# ----------------------------------------------------------------------
# '$WILDCARD_DOMAIN' 값 검증
# ----------------------------------------------------------------------
if [ -z "$WILDCARD_DOMAIN" ]; then
  echo
  echo " ❌❌❌ WILDCARD 도메인이 지정되지 않았습니다."
  echo "     '--wildcard-domain <domain>' 또는 '-wd <domain>' 옵션을 사용하세요."
  echo
  help "비어 있는 wildcard 도메인" $FILENO
  exit 1
fi

if ! echo "$WILDCARD_DOMAIN" | grep -Eq '^[A-Za-z0-9.-]+\.[A-Za-z0-9.-]+$'; then
  echo
  echo " ❌❌❌ 올바르지 않은 도메인 형식입니다. value=${WILDCARD_DOMAIN}"
  echo "     예) mycom.co.kr"
  echo
  help "올바리지 않은 형식의 wildcard 도메인" $FILENO
  exit 1
fi

# ----------------------------------------------------------------------
# '$TARGET_CA_LIST' 값 검증
# ----------------------------------------------------------------------
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
    echo
    echo " ❌❌❌ 지원하지 않는 인증서 유형이 '--target-ca|-tc' 옵션에 지정되었습니다: $tgt"
    echo "     허용 값: ${TYPE[*]}"
    echo
    help "올바르지 않은 CA 유형" $FILENO
    exit 1
  fi
done

# ----------------------------------------------------------------------
# P12_PWD 검증
# ----------------------------------------------------------------------
if [ -z "$P12_PWD" ]; then
  echo
  echo " ❌❌❌ PKCS12(JKS) 비밀번호가 지정되지 않았습니다."
  echo "     '--p12-pwd <password>' 또는 '-p12 <password>' 옵션을 사용하세요."
  echo
  help "비어 있는 PKCS12(JKS) 비밀번호" $FILENO
  exit 1
fi

# 공백 문자 포함 여부(줄바꿈/탭/스페이스 등) 검사
if echo "$P12_PWD" | grep -q "[[:space:]]"; then
  echo
  echo " ❌❌❌ PKCS12(JKS) 비밀번호에는 공백 문자를 사용할 수 없습니다."
  echo "     공백 없이 다시 지정해 주세요."
  echo
  help "올바르지 않은 PKCS12(JKS) 비밀번호" $FILENO
  exit 1
fi

# 최소 길이 제한 (예: 4자 이상)
if [ ${#P12_PWD} -lt 4 ]; then
  echo
  echo " ❌❌❌ PKCS12(JKS) 비밀번호는 최소 4자 이상이어야 합니다."
  echo
  help "올바르지 않은 PKCS12(JKS) 비밀번호" $FILENO
  exit 1
fi

# ----------------------------------------------------------------------
# SSH PRI KEY 검증
# ----------------------------------------------------------------------
if [ -z "$SSH_PRI_KEY" ]; then
  echo
  echo " ❌❌❌ SSH 개인키 파일이 지정되지 않았습니다."
  echo "     '--ssh-key <file>' 또는 '-sk <file>' 옵션을 사용하세요."
  echo
  help "비어있는 PKCS12(JKS) 비밀번호" $FILENO
  exit 1
fi

if [ ! -f "$SSH_PRI_KEY" ] || [ ! -r "$SSH_PRI_KEY" ]; then
  echo
  echo " ❌❌❌ SSH 개인키 파일에 접근할 수 없습니다. path=${SSH_PRI_KEY}"
  echo "     파일이 존재하는지, 읽기 권한이 있는지 확인하세요."
  echo
  help "올바르지 않은 SSH 개인키 파일" $FILENO
  exit 1
fi

# ----------------------------------------------------------------------
# 서비스 목록 파일 로딩
# ----------------------------------------------------------------------
if [ -z "$SERVICES_LIST" ]; then
  echo
  echo " ❌❌❌ 서비스 목록 파일이 지정되지 않았습니다."
  echo "     '--service-files <file>' 또는 '-sf <file>' 옵션을 사용하세요."
  echo
  help "비어 있는 서비스 목록 파일" $FILENO
  exit 1
fi

if [ ! -f "$SERVICES_LIST" ] || [ ! -r "$SERVICES_LIST" ]; then
  echo
  echo " ❌❌❌ 서비스 목록 파일에 접근할 수 없습니다. path=${SERVICES_LIST}"
  echo "     파일이 존재하는지, 읽기 권한이 있는지 확인하세요."
  echo
  help "올바르지 않은 서비스 목록 파일" $FILENO
  exit 1
fi

while IFS= read -r line; do
  # 공백/주석/빈줄 무시
  if [ -z "$line" ]; then
    continue
  fi
  case "$line" in
    \#*) continue ;;
  esac

  # service-list.txt 형식 검증
  # 기대 형식: <type>;<user>@<host>:/absolute/path[;<cli>]
  #   - type : pem | sslca | pkcs12 | jks
  #   - user : [A-Za-z0-9._-]+
  #   - host : [A-Za-z0-9._-]+
  #   - path : '/' 로 시작, 세미콜론(;) 포함 불가
  #   - cli  : 선택 값, 세미콜론으로 구분된 나머지 전체 문자열
  if ! echo "$line" | grep -Eq '^(pem|sslca|pkcs12|jks);[A-Za-z0-9._-]+@[A-Za-z0-9._-]+:/[^;]+(;.*)?$'; then
    echo
    echo " ❌❌❌ service-list.txt 형식 오류: '$line'"
    echo "     기대 형식: <type>;<user>@<host>:/absolute/path[;<cli>]"
    echo "     예시     : pem;admin@gitlab.mycom.co.kr:/etc/gitlab/ssl/;sudo systemctl reload nginx"
    echo
    help "올바르지 않은 서비스 설정: $line" $FILENO
    exit 1
  fi

  DEST_CONFS+=("$line")
done < "$SERVICES_LIST"

# 현재 경로 지정
pushd .
# Let's Encrypt 설치된 디렉토리로 이동
cd $(echo $LETSENC_INSTDIR)

# ----------------------------------------------------------------------
# 전송을 위한 디렉터리 설정
# ----------------------------------------------------------------------
CERT_DIR="./archive/${WILDCARD_DOMAIN}"
SSL_CA_DIR="./archive/${WILDCARD_DOMAIN}/ssl_ca"
PKCS12_DIR="./archive/${WILDCARD_DOMAIN}/pkcs12"
JKS_DIR="./archive/${WILDCARD_DOMAIN}/jks"

CERT_NAME="R3-wildcard.${WILDCARD_DOMAIN}"
# ${WILDCARD_DOMAIN}을 dot(.)으로 분리했을 때 첫번째 토큰을 alias 로 사용
# 예) mycom.co.kr -> ymtech
NAME_OR_ALIAS="$(echo "$WILDCARD_DOMAIN" | awk -F'.' '{print $1}')"

INTER_CERTS_ALIAS_OR_CNAME="intermediate"
ROOT_CERTS_ALIAS="isrg-root-x1"

validate-file(){
  if [ ! -f "$1" ];then
    echo " ❌❌❌ Invalid certificated file: $1" $LINENO
    exit 1
  else
    echo " * * * Validated file: $1"
  fi
}

## pem to '.crt' & '.key'
convert-pem-to-sslca(){
  echo
  echo " ✅  > > > begin: convert to nginx ssl & ca  "

  rm -rfv "$SSL_CA_DIR"
  mkdir -p "$SSL_CA_DIR"

  cp -f "$FILE_FULLCHAIN" "$SSL_CA_DIR/${CERT_NAME}.crt"

  printf " * * * "
  openssl pkey -in "$FILE_PRIVKEY" -out "$SSL_CA_DIR/${CERT_NAME}.key"

  echo
  ls -al "$SSL_CA_DIR/"

  echo " < < < end:"
}

## pem to '.p12'
convert-pem-to-p12(){
  echo
  echo " ✅> > > > begin: convert to pkcs12"

  rm -rfv "$PKCS12_DIR"
  mkdir -p "$PKCS12_DIR"

  openssl pkcs12 -export \
    -out "${PKCS12_DIR}/${CERT_NAME}.p12" \
    -passout pass:$P12_PWD \
    -in "$FILE_FULLCHAIN" \
    -inkey "$FILE_PRIVKEY" \
    -CAfile "$FILE_CHAIN" \
    -caname "$INTER_CERTS_ALIAS_OR_CNAME" \
    -name "$NAME_OR_ALIAS"

  ls -al "${PKCS12_DIR}/${CERT_NAME}.p12"

  echo " < < < end:"
}

## pem to '.p12' to '.jks'. (Java KeyStore)
convert-p12-to-jks(){
  echo
  echo " ✅ > > > begin: convert to jks"

  if [ ! -f "${PKCS12_DIR}/${CERT_NAME}.p12" ]; then
    echo
    echo " ❌❌❌ No file for PKCS12. Path=${PKCS12_DIR}/${CERT_NAME}.p12"
  else
    rm -rfv "$JKS_DIR"
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

    echo " + ✅ inject 'intermediate CA'"
    keytool -import -trustcacerts \
      -file "$FILE_CHAIN" \
      -keystore "${JKS_DIR}/${CERT_NAME}.jks" \
      -storepass "$P12_PWD" \
      -alias "$INTER_CERTS_ALIAS_OR_CNAME" \
      -noprompt

    echo " + ✅ inject 'iROOT CA'"
    keytool -import -trustcacerts \
      -file "$FILE_ROOT" \
      -keystore "${JKS_DIR}/${CERT_NAME}.jks" \
      -storepass "$P12_PWD" \
      -alias "$ROOT_CERTS_ALIAS" \
      -noprompt
  fi

  ls -al "${JKS_DIR}/${CERT_NAME}.jks"

  echo " < < < end:"
}

## send file to destination
send-files(){
  if [ $# -ne 2 ];then
    echo
    echo " ❌❌❌ Illegal arguments."
    return 1
  else
    local srcDir="$1"
    local dstDir="$2"
    echo "scp -i $SSH_PRI_KEY $srcDir/*.* $dstDir"
    if [ $NO_SEND -eq 1 ]; then
      echo " ❗❗❗ DO NOT send files because enables 'NO_SEND'."
      return 0
    else
      scp -i "$SSH_PRI_KEY" "$srcDir"/*.* "$dstDir"
      return $?
    fi
  fi
}

## execute remote cli
exe-cli(){
  local server="$1"
  local cli="$2"
  local prev_status="$3"

  if [ -z "$cli" ]; then
    return 0
  fi

  if [ -n "$prev_status" ] && [ "$prev_status" -ne 0 ]; then
    echo " ❗❗❗ 이전 단계가 실패(status=$prev_status)이므로 CLI 실행을 건너뜁니다. server=$server, cli=$cli"
    return "$prev_status"
  fi

  echo "ssh -i $SSH_PRI_KEY $server \"$cli\""
  if [ $NO_SEND -eq 1 ]; then
    echo " ❗❗❗ DO NOT execute cli because enables 'NO_SEND'."
    return 0
  else
    ssh -i "$SSH_PRI_KEY" "$server" "$cli"
    return $?
  fi
}

## remove directory recursively.
delete-dir(){
  echo "rm -rfv $1"
  if [ $NO_DELETE -eq 1 ]; then
    echo " ❗❗❗ DO NOT delete converted files because enables 'NO_DELETE'."
  else
    rm -rfv "$1"
  fi
}

delete-converted-files(){
  echo
  delete-dir "$SSL_CA_DIR"
  delete-dir "$PKCS12_DIR"
  delete-dir "$JKS_DIR"
}

# ----------------------------------------------------------------------
# 메인 처리
# ----------------------------------------------------------------------
if [ ! -d "$CERT_DIR" ]; then
  echo " ❌❌❌ Invalid certificated files directory. path=$CERT_DIR"
fi

echo
validate-file "$CERT_DIR/cert1.pem"
validate-file "$CERT_DIR/chain1.pem"
validate-file "$CERT_DIR/fullchain1.pem"
validate-file "$CERT_DIR/privkey1.pem"

delete-converted-files

FILE_CERT="$CERT_DIR/cert1.pem"
FILE_CHAIN="$CERT_DIR/chain1.pem"
FILE_FULLCHAIN="$CERT_DIR/fullchain1.pem"
FILE_PRIVKEY="$CERT_DIR/privkey1.pem"
FILE_ROOT="$CERT_DIR/${ROOT_CERTS_ALIAS}.pem"

echo
echo " ✅ > > > download 'ISRG ROOT CACERTS file"
wget -q https://letsencrypt.org/certs/isrgrootx1.pem -O "$FILE_ROOT"

echo
convert-pem-to-sslca

echo
convert-pem-to-p12

echo
convert-p12-to-jks

echo
echo " ✅ > > > begin: send certificates"

declare -A SEND_MAP=()

for dst_conf in "${DEST_CONFS[@]}"; do
  # 형식: <유형>;<사용자ID>@<서버정보>:<경로>[;<CLI>]
  IFS=';' read -r type dst cli <<< "$dst_conf"

  map_key="${type}__cached"
  send_this=0

  if [[ -n "${SEND_MAP[$map_key]}" ]]; then
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

  if [ $send_this -eq 0 ]; then
    echo " - skip (not in target-ca): $dst_conf"
    echo "---"
    continue
  fi

  server="${dst%%:*}"
  status=0

  case "$type" in
    pem)
      send-files "$CERT_DIR" "$dst"
      status=$?
      ;;
    sslca)
      send-files "$SSL_CA_DIR" "$dst"
      status=$?
      ;;
    pkcs12)
      send-files "$PKCS12_DIR" "$dst"
      status=$?
      ;;
    jks)
      send-files "$JKS_DIR" "$dst"
      status=$?
      ;;
    *)
      echo " ❌❌❌ 올바르지 않은 인증서 유형입니다 :=> ${dst_conf}"
      status=1
      ;;
  esac

  if [ -n "$cli" ]; then
    exe-cli "$server" "$cli" "$status"
  fi

  echo "---"
done

echo " < < < end:"

echo
echo "'delete' isrg-root-x1"
rm -rfv "$FILE_ROOT"

popd

echo
exit 0

