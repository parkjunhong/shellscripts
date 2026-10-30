#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : install-update-mvn-config.sh: Maven Environment Switcher Installer
# @license  : Apache License 2.0
# @since    : 2026-06-23
# @desc     : support Ubuntu 24.04+, RockyOS 9+, RHEL 9+, CentOS Stream 9+
# =======================================

echo "[진행] update-mvn-config 설정 중..."
bin_dir="$HOME/bin"
dest_path="$bin_dir/update-mvn-config"

mkdir -p "$bin_dir"

URL_UPDATE_MVN_CONFIG="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/maven/update-mvn-config/update-mvn-config"
if ! curl -sfLo "$dest_path" "$URL_UPDATE_MVN_CONFIG"; then
  echo_e " - [ERROR] '기본 Maven 버전 설정 도구' 다운로드 실패"
  echo_e " - [ERROR] '$URL_UPDATE_MVN_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."
  rm -f -- "$dest_path"

  _add_notice " - [install-update-mvn-config.sh] [ERROR] '기본 Maven 버전 설정 도구' 다운로드 실패"
  _add_notice " - [install-update-mvn-config.sh] [ERROR] '$URL_UPDATE_MVN_CONFIG' 파일이 존재하지 않아 설치를 생략합니다."

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
  ~/bin/update-mvn-config "$@"
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

# 최초 설치 시 실행하여 MVN_HOME, M2_HOME 설정 (비대화형 환경이 아닐 때 실행)
if [[ -t 0 ]]; then
  "$HOME/bin/update-mvn-config" || true
else
  _add_notice " - [update-mvn-config] 비대화형 모드이므로 초기 실행을 생략했습니다. 터미널에서 'update-mvn-config'를 실행하여 기본 Maven을 선택하세요."
fi

exit 0
