#!/usr/bin/env bash

# 디렉토리 생성
mkdir -p "$HOME/bin"
export PATH=$PATH:$HOME/bin

# 설치파일 다운로드
wget -qO $HOME/bin/setup-env.sh  https://github.com/parkjunhong/shellscripts/raw/refs/heads/main/env/setup-env.sh

# 실행권한 추가
chmod +x $HOME/bin/setup-env.sh

# 실행
$HOME/bin/setup-env.sh

exit 0

