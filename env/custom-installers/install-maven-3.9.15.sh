#!/usr/bin/env bash

##
# 오류 메시지를 출력하고 도움말을 호출한 뒤 프로그램을 종료합니다.
#
# @param $1 {string} 발생한 오류 원인 메시지
# @param $2 {string} 오류가 발생한 라인 번호
#
# @return 없음 (스크립트 종료)
##
error_exit() {
  help "$1" "$2"
  exit 1
}

# ==========================================
# 터미널 출력 색상 정의
# ==========================================
if [ -t 1 ]; then
  COLOR_ERROR='\033[1;31m'  # 오류, '31m': 빨강
  COLOR_WARN='\033[1;33m'   # 경고, '33m': 노랑
  COLOR_INFO='\033[1;32m'   # 정보, '32m': 녹색
  COLOR_NC='\033[0m'        # 색상 초기화
else
  COLOR_ERROR=''            # 오류
  COLOR_WARN=''             # 경고
  COLOR_INFO=''             # 정보
  COLOR_NC=''               # 색상 초기화
fi

echo_e() {
  printf "${COLOR_ERROR}%s${COLOR_NC}\n" "$*"
}
echo_w() {
  printf "${COLOR_WARN}%s${COLOR_NC}\n" "$*"
}
echo_i() {
  printf "${COLOR_INFO}%s${COLOR_NC}\n" "$*"
}

echo "[진행] Maven 설치 중..."
  
# 파일명에서 정규식을 사용해 버전(예: 3.9.15)을 파싱
URL_MAVEN_FILE="https://dlcdn.apache.org/maven/maven-3/3.9.15/binaries/apache-maven-3.9.15-bin.tar.gz"
file_name=$(basename "$URL_MAVEN_FILE")
mvn_version=$(echo "$file_name" | sed -n 's/.*apache-maven-\([0-9\.]*\)-bin.*/\1/p')

if [ -z "$mvn_version" ]; then
  error_exit "Maven 다운로드 URL에서 버전을 파싱할 수 없습니다." "$LINENO"
fi

target_dir="/opt/apache-maven-${mvn_version}"
if [ -d "$target_dir" ]; then
  echo_w " - Maven 버전 ${mvn_version} 이(가) 이미 존재하므로 설치를 건너뜁니다."  
  
  exit 0
fi

temp_archive="/tmp/$file_name"

# ---------------------------------------------------------
# curl -f 옵션 추가 및 예외 처리 완화
# 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
# 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
# ---------------------------------------------------------
if ! curl -sfLo "$temp_archive" "$URL_MAVEN_FILE"; then
  echo_e " - [ERROR] Maven 다운로드 실패"
  echo_e " - [ERROR] '$URL_MAVEN_FILE' 파일이 존재하지 않아 설치를 생략합니다."
  rm -f "$temp_archive"
  
  _add_notice " - [$func_name] [ERROR] Maven 다운로드 실패"
  _add_notice " - [$func_name] [ERROR] '$URL_MAVEN_FILE' 파일이 존재하지 않아 설치를 생략합니다."

  exit 1
fi 

sudo mkdir -p /opt || error_exit "/opt 디렉토리 생성 실패" "$LINENO"
sudo tar -xzf "$temp_archive" -C /opt/ || error_exit "Maven 압축 해제 실패" "$LINENO"
rm -f "$temp_archive"
echo_i " - Maven 바이너리를 $target_dir 에 설치했습니다."

exit 0
