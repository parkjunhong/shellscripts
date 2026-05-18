#!/usr/bin/env bash

# ==========================================

echo "[진행] update-java-config 설정 중..."
bin_dir="$HOME/bin"
dest_path="$bin_dir/update-java-config"

mkdir -p "$bin_dir"

# ---------------------------------------------------------
# curl -f 옵션 추가 및 예외 처리 완화
# 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
# 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
# ---------------------------------------------------------
URL_UPDATE_JAVA_CONFIG="https://github.com/parkjunhong/shellscripts/raw/refs/heads/main/java/update-java-config"
if ! curl -sfLo "$dest_path" "$URL_UPDATE_JAVA_CONFIG"; then
  echo_e " - [ERROR] '기본 Java 설정 도구' 다운로드 실패"
  echo_e " - [ERROR] '$URL_UPDATE_JAVA_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."
  rm -f "$dest_path"
  
  _add_notice " - [$func_name] [ERROR] '기본 Java 설정 도구' 다운로드 실패"
  _add_notice " - [$func_name] [ERROR] '$URL_UPDATE_JAVA_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."

  exit 1
fi 

chmod +x "$dest_path"
echo " - $dest_path 다운로드 및 실행 권한 부여 완료."

if ! grep -q "function update-java-config()" "$HOME/.bashrc"; then
  cat << 'EOF' >> "$HOME/.bashrc" || error_exit "~/.bashrc 파일 수정 실패" "$LINENO"

# ==========================================
# Java 환경 변수 관리 (update-java-config 연동)
# ==========================================

# 1. 새 터미널 오픈 및 OS 재부팅 시 환경 변수 유지
if [ -f ~/.java_env ]; then
  source ~/.java_env
fi

# 2. 터미널에서 스크립트 실행 직후 현재 쉘에 즉시 동기화하는 래퍼 함수
function update-java-config() {
  ~/bin/update-java-config
  if [ -f ~/.java_env ]; then
      source ~/.java_env
      echo "[System] 현재 터미널의 JAVA_HOME이 즉시 적용되었습니다."
  fi
}
EOF
  echo_i " - ~/.bashrc에 update-java-config 래퍼 함수를 추가했습니다."
else
  echo_w " - ~/.bashrc에 이미 update-java-config 설정이 존재합니다."
fi

exit 0
