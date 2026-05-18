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

echo "[진행] update-mvn-config 설정 중..."
bin_dir="$HOME/bin"
dest_path="$bin_dir/update-mvn-config"

mkdir -p "$bin_dir"

# ---------------------------------------------------------
# curl -f 옵션 추가 및 예외 처리 완화
# 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
# 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
# ---------------------------------------------------------
URL_UPDATE_MVN_CONFIG="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/maven/update-mvn-config"
if ! curl -sfLo "$dest_path" "$URL_UPDATE_MVN_CONFIG"; then
  echo_e " - [ERROR] '기본 Maven 버전 설정 도구' 다운로드 실패"
  echo_e " - [ERROR] '$URL_UPDATE_MVN_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."
  rm -f "$dest_path"
  
  _add_notice " - [$func_name] [ERROR] '기본 Maven 버전 설정 도구' 다운로드 실패"
  _add_notice " - [$func_name] [ERROR] '$URL_UPDATE_MVN_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."
  
  exit 1
fi 

chmod +x "$dest_path"
echo " - $dest_path 다운로드 및 실행 권한 부여 완료."

if ! grep -q "function update-mvn-config()" "$HOME/.bashrc"; then
  cat << 'EOF' >> "$HOME/.bashrc" || error_exit "~/.bashrc 파일 수정 실패" "$LINENO"

# ==========================================
# Maven 환경 변수 관리 (update-mvn-config 연동)
# ==========================================

# 1. 새 터미널 오픈 및 OS 재부팅 시 환경 변수 유지 (조건 2, 3 충족)
if [ -f ~/.maven_env ]; then
  source ~/.maven_env
fi

# 2. 터미널에서 스크립트 실행 직후 현재 쉘에 즉시 동기화하는 래퍼 함수 (조건 1 충족)
function update-mvn-config() {
  ~/bin/update-mvn-config
  if [ -f ~/.maven_env ]; then
      source ~/.maven_env
      echo "[System] 현재 터미널의 M2_HOME, MAVEN_HOME, PATH가 즉시 적용되었습니다."
  fi  
}
EOF
  echo_i " - ~/.bashrc에 update-mvn-config 래퍼 함수를 추가했습니다."
else
  echo_w " - ~/.bashrc에 이미 update-mvn-config 설정이 존재합니다."
fi

exit 0
