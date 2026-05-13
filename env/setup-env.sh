#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : setup-env.sh
# @license  : Apache License 2.0
# @since    : 2026-05-12
# @desc     : support Ubuntu 24+, Rocky Linux 9+
# @installation : 
#   1. insert 'source <path>/setup-env.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/setup-env.sh' into 
#   etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")

# ==========================================
# 전역 변수: 패키지 매니저 환경 자동 판별
# ==========================================
PKG_MANAGER=""
PKG_UPDATE_CMD=""
PKG_INSTALL_CMD=""

if command -v apt &> /dev/null; then
  PKG_MANAGER="apt"
  PKG_UPDATE_CMD="sudo apt update"
  PKG_INSTALL_CMD="sudo apt install -y"
elif command -v dnf &> /dev/null; then
  PKG_MANAGER="dnf"
  PKG_UPDATE_CMD="sudo dnf check-update"
  PKG_INSTALL_CMD="sudo dnf install -y"
else
  echo "[오류] 지원하지 않는 운영체제입니다. (apt 또는 dnf가 필요합니다.)"
  exit 1
fi

# ==========================================
# 외부 설정 파일(Properties) 다운로드 및 로드
# ==========================================
CONFIG_URL="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/env/configurations.properties"
CONFIG_FILE="/tmp/configurations.properties"

if ! command -v curl &> /dev/null; then
  echo "[진행] curl 임시 설치 중 (설정 파일 다운로드용)..."
  $PKG_UPDATE_CMD > /dev/null 2>&1
  $PKG_INSTALL_CMD curl > /dev/null 2>&1
fi

curl -sLo "$CONFIG_FILE" "$CONFIG_URL" || { echo "[오류] 외부 설정 파일을 다운로드할 수 없습니다."; exit 1; }

# ---------------------------------------------------------
# [개선됨] Properties 파일을 가장 안전하게 파싱하여 변수로 등록
# - 쌍따옴표("), 따옴표('), 공백, 특수문자($) 등이 있어도 오류가 나지 않음
# ---------------------------------------------------------
while IFS='=' read -r key value || [ -n "$key" ]; do
  # 주석(#)이거나 빈 줄이면 건너뛰기
  if [[ "$key" =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
    continue
  fi

  # Key와 Value의 양옆 공백 제거 (Value 내부의 띄어쓰기는 그대로 유지됨)
  key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # 일반 변수만 export 처리 (배열 식별용 점(.)이 포함된 키는 제외)
  if [[ ! "$key" =~ \. ]]; then
    export "$key"="$value"
  fi
done < "$CONFIG_FILE"

# 1. 다중 RSA 공개키 설정 파싱 및 배열에 담기
RSA_PUBLIC_KEY_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*RSA_PUBLIC_KEY\. ]] && RSA_PUBLIC_KEY_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

# 2. 다중 사용자 정의 도구 URL 파싱 및 배열에 담기
CUSTOM_TOOLS_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*URL_CUSTOM_TOOL\. ]] && CUSTOM_TOOLS_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

rm -f "$CONFIG_FILE"

##
# 도움말을 출력합니다.
#
# @param $1 {string} 오류 원인 메시지 (선택)
# @param $2 {string} 오류 발생 라인 번호 (선택)
#
# @return 도움말 포맷 출력 (표준 출력)
##
help(){
  if [ ! -z "$1" ]; then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}; do  
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법:"
  echo "  ./$FILENAME [옵션]"
  echo ""
  echo "옵션:"
  echo "  -h, --help      : 도움말을 출력합니다."
  echo "  --all           : '--jdk, --maven'를 설치합니다."
  echo "  --jdk           : JDK를 설치합니다. 내부적으로 '--java-config'를 진행합니다."
  echo "  --java-config   : update-java-config 스크립트를 설치하고 설정합니다."
  echo "  --maven         : Apache Maven을 설치합니다. 내부적으로 '--mvn-config'를 진행합니다."
  echo "  --mvn-config    : update-mvn-config 스크립트를 설치하고 설정합니다."
  echo "  --ssh-key       : RSA 공개키를 authorized_keys에 등록합니다."
}

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

# 패키지 업데이트 여부
PKG_UPDATED=0

##
# 스크립트 실행 중 1번만 OS에 맞는 패키지 매니저 업데이트를 실행하도록 보장합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_try_pkg_update() {
  echo "............... ${FUNCNAME[0]} ..............."
  if [ "$PKG_UPDATED" -eq 0 ]; then
    echo "[진행] 패키지 인덱스 업데이트 중 ($PKG_MANAGER)..."
    $PKG_UPDATE_CMD || true
    PKG_UPDATED=1
  fi
}

##
# OS에 맞는 패키지 매니저로 설치를 진행합니다.
#
# @param $1 {string} 패키지 이름
#
# @return 진행 상황 메시지 (표준 출력)
##
_install_package() {
  if ! command -v "$1" &> /dev/null; then
    echo "[진행] $1 설치 중..."
    _try_pkg_update
    $PKG_INSTALL_CMD "$1" || error_exit "$1 설치 실패" "$LINENO"
  fi
}

##
# 외부 설정파일의 DEFAULT_TOOLS를 읽어 공통 설치 함수를 통해 설치합니다.
##
_setup_default_tools() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  IFS=',' read -ra TOOLS <<< "$DEFAULT_TOOLS"
  for tool in "${TOOLS[@]}"; do
    tool=$(echo "$tool" | xargs) # 양옆 공백 제거
    _install_package "$tool"
  done
}

##
# Bash Completion 파일을 시스템의 올바른 경로에 다운로드하고 현재 쉘에 즉시 적용합니다.
# OS 환경(Ubuntu, Rocky 등)에 따라 설치 경로를 동적으로 탐색합니다.
#
# @param $1 {string} bash completion 파일의 다운로드 URL
# @param $2 {string} 대상 명령어 이름 (이 이름으로 completion 파일이 저장됨)
#
# @return 진행 상황 메시지 (표준 출력)
##
_install_completion() {
  echo "............... ${FUNCNAME[0]} - $2 ..............."
  
  local comp_url="$1"
  local target_cmd="$2"
  
  if [ -z "$comp_url" ] || [ -z "$target_cmd" ]; then
    error_exit "completion 설치 함수 호출 오류: URL 또는 명령어 이름이 누락되었습니다." "$LINENO"
  fi

  # ========================================================
  # Bash Completion 설치 경로 동적 탐색 (Ubuntu 24+, Rocky 9+ 지원)
  # ========================================================
  local comp_dir=""
  
  if command -v pkg-config &> /dev/null; then
    comp_dir=$(pkg-config --variable=completionsdir bash-completion 2>/dev/null)
  fi

  if [ -z "$comp_dir" ] && [ -d "/usr/share/bash-completion/completions" ]; then
    comp_dir="/usr/share/bash-completion/completions"
  elif [ -z "$comp_dir" ] && [ -d "/etc/bash_completion.d" ]; then
    comp_dir="/etc/bash_completion.d"
  fi

  if [ -z "$comp_dir" ]; then
    echo " - [경고] bash-completion 경로를 찾지 못했습니다. 임시로 /etc/bash_completion.d를 생성합니다."
    comp_dir="/etc/bash_completion.d"
    sudo mkdir -p "$comp_dir"
  fi
  # ========================================================

  local temp_comp="/tmp/${target_cmd}.completion"
  curl -sLo "$temp_comp" "$comp_url" || error_exit "${target_cmd} completion 다운로드 실패" "$LINENO"
  
  # 구형 폴더면 .completion 확장자 유지, 신형 표준 폴더면 명령어 이름과 정확히 일치시킴
  local target_comp_file="$comp_dir/$target_cmd"
  if [[ "$comp_dir" == *"/etc/bash_completion.d"* ]]; then
      target_comp_file="$comp_dir/${target_cmd}.completion"
  fi

  if [ -f "$target_comp_file" ]; then
    if ! cmp -s "$temp_comp" "$target_comp_file"; then
      read -p "> ${target_cmd} completion 내용이 다릅니다. 업데이트하시겠습니까? (y/n): " ch
      if [[ "$ch" == "y" || "$ch" == "Y" ]]; then
        sudo mv "$temp_comp" "$target_comp_file"
        echo " - ${target_cmd} completion 파일이 업데이트되었습니다."
      else
        echo " - ${target_cmd} completion 파일 설치를 유지합니다."
        rm -f "$temp_comp"
      fi
    else
      echo " - ${target_cmd} completion 파일이 이미 최신입니다."
      rm -f "$temp_comp"
    fi
  else
    sudo mv "$temp_comp" "$target_comp_file"
    echo " - ${target_cmd} completion 파일을 설치했습니다."
  fi
  
  # Bash Completion 현재 쉘 즉시 적용
  if [ -f "$target_comp_file" ]; then
    source "$target_comp_file" 2>/dev/null || true
    echo " - [System] ${target_cmd} 자동완성이 현재 터미널에 즉시 적용되었습니다."
  fi
}

##
# 사용자 정의 도구 및 bash completion 파일을 다운로드하고 설치합니다.
# 파일이 이미 존재할 경우 내용을 비교하여 다를 때만 사용자에게 설치 여부를 확인합니다.
#
# @param $1 사용자 정의 도구 URL
#
# @return 진행 상황 메시지 (표준 출력)
##
_install_custom_tools() {
  local tool_url="$1"
  local target_cmd=$(basename "$tool_url")
  
  echo
  echo "############### ${FUNCNAME[0]} - $target_cmd ###############"
  echo "[진행] '$target_cmd' 설치 중..."
  local bin_dir="$HOME/bin"
  local temp_bin="/tmp/${target_cmd}"
  
  curl -sLo "$temp_bin" "$tool_url" || error_exit "'$target_cmd' 다운로드 실패" "$LINENO"
  
  if [ -f "$bin_dir/$target_cmd" ]; then
    if ! cmp -s "$temp_bin" "$bin_dir/$target_cmd"; then
      read -p "> '$target_cmd' 실행 파일 내용이 다릅니다. 업데이트하시겠습니까? (y/n): " ch
      if [[ "$ch" == "y" || "$ch" == "Y" ]]; then
        mv "$temp_bin" "$bin_dir/$target_cmd" && chmod +x "$bin_dir/$target_cmd"
        echo " - '$target_cmd' 실행 파일이 업데이트되었습니다."
      else
        echo " - '$target_cmd' 실행 파일 설치를 유지합니다."
        rm -f "$temp_bin"
      fi
    else
      echo " - '$target_cmd' 실행 파일이 이미 최신입니다."
      rm -f "$temp_bin"
    fi
  else
    mkdir -p "$bin_dir" && mv "$temp_bin" "$bin_dir/$target_cmd" && chmod +x "$bin_dir/$target_cmd"
    echo " - '$target_cmd' 실행 파일을 설치했습니다."
  fi

  # 공통 함수를 호출하여 completion 다운로드 및 설치 위임 (URL은 tool_url.completion 규칙 적용)
  local completion_url="${tool_url}.completion"
  _install_completion "$completion_url" "$target_cmd"
}

##
# 외부 설정파일의 URL_CUSTOM_TOOLS.<식별자> 패턴을 읽어 다수의 사용자 정의 도구를 순차적으로 설치합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_custom_tools() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  if [ ${#CUSTOM_TOOLS_LIST[@]} -gt 0 ]; then
    for tool_url in "${CUSTOM_TOOLS_LIST[@]}"; do
      if [ -n "$tool_url" ]; then
        _install_custom_tools "$tool_url"
      fi
    done
  else
    echo " - 설정된 커스텀 도구가 없습니다."
  fi
}

##
# 사용자의 홈 디렉토리에 bin 디렉토리를 생성하고, PATH 환경변수에 등록합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_home_bin() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  echo "[진행] ~/bin 디렉토리 설정 중..."
  local bin_dir="$HOME/bin"
  if [ ! -d "$bin_dir" ]; then
    mkdir -p "$bin_dir" || error_exit "~/bin 디렉토리 생성 실패" "$LINENO"
    echo " - ~/bin 디렉토리를 생성했습니다."
  fi
  if ! grep -q "PATH=\$PATH:$bin_dir" "$HOME/.bashrc"; then
    echo "PATH=\$PATH:$bin_dir" >> "$HOME/.bashrc" || error_exit "~/.bashrc 파일 수정 실패" "$LINENO"
    echo " - ~/.bashrc 파일에 PATH 설정을 추가했습니다."
  else
    echo " - ~/.bashrc 파일에 이미 PATH 설정이 존재합니다."
  fi

  source "$HOME/.bashrc"
}

##
# .bashrc 파일에 현재 위치의 git branch를 표시하는 프롬프트(PS1) 설정을 추가합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_git_prompt() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  echo "[진행] git branch 프롬프트 설정 중..."
  if ! grep -q "parse_git_branch()" "$HOME/.bashrc"; then
    cat << 'EOF' >> "$HOME/.bashrc" || error_exit "~/.bashrc 파일 수정 실패" "$LINENO"

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /' 
}

PS1='[directory] \[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\n[\t ] \[\033[01;32m\]\u@\h\[\033[00m\]:$ '
EOF
    echo " - ~/.bashrc에 프롬프트 설정을 추가했습니다."
  else
    echo " - ~/.bashrc 파일에 이미 git 프롬프트 설정이 존재합니다."
  fi
}

##
# 사용자를 sudoers 그룹에 등록하고 특정 관리 명령어들의 비밀번호 입력을 면제합니다.
# 외부설정된 NO_PASSWORD_COMMANDS 값을 활용하며, 사용자 입력을 통해 대상을 지정합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_sudoers() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  echo "[진행] 사용자 sudoers 설정 중..."
  
  # 1. 기본값으로 사용할 현재 접속 계정 확인
  local current_user="${USER:-$(whoami)}"
  local target_user=""
  local interrupted=0

  # 2. Ctrl+C (SIGINT) 입력 시 전체 종료를 막고 플래그만 변경하도록 트랩 설정
  trap 'interrupted=1' SIGINT
  
  # 3. 사용자 입력 대기
  read -r -p "> sudoers에 등록할 사용자 계정을 입력하세요 (기본값: $current_user) [취소: Ctrl+C]: " target_user
  
  # 4. 입력 종료 후 트랩 해제 (기본 동작으로 복구)
  trap - SIGINT
  
  # Ctrl+C가 눌렸을 경우 (interrupted 플래그 확인)
  if [ "$interrupted" -eq 1 ]; then
    echo -e "\n - [취소] sudoers 설정을 건너뛰고 다음 단계로 진행합니다."
    return 0
  fi

  # 입력값이 비어있으면 기본값(현재 사용자)으로 설정
  if [ -z "$target_user" ]; then
    target_user="$current_user"
  fi

  local sudoers_file="/etc/sudoers.d/$target_user"

  if ! id "$target_user" &>/dev/null; then
    error_exit "'$target_user' 사용자가 시스템에 존재하지 않습니다." "$LINENO"
  fi

  echo "$target_user ALL=(ALL) ALL" | sudo tee "$sudoers_file" > /dev/null
  
  # OS에 따라 패키지 매니저 경로를 추가
  local os_pkg_cmd=""
  if [ "$PKG_MANAGER" == "apt" ]; then
    os_pkg_cmd="/usr/bin/apt, /usr/bin/apt-get, "
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    os_pkg_cmd="/usr/bin/dnf, "
  fi
  
  local full_no_pw_cmds="${os_pkg_cmd}${NO_PASSWORD_COMMANDS}"

  echo "$target_user ALL=(ALL) NOPASSWD: $full_no_pw_cmds" | sudo tee -a "$sudoers_file" > /dev/null
  
  sudo chmod 440 "$sudoers_file"
  echo " - $target_user sudoers 설정이 완료되었습니다."
}

##
# /etc/vim/vimrc 파일에 커스텀 기본 옵션들을 활성화합니다. (vim 패키지 설치는 _install_package가 담당)
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_install_vim_options() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  echo "[진행] vim 환경 설정 중..."
  
  local vimrc_file="/etc/vim/vimrc"
  
  # Rocky Linux 등 일부 OS에서는 /etc/vimrc 경로를 사용
  if [ ! -f "$vimrc_file" ] && [ -f "/etc/vimrc" ]; then
    vimrc_file="/etc/vimrc"
  fi
  
  if [ -f "$vimrc_file" ]; then
    # 중복 설정 방지 체크
    if ! grep -q "\" Custom Settings by setup-env.sh" "$vimrc_file"; then
      cat << 'EOF' | sudo tee -a "$vimrc_file" > /dev/null

" Custom Settings by setup-env.sh
set showcmd   " Show (partial) command in status line.
set ts=2
set shiftwidth=2
set paste
set hlsearch
set nu
set expandtab
EOF
      echo " - $vimrc_file 파일에 커스텀 설정을 추가했습니다."
    else
      echo " - $vimrc_file 파일에 이미 커스텀 설정이 존재합니다."
    fi
  else
    echo " - [경고] vimrc 파일을 찾지 못해 커스텀 설정을 추가하지 못했습니다."
  fi
}

##
# 외부설정된 URL의 원격 스크립트를 통해 Eclipse Temurin JDK 25를 설치합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
install_jdk() {
  echo "[진행] JDK 설치 중..."
  local temp_script="/tmp/install-jdk.sh"
  
  curl -sLo "$temp_script" "$URL_JDK_INSTALLER" || error_exit "JDK 설치 스크립트 다운로드 실패" "$LINENO"
  chmod +x "$temp_script"
  sudo "$temp_script" || error_exit "JDK 설치 스크립트 실행 실패" "$LINENO"
  rm -f "$temp_script"
  echo " - JDK 설치가 완료되었습니다."
  
  setup_java_config
}

##
# 외부설정된 URL에서 update-java-config 스크립트를 다운로드하고 .bashrc에 래퍼 함수를 등록합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_java_config() {
  echo "[진행] update-java-config 설정 중..."
  local bin_dir="$HOME/bin"
  local dest_path="$bin_dir/update-java-config"
  
  mkdir -p "$bin_dir"
  curl -sLo "$dest_path" "$URL_UPDATE_JAVA_CONFIG" || error_exit "update-java-config 다운로드 실패" "$LINENO"
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
    echo " - ~/.bashrc에 update-java-config 래퍼 함수를 추가했습니다."
  else
    echo " - ~/.bashrc에 이미 update-java-config 설정이 존재합니다."
  fi
}

##
# 외부설정된 URL로부터 Maven 바이너리를 다운로드하고 /opt 디렉토리에 압축을 해제합니다.
# 파일명에서 버전을 유추하여 중복 설치를 방지합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
install_maven() {
  echo "[진행] Maven 설치 중..."
  
  # 파일명에서 정규식을 사용해 버전(예: 3.9.15)을 파싱
  local file_name=$(basename "$URL_MAVEN_FILE")
  local mvn_version=$(echo "$file_name" | sed -n 's/.*apache-maven-\([0-9\.]*\)-bin.*/\1/p')
  
  if [ -z "$mvn_version" ]; then
    error_exit "Maven 다운로드 URL에서 버전을 파싱할 수 없습니다." "$LINENO"
  fi

  local target_dir="/opt/apache-maven-${mvn_version}"
  if [ -d "$target_dir" ]; then
    echo " - Maven 버전 ${mvn_version} 이(가) 이미 존재하므로 설치를 건너뜁니다."
    return 0
  fi

  local temp_archive="/tmp/$file_name"
  curl -sLo "$temp_archive" "$URL_MAVEN_FILE" || error_exit "Maven 다운로드 실패" "$LINENO"
  sudo mkdir -p /opt || error_exit "/opt 디렉토리 생성 실패" "$LINENO"
  sudo tar -xzf "$temp_archive" -C /opt/ || error_exit "Maven 압축 해제 실패" "$LINENO"
  rm -f "$temp_archive"
  echo " - Maven 바이너리를 $target_dir 에 설치했습니다."
  
  setup_mvn_config
}

##
# 외부설정된 URL에서 update-mvn-config 스크립트를 다운로드하고 .bashrc에 래퍼 함수를 등록합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_mvn_config() {
  echo "[진행] update-mvn-config 설정 중..."
  local bin_dir="$HOME/bin"
  local dest_path="$bin_dir/update-mvn-config"
  
  mkdir -p "$bin_dir"
  curl -sLo "$dest_path" "$URL_UPDATE_MVN_CONFIG" || error_exit "update-mvn-config 다운로드 실패" "$LINENO"
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
    echo " - ~/.bashrc에 update-mvn-config 래퍼 함수를 추가했습니다."
  else
    echo " - ~/.bashrc에 이미 update-mvn-config 설정이 존재합니다."
  fi
}

##
# 외부설정된 RSA_PUBLIC_KEY_LIST 배열을 통해 ~/.ssh/authorized_keys 파일에 여러 공개키를 등록합니다.
##
setup_ssh_key() {
  echo
  echo "############### ${FUNCNAME[0]} ###############"
  echo "[진행] SSH RSA 키 등록 중..."
  local ssh_dir="$HOME/.ssh"
  local auth_file="$ssh_dir/authorized_keys"
  
  [ ! -d "$ssh_dir" ] && mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"
  [ ! -f "$auth_file" ] && touch "$auth_file" && chmod 600 "$auth_file"

  # 프로퍼티 파일에서 배열로 담은 모든 SSH 키 반복 등록
  for public_key in "${RSA_PUBLIC_KEY_LIST[@]}"; do
    # 식별자(주석)가 아닌 실제 Base64 키 데이터 부분만 추출하여 검증에 사용
    local key_body=$(echo "$public_key" | awk '{print $2}')

    # 정규표현식 특수문자(+) 오작동 방지를 위해 고정 문자열 검색 옵션(-F) 사용
    if ! grep -qF "$key_body" "$auth_file"; then
      echo "$public_key" >> "$auth_file"
      echo " - 공개키를 등록했습니다: ${public_key:0:30}..."
    else
      echo " - 이미 등록된 키입니다: ${public_key:0:30}..."
    fi
  done
  
  chmod 600 "$auth_file"
}

# 파라미터가 없는 경우 도움말 호출
if [ $# -eq 0 ]; then
  help "파라미터가 입력되지 않았습니다." "$LINENO"
  exit 1
fi

# ==========================================
# 1. 도움말 옵션 사전 검사 (Pre-pass)
# ==========================================
# 파라미터 중 어디에라도 -h 또는 --help가 있다면 다른 작업 없이 도움말만 출력하고 즉시 종료합니다.
for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    help
    exit 0
  fi
done

# ==========================================
# 2. 필수 기본 설치 진행
# ==========================================
# 사전 검사를 무사히 통과했다면(도움말 요청이 아님) 기본 도구들을 무조건 설치합니다.
_setup_home_bin  
_setup_sudoers
_setup_default_tools # DEFAULT_TOOLS 기반 _install_package 실행
_setup_custom_tools # URL_CUSTOM_TOOLS 배열 기반 자동 처리
_setup_git_prompt
_install_vim_options # `vim` 옵션 적용

# ==========================================
# 3. 메인 실행부 (선택 옵션 처리)
# ==========================================
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --jdk)
      install_jdk
      shift
      ;;
    --java-config)
      setup_java_config
      shift
      ;;
    --maven)
      install_maven
      shift
      ;;
    --mvn-config)
      setup_mvn_config
      shift
      ;;
    --ssh-key)
      setup_ssh_key
      shift
      ;;
    --all)
      install_jdk
      install_maven
      shift
      ;;
    *)
      error_exit "알 수 없는 옵션: $1" "$LINENO"
      ;;
  esac
done

exit 0
