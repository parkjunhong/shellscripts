#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : install-maven-3.9.15.sh: Apache Maven 3.9.15 Binary Installer
# @license  : Apache License 2.0
# @since    : 2026-06-23
# @desc     : support Ubuntu 24.04+, RockyOS 9+, RHEL 9+, CentOS Stream 9+
# =======================================

echo "[진행] Maven 설치 중..."

URL_MAVEN_FILE="https://archive.apache.org/dist/maven/maven-3/3.9.15/binaries/apache-maven-3.9.15-bin.tar.gz"
file_name="$(basename "$URL_MAVEN_FILE")"
mvn_version="$(echo "$file_name" | sed -n 's/.*apache-maven-\([0-9\.]*\)-bin.*/\1/p')"

if [ -z "$mvn_version" ]; then
  error_exit "Maven 다운로드 URL에서 버전을 파싱할 수 없습니다." "$LINENO"
fi

target_dir="/opt/apache-maven-${mvn_version}"
if [ -d "$target_dir" ]; then
  echo_w " - Maven 버전 ${mvn_version} 이(가) 이미 존재하므로 설치를 건너뜁니다."
  exit 0
fi

temp_archive="/tmp/$file_name"

if ! curl -sfLo "$temp_archive" "$URL_MAVEN_FILE"; then
  echo_e " - [ERROR] Maven 다운로드 실패"
  echo_e " - [ERROR] '$URL_MAVEN_FILE' 파일이 존재하지 않아 설치를 생략합니다."
  rm -f -- "$temp_archive"

  _add_notice " - [install-maven-3.9.15.sh] [ERROR] Maven 다운로드 실패"
  _add_notice " - [install-maven-3.9.15.sh] [ERROR] '$URL_MAVEN_FILE' 파일이 존재하지 않아 설치를 생략합니다."

  exit 1
fi

sudo mkdir -p /opt || error_exit "/opt 디렉토리 생성 실패" "$LINENO"
sudo tar -xzf "$temp_archive" -C /opt/ || error_exit "Maven 압축 해제 실패" "$LINENO"
rm -f -- "$temp_archive"
echo_i " - Maven 바이너리를 $target_dir 에 설치했습니다."

exit 0
