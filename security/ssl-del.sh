#!/bin/bash

# =======================================
# @auther : parkjunhong77@gmail.com
# @title  : Let's Encrypt 인증서 추가 (Java & IDE Cacerts)
# @license: Apache License 2.0
# @since  : 2025-02-12
# @helpers: https://chatgpt.com/, https://gemini.google.com/
# =======================================

help() {
    
  if [ $# -gt 0 ];then
      echo
      echo "['${FUNCNAME[1]}' says] " $1
  fi  

  echo ""
  echo "설명: Let's Encrypt 인증서를 다운로드하여 Java 및 IDE Cacerts에 추가합니다."
  echo ""
  echo "사용법: $0 -server <서버 주소> -alias <alias 이름> [-ide <IDE cacerts 파일 경로>]"
  echo ""
  echo "필수 인자:"
  echo "  -server <서버 주소>: Let's Encrypt 인증서를 발급받을 서버 주소 (예: example.com)"
	echo "  -alias <별칭>: 적용할 인증서 별칭"
  echo ""
  echo "선택적 인자:"
  echo "  -cacerts_files <파일1,파일2,...>: 콤마(,)로 구분된 추가할 cacerts 파일 경로 목록"
  echo ""
  echo "참고:"
  echo "  - Java cacerts 파일은 $JAVA_HOME/lib/security/cacerts 에 위치합니다. JAVA_HOME 환경변수가 설정되지 않은 경우, java 명령어를 찾아서 자동으로 경로를 추적합니다."
  echo "  - 인증서 저장소 비밀번호는 'changeit'으로 고정되어 있습니다. 필요에 따라 스크립트를 수정하여 변경할 수 있습니다."
  echo "  - 스크립트 실행 시 sudo 권한이 필요합니다."
  echo ""
  exit 0
}

# === 초기 변수 설정 ===
SERVER=""
ALIAS=""
CACERTS_FILES=""
CERT_FILE="/tmp/letsencrypt-cert.crt"
STOREPASS="changeit"

# === 명령줄 인자 처리 ===
while [[ $# -gt 0 ]]; do
  case $1 in
    -server)
      SERVER="$2"
      CERT_FILE="$2-cert.crt"
      shift 2
      ;;
		-alias)
			ALIAS="$2"
			shift 2			
			;;
    -cacerts_files)
      CACERTS_FILES="$2"
      shift 2
      ;;
    -h|--help) # help 옵션 추가
      help
      ;;
    *)
      echo "❌ 알 수 없는 옵션: $1"
      help # help() 함수 호출
      ;;
  esac
done

# === 필수 입력값 검증 ===
if [[ -z "$SERVER" || -z "$ALIAS" ]]; then
  echo "❌ 필수 입력값 누락!"
  help # help() 함수 호출
fi

# === Java cacerts 경로 자동 탐색 (OS 분기) ===
JAVA_HOME_USER=$(echo $JAVA_HOME)
if [ -z "$JAVA_HOME_USER" ]; then
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then # Linux
	  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
	elif [[ "$OSTYPE" == "darwin"* ]]; then # macOS
	  JAVA_HOME=$(/usr/libexec/java_home)
	else
	  echo "❌ 지원하지 않는 운영체제입니다: $OSTYPE"
	  exit 1
	fi
else
	JAVA_HOME=$(readlink -f "$JAVA_HOME_USER")
fi
JAVA_CACERTS=$(find $JAVA_HOME -name cacerts)

if [ ! -f "$JAVA_CACERTS" ]; then
  echo "❌ Java cacerts 파일을 찾을 수 없습니다! (JAVA_HOME: $JAVA_HOME)"
  echo "❌ Java cacerts 파일을 찾을 수 없습니다! (JAVA_CERT: $JAVA_CACERTS)"
  exit 1
fi
echo "✅ Java cacerts 파일 위치: $JAVA_CACERTS"

# === 1. Java TrustStore 갱신 (sudo 사용) ===
echo " [begin] >>> Java TrustStore"
echo " Java TrustStore에서 기존 '$ALIAS' 인증서를 제거합니다..."
sudo keytool -delete -alias "$ALIAS" -keystore "$JAVA_CACERTS" -storepass "$STOREPASS" -noprompt 2>/dev/null

# === 2. 추가적인 cacerts 파일 갱신 (옵션) ===
if [[ -n "$CACERTS_FILES" ]]; then
  echo " [begin] >>> 추가적인 cacerts 파일"
  IFS=',' read -ra FILES <<< "$CACERTS_FILES"
  for CACERTS_FILE in "${FILES[@]}"; do
    if [ ! -f "$CACERTS_FILE" ]; then
      echo "❌ 지정된 cacerts 파일을 찾을 수 없습니다! ($CACERTS_FILE)"
      continue
    fi
    echo "✅ 추가적인 cacerts 파일 위치: $CACERTS_FILE"

    echo " $CACERTS_FILE 에서 기존 '$ALIAS' 인증서를 제거합니다..."
    sudo keytool -delete -alias "$ALIAS" -keystore "$CACERTS_FILE" -storepass "$STOREPASS" -noprompt 2>/dev/null

  done
  echo " [end] <<< 추가적인 cacerts 파일"
fi

# === 3. 인증서 추가 결과 검증 ===
echo " Java TrustStore에 추가된 인증서 확인:"
sudo keytool -list -keystore "$JAVA_CACERTS" -storepass "$STOREPASS" -alias "$ALIAS" 2>/dev/null | grep -i "$ALIAS"
if [ $? -eq 0 ]; then
  echo "✅ Java TrustStore에 인증서가 삭제되었습니다.!"
else
  echo "❌ Java TrustStore에 인증서가 삭제되지 않았습니다!"
fi

if [[ -n "$CACERTS_FILES" ]]; then
	for CACERTS_FILE in "${FILES[@]}"; do
		echo " $CACERTS_FILE 에 추가된 인증서 확인:"
		sudo keytool -list -keystore "$CACERTS_FILE" -storepass "$STOREPASS" -alias "$ALIAS" 2>/dev/null | grep -i "$ALIAS"
	  if [ $? -eq 0 ]; then
  	  echo "✅ 인증서가 삭제되었습니다! => $CACERTS_FILE"
	  else
    	echo "❌ 인증서가 삭제되지 않았습니다! => $CACERTS_FILE"
	  fi
	done
fi

echo "✅ 인증서 삭제 완료! (Java & IDE Cacerts)"


