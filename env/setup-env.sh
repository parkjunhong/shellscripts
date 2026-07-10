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

# 작업 완료 후 사용자에게 알려야 하는 메시지.
# 부모와 자식이 공유할 공통 공지사항 임시 파일 경로 설정
export NOTICE_MESSAGES_TEMP_FILE="/tmp/setup_env_notice_messages_$$.tmp"
# 스크립트 시작 시 기존 찌꺼기 파일 초기화
rm -f "$NOTICE_MESSAGES_TEMP_FILE"
touch "$NOTICE_MESSAGES_TEMP_FILE"

##
# 사용자에게 전달할 메시지를 저장합니다.
#
# @param $1 {string} 저장할 메시지
# @param $2 {string} 중복인 경우 추가 여부. (기본값: true / true: 중복이어도 추가, false: 중복이면 무시)
#
# @return 없음
##
_add_notice() {
  local msg="$1"
  local forced="${2:-true}"

  # 메시지가 비어있으면 무시
  if [ -z "$msg" ]; then
    return 0
  fi

  # forced=false 인 경우: 파일 내에 중복된 줄이 있는지 grep으로 검사
  if [[ "$forced" == "false" ]]; then
    # grep -F: 정규식이 아닌 단순 문자열 매칭, -x: 라인 전체가 정확히 일치, -q: 결과 출력 생략(조용히)
    if grep -Fxq "$msg" "$NOTICE_MESSAGES_TEMP_FILE" 2>/dev/null; then
      return 0 # 이미 존재하면 함수 종료
    fi
  fi

  # 파일에 메시지 누적 (Append)
  echo "$msg" >> "$NOTICE_MESSAGES_TEMP_FILE"
}

##
# 저장된 모든 공지 메시지를 출력합니다.
#
# @param 없음
#
# @return 저장된 메시지 목록 (표준 출력)
##
_announce_notices() {
  # 공지사항 파일이 존재하지 않거나 내용이 비어있는 경우(-s) 종료
  if [ ! -s "$NOTICE_MESSAGES_TEMP_FILE" ]; then
    return 0
  fi

  echo
  echo "================================================================================"
  echo "[공지] 작업 완료 후 확인이 필요한 메시지"
  echo "================================================================================"
  
  local idx=1
  # 파일에서 한 줄씩 안전하게 읽어와 출력 (IFS= 및 -r 옵션으로 공백/백슬래시 원형 유지)
  while IFS= read -r msg || [ -n "$msg" ]; do
    # 기존에 구성하신 포맷과 색상 출력 함수(echo_w) 그대로 사용
    echo_w " [$(printf "%-3d" "$idx")] $msg"   
    (( idx++ ))
  done < "$NOTICE_MESSAGES_TEMP_FILE"
  
  echo "================================================================================"
  
  # 출력이 모두 끝난 후 시스템 정리를 위해 임시 파일 삭제
  rm -f "$NOTICE_MESSAGES_TEMP_FILE"
}

##
# 도움말을 출력합니다.
#
# @param $1 {string} 오류 원인 메시지 (선택)
# @param $2 {string} 오류 발생 라인 번호 (선택)
#
# @return 도움말 포맷 출력 (표준 출력)
##
help(){
  if [ -n "$1" ]; then
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
  echo "  ./$FILENAME"
  echo ""
  echo " - 설치가능한 옵션은 설치하려는 '카탈로그'가 제공하는 옵션에 따라서 안내됩니다."
  echo "   아래 내용은 설치가능한 모든 옵션 정보입니다."
  echo ""
  echo " [옵션]"
  echo "  --all               : 모든 옵션을 적용합니다."
  echo "  --add-sudoers       : 특정 사용자를 'sudoers'에 추가합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --custom-tools      : 사용자 정의 도구를 설치합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --custom-installers : 사용자 정의 설치 스크립트를 실행합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --remove-packages   : 사용하지 않을 패키지를 삭제합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --install-packages  : 기본 패키지를 설치합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --ssh-key           : 설정한 RSA 공개키를 authorized_keys에 등록합니다. '--no-default-opts'이 자동으로 적용됩니다."
  echo "  --no-default-opts   : 기본 옵션을 설치하지 않습니다."
  echo "                        - _setup_home_bin: $HOME\bin 경로를 \$PATH에 추가하기."
  echo "                        - _setup_git_prompt: 사용자 정의 프롬프트 적용하기. (git branch 추가)"
  echo "                        - _install_vim_options: 사용자 활성화 옵션 적용하기."
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h | --help)
      help
      exit 0
      ;;
  esac
done

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
# 전역 변수: 패키지 매니저 환경 자동 판별
# ==========================================
PKG_MANAGER=""
PKG_UPDATE_CMD=""
PKG_INSTALL_CMD=""
PKG_REMOVE_CMD=""

if command -v apt &> /dev/null; then
  PKG_MANAGER="apt"
  PKG_UPDATE_CMD="sudo apt update"
  PKG_INSTALL_CMD="sudo apt install -y"
  PKG_REMOVE_CMD="sudo apt purge -y"
elif command -v dnf &> /dev/null; then
  PKG_MANAGER="dnf"
  PKG_UPDATE_CMD="sudo dnf makecache"
  PKG_INSTALL_CMD="sudo dnf install -y"
  PKG_REMOVE_CMD="sudo dnf remove -y"
else
  echo "[❌] 지원하지 않는 운영체제입니다. (apt 또는 dnf가 필요합니다.)"
  exit 1
fi

##
# OS별 패키지 매니저를 통해 실제 패키지가 설치되어 있는지 확인합니다.
#
# @param $1 {string} 패키지 이름
#
# @return 0(설치됨) 또는 1(설치 안 됨)
##
_is_package_installed() {
  local pkg_name="$1"
  if [ "$PKG_MANAGER" == "apt" ]; then
    # Ubuntu/Debian: dpkg를 통해 상태가 'install ok installed' 인지 확인
    dpkg -s "$pkg_name" 2>/dev/null | grep -q "Status: install ok installed"
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    # Rocky/RHEL: rpm -q 를 통해 설치 여부 확인 (매우 빠름)
    rpm -q "$pkg_name" &>/dev/null
  else
    return 1
  fi
}

# ==========================================
# 외부 설정 파일(Properties) 다운로드 및 로드
# ==========================================
if ! _is_package_installed "curl"; then
  $PKG_UPDATE_CMD > /dev/null 2>&1
  $PKG_INSTALL_CMD curl > /dev/null 2>&1
fi

# ==============================================================================
# 카탈로그 INI 파싱 및 동적 테이블 생성/선택 테스트 스크립트
# ==============================================================================

# 1. 데이터 저장을 위한 연관 배열 및 변수
declare -a CATALOG_SECTIONS=()
declare -A CATALOG_TITLE=()
declare -A CATALOG_DESC=()
declare -A CATALOG_URL=()

MAX_TITLE_WIDTH=4 # '제목' 기본 너비 (한글 2글자 = 4)
MAX_DESC_WIDTH=4  # '설명' 기본 너비 (한글 2글자 = 4)

# ==============================================================================
# [유틸리티] 한글/영문 혼용 문자열의 실제 터미널 출력 너비 계산 및 패딩
# ==============================================================================
# 문자열의 터미널 출력 너비 계산 (한글=2, 영문/숫자/기호=1)
_get_display_width() {
  local str="$1"
  local width=0
  local i char

  for (( i=0; i<${#str}; i++ )); do
    char="${str:$i:1}"
    # ASCII 범위(영문, 숫자, 기본 기호 및 공백)는 1칸, 그 외(한글 등)는 2칸으로 계산
    if [[ "$char" == [a-zA-Z0-9\ \!\@\#\$%\^\&\*\(\)\_\+\-\=\[\]\{\}\;\:\'\"\,\.\<\>\/\?\`\~\|\\] ]]; then
      ((width++))
    else
      ((width+=2))
    fi
  done
  echo "$width"
}

# 지정된 너비만큼 공백을 채워 문자열 반환 (좌측 정렬용)
_pad_string() {
  local str="$1"
  local target_width="$2"
  local current_width=$(_get_display_width "$str")
  local spaces=$(( target_width - current_width ))
  
  echo -n "$str"
  for (( i=0; i<spaces; i++ )); do
    echo -n " "
  done
}

# ==============================================================================
# [로직 1] INI 파일 파싱 및 최대 너비 계산
# ==============================================================================
parse_ini_catalog() {
  local ini_file="$1"
  local cur_sec=""

  if [[ ! -f "$ini_file" ]]; then
    echo "[❌] $ini_file 파일을 찾을 수 없습니다."
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 양옆 공백 제거
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # 주석(#, ;) 및 빈 줄 무시
    [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^\; ]] && continue

    # [섹션] 파싱
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
      cur_sec="${BASH_REMATCH[1]}"
      CATALOG_SECTIONS+=("$cur_sec")
      continue
    fi

    # key=value 파싱
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      local current_val_width=$(_get_display_width "$val")
      
      case "$key" in
        title)
          CATALOG_TITLE["$cur_sec"]="$val"
          (( current_val_width > MAX_TITLE_WIDTH )) && MAX_TITLE_WIDTH=$current_val_width
          ;;
        description)
          CATALOG_DESC["$cur_sec"]="$val"
          (( current_val_width > MAX_DESC_WIDTH )) && MAX_DESC_WIDTH=$current_val_width
          ;;
        catalog_url)
          CATALOG_URL["$cur_sec"]="$val"
          ;;
      esac
    fi
  done < "$ini_file"
}

# ==============================================================================
# [로직 2] 동적 ASCII 테이블 렌더링
# ==============================================================================
_print_border() {
  # '#'(3) + 양옆 여백(2씩) + 구분선 4개 = 기본 13칸
  local total_len=$(( 13 + MAX_TITLE_WIDTH + MAX_DESC_WIDTH ))
  for (( i=0; i<total_len; i++ )); do echo -n "-"; done
  echo
}

show_catalog_table() {
  echo
  _print_border
  # 헤더 출력
  echo -n "|  #  | "
  _pad_string "제목" "$MAX_TITLE_WIDTH"
  echo -n " | "
  _pad_string "설명" "$MAX_DESC_WIDTH"
  echo " |"
  _print_border

  # 내용 출력
  local idx=1
  for sec in "${CATALOG_SECTIONS[@]}"; do
    printf "| %3d | " "$idx"
    _pad_string "${CATALOG_TITLE[$sec]}" "$MAX_TITLE_WIDTH"
    echo -n " | "
    _pad_string "${CATALOG_DESC[$sec]}" "$MAX_DESC_WIDTH"
    echo " |"
    ((idx++))
  done
  _print_border
  echo
}

# ==============================================================================
# [로직 3] 사용자 상호작용 (번호 선택, 검증, 취소 및 진행)
# ==============================================================================
select_catalog() {
  local total_items=${#CATALOG_SECTIONS[@]}
  local interrupted=0

  while true; do
    show_catalog_table

    interrupted=0
    trap 'interrupted=1' SIGINT
    
    local choice=""
    echo -n "> 🛠️ 설치할 카탈로그 번호를 선택하세요 (1-$total_items) [취소: Ctrl+C 후 'Enter']: " >&2
    read -r choice
    
    trap - SIGINT

    # 1. Ctrl + C 처리
    if [[ "$interrupted" -eq 1 ]]; then
      echo_w " - [🛑] 카탈로그 선택을 종료합니다." >&2
      return 1
    fi

    # 2. 유효성 검사 (숫자인지, 범위 내인지)
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > total_items )); then
      echo_w "⚠️ - 잘못된 번호입니다. 1에서 $total_items 사이의 숫자를 입력해주세요." >&2
      continue
    fi

    # 3. 정상 선택 처리
    local selected_index=$(( choice - 1 ))
    local selected_sec="${CATALOG_SECTIONS[$selected_index]}"
    local selected_title="${CATALOG_TITLE[$selected_sec]}"
    local selected_desc="${CATALOG_DESC[$selected_sec]}"
    local selected_url="${CATALOG_URL[$selected_sec]}"

    echo -e "\n▶  선택하신 환경: \033[1;36m$selected_title\033[0m" >&2
    echo -e "▶  상세 설명    : $selected_desc" >&2
    echo -e "▶  catalog_url  : $selected_url\n" >&2

    # 설치 여부 확인
    local confirm=""
    trap 'interrupted=1' SIGINT
    echo -n "> 위 환경을 설치하시겠습니까? (y/n) [취소: Ctrl+C 후 'Enter']: " >&2
    read -r confirm
    trap - SIGINT

    if [[ "$interrupted" -eq 1 ]]; then
      echo_w " - [🛑] 설치 단계를 취소합니다." >&2
      return 1
    fi

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo_i "[🛠️] 설치를 진행합니다!" >&2
      
      # 향후 setup-env.sh 통합 시, 여기서 추출된 URL을 전역 변수에 저장하거나 
      # 설정을 다운로드하는 함수를 호출하시면 됩니다.
      export SELECTED_CATALOG_URL="$selected_url"
      return 0
    else
      echo_w " - 설치를 취소했습니다. 다시 목록에서 선택해 주세요.\n" >&2
      # 다시 표를 보여줄지 여부는 기호에 맞게 조정 (여기선 표는 생략하고 다시 프롬프트로)
      continue
    fi
  done
}

##
# 카탈로그 정의 파일 다운로드
##
CATALOGS_INI_URL="https://github.com/parkjunhong/shellscripts/raw/refs/heads/main/env/catalogs.ini"
CATALOGS_FILE="/tmp/catalogs.ini"
if ! curl -sfLo "$CATALOGS_FILE" "$CATALOGS_INI_URL"; then
  echo
  echo_e "[❌] 카탈로그 정의 파일($CATALOGS_INI_URL)이 존재하지 않아 다운로드할 수 없습니다."
  echo_e "[❌] 설치를 취소합니다."
  rm -f -- "$CATALOGS_FILE"
  exit 1
fi

# 카탈로그 분석
parse_ini_catalog "$CATALOGS_FILE"
# 카탈로그 선택
select_catalog
RET_VAL=$?  # 함수의 반환값(return 0 또는 1)을 변수에 저장

# 임시 카탈로그 파일 삭제
rm -f -- "$CATALOGS_FILE"

# 3. 반환값 검증 및 분기
if [[ $RET_VAL -ne 0 ]]; then
  # 반환값이 0이 아니면(취소했거나 에러인 경우) 즉시 스크립트 종료
  echo
  echo_w "[🛠 ] 사용자가 카탈로그 설치를 취소했습니다."
  echo_w "종료합니다."
  exit 0
fi

# 외부 설정 파일 다운로드
CONFIG_FILE="/tmp/configurations.properties"
# ---------------------------------------------------------
# curl -f 옵션 추가 및 예외 처리 완화
# 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
# 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
# ---------------------------------------------------------
if ! curl -sfLo "$CONFIG_FILE" "$SELECTED_CATALOG_URL"; then
  echo
  echo_e "[❌] 외부 설정 파일($SELECTED_CATALOG_URL)이 존재하지 않아 다운로드할 수 없습니다."
  echo_e "[❌] 설치를 취소합니다."
  rm -f -- "$CONFIG_FILE"
  exit 1
fi 

# ---------------------------------------------------------
# Properties 파일을 가장 안전하게 파싱하여 변수로 등록
# - 쌍따옴표("), 따옴표('), 공백, 특수문자($) 등이 있어도 오류가 나지 않음
# - [보안] Whitelist 방식을 적용하여 시스템 변수 오염(Environment Injection) 완벽 방지
# ---------------------------------------------------------
while IFS='=' read -r key value || [ -n "$key" ]; do
  # 주석(#)이거나 빈 줄이면 건너뛰기
  if [[ "$key" =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
    continue
  fi

  # Key와 Value의 양옆 공백 제거 (Value 내부의 띄어쓰기는 그대로 유지됨)
  key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')  
  value=$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # 일반 변수만 처리 (배열 식별용 점(.)이 포함된 키는 제외)
  if [[ ! "$key" =~ \. ]]; then    
    # [보안 처리] 허용된 변수명 패턴만 등록 (URL_로 시작하거나 특정 키워드인 경우)
    #if [[ "$key" =~ ^(URL_[A-Z0-9_]+|NO_PASSWORD_COMMANDS|INSTALL_PACKAGES|REMOVE_PACKAGES)$ ]]; then      
      # export 대신 declare -g 를 사용하여 현재 스크립트 실행 범위 내에서만 변수 등록
    declare -g "$key"="$value"      
    #else
      #echo " - [보안 경고] 허용되지 않은 키명($key)은 시스템 보호를 위해 무시됩니다."
    #fi
  fi
done < "$CONFIG_FILE"

# 1. 다중 사용자 정의 도구 URL 파싱 및 배열에 담기
CUSTOM_TOOL_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*URL_CUSTOM_TOOL\. ]] && CUSTOM_TOOL_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

# 2. 다중 사용자 설치 스크립트 URL 파싱 및 배열에 담기
CUSTOM_INSTALLER_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*URL_CUSTOM_INSTALLER\. ]] && CUSTOM_INSTALLER_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

# 3. 다중 사용자 실행 명령어 파싱 및 배열에 담기
CUSTOM_COMMAND_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*URL_CUSTOM_COMMAND\. ]] && CUSTOM_COMMAND_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

# 3. 다중 RSA 공개키 설정 파싱 및 배열에 담기
RSA_PUBLIC_KEY_LIST=()
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^[[:space:]]*RSA_PUBLIC_KEY\. ]] && RSA_PUBLIC_KEY_LIST+=("$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")
done < "$CONFIG_FILE"

# 임시 외부설정파일 삭제
rm -f -- "$CONFIG_FILE"

# ==============================================================================
# 카탈로그 데이터 기반 동적 설치 옵션 메뉴 생성
# ==============================================================================

# 1. 사용 가능한 옵션과 설명을 담을 연관 배열 선언
declare -A OPT_DESCRIPTIONS=()
declare -a AVAILABLE_OPTS=() # 실제 출력할 옵션 순서를 보장하기 위한 배열

# 2. 각 항목별 검증 및 유효 옵션 등록
if [[ -n "$REMOVE_PACKAGES" ]]; then
  AVAILABLE_OPTS+=("--remove-packages")
  OPT_DESCRIPTIONS["--remove-packages"]="사용하지 않을 패키지를 삭제합니다. '--no-default-opts'이 자동으로 적용됩니다."
fi

if [[ -n "$NO_PASSWORD_COMMANDS" ]]; then
  AVAILABLE_OPTS+=("--add-sudoers")
  OPT_DESCRIPTIONS["--add-sudoers"]="특정 사용자를 'sudoers'에 추가합니다. '--no-default-opts'이 자동으로 적용됩니다."
fi

if [[ -n "$INSTALL_PACKAGES" ]]; then
  AVAILABLE_OPTS+=("--install-packages")
  OPT_DESCRIPTIONS["--install-packages"]="기본 설치 도구 패키지를 설치합니다."
fi

if (( ${#CUSTOM_TOOL_LIST[@]} > 0 )); then
  AVAILABLE_OPTS+=("--custom-tools")
  OPT_DESCRIPTIONS["--custom-tools"]="사용자 정의 도구를 다운로드 및 설치합니다. '--no-default-opts'이 자동으로 적용됩니다."
fi

if (( ${#CUSTOM_INSTALLER_LIST[@]} > 0 )); then
  AVAILABLE_OPTS+=("--custom-installers")
  OPT_DESCRIPTIONS["--custom-installers"]="사용자 정의 설치 스크립트를 실행합니다. '--no-default-opts'이 자동으로 적용됩니다."
fi

if (( ${#CUSTOM_COMMAND_LIST[@]} > 0 )); then
  AVAILABLE_OPTS+=("--custom-commands")
  OPT_DESCRIPTIONS["--custom-commands"]="사용자 정의 명령어를 실행합니다. '--no-default-opts'이 자동으로 적용됩니다."
fi

if (( ${#RSA_PUBLIC_KEY_LIST[@]} > 0 )); then
  AVAILABLE_OPTS+=("--ssh-key")
  OPT_DESCRIPTIONS["--ssh-key"]="RSA 기반의 ssh 접속을 위한 공개키를 등록합니다."
fi

# 3. 메뉴 출력 및 사용자 입력 받기
echo
echo "========================================================"

if (( ${#AVAILABLE_OPTS[@]} == 0 )); then
  echo_w " - [💡] 선택한 카탈로그에 시스템에 적용 가능한 설치 옵션이 없습니다."
  echo "========================================================"
  rm -f -- "$CONFIG_FILE"
  exit 0
fi

echo_i "시스템에 적용 가능한 옵션은 다음과 같습니다."
echo
# 3-1. 가장 긴 옵션 이름의 길이 동적 계산
max_opt_len=5 # 기본값: "--all"의 길이
for opt in "${AVAILABLE_OPTS[@]}"; do
  if (( ${#opt} > max_opt_len )); then
    max_opt_len=${#opt}
  fi
done

# 3-2. printf 포맷팅을 활용하여 일정한 너비로 렌더링
# %-${max_opt_len}s : 변수 길이만큼 공간을 확보하고 문자열을 좌측 정렬(-) 처리
printf "  [ 0] %-${max_opt_len}s : %s\n" "--all" "모든 옵션을 적용합니다. (이 옵션을 선택하는 경우, 다른 옵션은 무시됩니다.)"

idx=1
for opt in "${AVAILABLE_OPTS[@]}"; do
  printf "  [%2d] %-${max_opt_len}s : %s\n" "$idx" "$opt" "${OPT_DESCRIPTIONS[$opt]}"
  ((idx++))
done

echo
echo "========================================================"
echo "적용하려는 옵션의 [번호]를 입력하기 바랍니다. (여러 개의 경우 띄어쓰기로 구분, 예: 1 3 4)"

read -r -p "적용 옵션 번호: " user_input_nums

if [[ -z "$user_input_nums" ]]; then
  echo_w " - [❌] 입력된 옵션이 없어 설치를 종료합니다."
  exit 0
fi

# 4. 입력받은 번호를 실제 옵션 문자열로 파싱 및 변환
parsed_opts=""
for num in $user_input_nums; do
  # 숫자가 아니거나 범위를 벗어난 입력 무시
  if [[ ! "$num" =~ ^[0-9]+$ ]] || (( num < 0 || num > ${#AVAILABLE_OPTS[@]} )); then
    echo_w "⚠️  - 무효한 번호($num)가 포함되어 있어 무시됩니다."
    continue
  fi
  
  if (( num == 0 )); then
    parsed_opts="--all"
    break # --all이 선택되면 다른 번호는 모두 무시하고 즉시 종료
  else
    opt_idx=$(( num - 1 ))
    parsed_opts="$parsed_opts ${AVAILABLE_OPTS[$opt_idx]}"
  fi
done

# 유효한 번호가 하나도 추출되지 않았을 경우 방어 로직
if [[ -z "$parsed_opts" ]]; then
  echo_w " - [🛑] 유효한 옵션이 선택되지 않아 스크립트를 종료합니다."
  exit 1
fi

# 5. 변환된 문자열을 스크립트 실행 인자($@)로 강제 덮어쓰기
eval set -- $parsed_opts

# 작업실행 여부
# 키: '함수 또는 함수+파라미터'
# 값: 1/진행, 그외/미진행
declare -A EXECUTED_JOB_FLAGS=()

##
# 사용자의 홈 디렉토리에 bin 디렉토리를 생성하고, PATH 환경변수에 등록합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_home_bin() {
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo
  echo "############### $func_name ###############"
  echo "[✨] $HOME/bin 디렉토리 설정 중..."
  local bin_dir="$HOME/bin"
  if [ ! -d "$bin_dir" ]; then
    mkdir -p "$bin_dir" || error_exit "~/bin 디렉토리 생성 실패" "$LINENO"
    echo_i " - ~/bin 디렉토리를 생성했습니다."
  fi
  if ! grep -q "PATH=\$PATH:$bin_dir" "$HOME/.bashrc"; then
    echo "PATH=\$PATH:$bin_dir" >> "$HOME/.bashrc" || error_exit "$HOME/.bashrc 파일 수정 실패" "$LINENO"
    
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
      # source(. ./setup-env.sh) 명령으로 스크립트가 실행된 경우 → 부모 쉘이므로 즉시 적용 가능
      source ~/.bashrc 2>/dev/null || true
      echo_i " - $HOME/bin -> \$PATH 경로 추가가 현재 터미널에 즉시 적용되었습니다."
    else
      # 서브 쉘(./setup-env.sh)로 실행된 경우 → 안내 메시지 출력
      echo_i " - $HOME/.bashrc 파일에 PATH 설정에 '$HOME/bin' 을 추가했습니다."
      echo_w " - 현재 터미널에 즉시 반영하려면 다음 명령을 실행하세요:"
      echo_w "   source ~/.bashrc"
      echo_w " - 또는 새 터미널을 열면 적용됩니다."
      
      _add_notice "### $HOME/bin -> \$PATH 추가 작업 ###"
      _add_notice " - $HOME/.bashrc 파일에 PATH 설정에 '$HOME/bin' 을 추가했습니다." false
      _add_notice " - 현재 터미널에 즉시 반영하려면 다음 명령을 실행하세요:" false
      _add_notice "   source ~/.bashrc" false
    fi
  else
    echo_w " - ~/.bashrc 파일에 이미 PATH 설정이 존재합니다."
  fi

  EXECUTED_JOB_FLAGS["$func_name"]=1
}

##
# .bashrc 파일에 현재 위치의 git branch를 표시하는 프롬프트(PS1) 설정을 추가합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_setup_git_prompt() {
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo
  echo "############### $func_name ###############"
  echo "[✨] git branch 프롬프트 설정 중..."
  if ! grep -q "parse_git_branch()" "$HOME/.bashrc"; then
    cat << 'EOF' >> "$HOME/.bashrc" || error_exit "~/.bashrc 파일 수정 실패" "$LINENO"

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /' 
}

PS1='[directory] \[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]\n[\t ] \[\033[01;32m\]\u@\h\[\033[00m\]:$ '
EOF
    echo_i " - ~/.bashrc에 프롬프트 설정을 추가했습니다."
  else
    echo_w " - ~/.bashrc 파일에 이미 git 프롬프트 설정이 존재합니다."
  fi
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
}

##
# 스크립트 실행 중 1번만 OS에 맞는 패키지 매니저 업데이트를 실행하도록 보장합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_try_pkg_update() {
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo "############### $func_name ###############"
  echo "[✨] 패키지 인덱스 업데이트 중 ($PKG_MANAGER)..."
  
  if $PKG_UPDATE_CMD; then
    EXECUTED_JOB_FLAGS["$func_name"]=1
  else
    echo_w "❌ 패키지 인덱스 업데이트에 실패했습니다."
    return 1
  fi
}

##
# OS에 맞는 패키지 매니저로 설치를 진행합니다.
# 설치에 실패하더라도 전체 스크립트를 중단하지 않고 로그를 남긴 후 다음으로 넘어갑니다.
#
# @param $1 {string} 패키지 이름
#
# @return 성공 시 0, 실패 시 1
##
_install_package() {
  local func_name="${FUNCNAME[0]}"
  local package_name="$1"
  local flag="${EXECUTED_JOB_FLAGS[$func_name.$package_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi

  # [개선] OS 패키지 매니저를 통한 정확한 설치 여부 확인
  if ! _is_package_installed "$package_name"; then  
    echo "[✨] '$package_name' 설치 중..."
    
    # [수정] error_exit을 제거하고 예외 처리 분기 추가
    if ! $PKG_INSTALL_CMD "$package_name"; then
      echo_e " - [ERROR] '$package_name' 패키지 설치 중 오류가 발생하여 설치를 건너뜁니다."
      
      # 작업 완료 후 출력되는 공지사항(NOTICE)에 실패 내역 추가
      _add_notice " - [$func_name] [ERROR] '$package_name' 패키지 설치 실패 (수동 확인 필요)"
      
      return 1 # 실패 상태 코드로 반환하되, 스크립트 실행은 계속됨
    fi

    echo_i " - '$package_name' 설치가 완료되었습니다."
    EXECUTED_JOB_FLAGS["$func_name.$package_name"]=1
  else
    echo_w " - '$package_name' 패키지가 이미 설치되어 있습니다."
    EXECUTED_JOB_FLAGS["$func_name.$package_name"]=1
  fi
  
  return 0
}

##
# OS에 맞는 패키지 매니저로 삭제를 진행합니다.
#
# @param $1 {string} 패키지 이름
#
# @return 진행 상황 메시지 (표준 출력)
##
_remove_package(){
  local func_name="${FUNCNAME[0]}"
  local package_name="$1"
  local flag="${EXECUTED_JOB_FLAGS[$func_name.$package_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi

  # [개선 및 논리버그 수정] 패키지가 실제로 설치되어 있을 때만(!) 삭제 진행
  if _is_package_installed "$package_name"; then  
    echo "[✨] '$package_name' 제거 중..."

    $PKG_REMOVE_CMD "$package_name" || error_exit "'$package_name' 제거 실패" "$LINENO"

    EXECUTED_JOB_FLAGS["$func_name.$package_name"]=1
  else
    echo_w " - '$package_name' 패키지가 시스템에 존재하지 않아 제거를 건너뜁니다."
    EXECUTED_JOB_FLAGS["$func_name.$package_name"]=1
  fi
}

##
# 기본적으로 설치된 도구 중에 사용하지 않는 것을 제거합니다.
## 
remove_packages(){
  if [ -z "${REMOVE_PACKAGES}" ]; then
    echo ""
    echo_w "⚠️  '삭제할 패키지' 목록이 존재하지 않습니다."
    return 0
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi

  echo
  echo "############### $func_name ###############"
  IFS=',' read -ra PKGS <<< "$REMOVE_PACKAGES"
  for pkg in "${PKGS[@]}"; do
    pkg=$(echo "$pkg" | xargs) # 양옆 공백 제거
    _remove_package "$pkg"
  done
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
}


##
# 외부 설정파일의 INSTALL_PACKAGES를 읽어 공통 설치 함수를 통해 설치합니다.
##
install_packages() {
  if [ -z "${INSTALL_PACKAGES}" ]; then
    echo ""
    echo_w "⚠️  '설치할 패키지' 목록이 존재하지 않습니다."
    return 0
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi

  echo
  echo "############### $func_name ###############"
  IFS=',' read -ra PKGS <<< "$INSTALL_PACKAGES"
  for pkg in "${PKGS[@]}"; do
    pkg=$(echo "$pkg" | xargs) # 양옆 공백 제거
    _install_package "$pkg"
  done
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
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

  # [수정] elif를 독립된 if문으로 분리하여 논리적 꼬임 방지
  if [ -z "$comp_dir" ] && [ -d "/usr/share/bash-completion/completions" ]; then
    comp_dir="/usr/share/bash-completion/completions"
  fi
  
  if [ -z "$comp_dir" ] && [ -d "/etc/bash_completion.d" ]; then
    comp_dir="/etc/bash_completion.d"
  fi

  if [ -z "$comp_dir" ]; then
    echo "⚠️ - bash-completion 경로를 찾지 못했습니다. 임시로 /etc/bash_completion.d를 생성합니다."
    comp_dir="/etc/bash_completion.d"
    sudo mkdir -p "$comp_dir"
  fi
  # ========================================================

  local temp_comp="/tmp/${target_cmd}.completion"  
  
  # ---------------------------------------------------------
  # [개선] curl -f 옵션 추가 및 예외 처리 완화
  # 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
  # 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
  # ---------------------------------------------------------
  if ! curl -sfLo "$temp_comp" "$comp_url"; then
    echo_w " - [💡] '${target_cmd}'의 bash completion 파일이 존재하지 않아 설치를 생략합니다."
    rm -f -- "$temp_comp"
    return 0
  fi
  
  # 구형 폴더면 .completion 확장자 유지, 신형 표준 폴더면 명령어 이름과 정확히 일치시킴
  local target_comp_file="$comp_dir/$target_cmd"
  if [[ "$comp_dir" == *"/etc/bash_completion.d"* ]]; then
      target_comp_file="$comp_dir/${target_cmd}.completion"
  fi

  # [수정] 설치 성공 여부를 추적하는 플래그
  local installed=0

  if [ -f "$target_comp_file" ]; then
    if ! cmp -s "$temp_comp" "$target_comp_file"; then
      # [수정] 백슬래시 이스케이프 방지를 위한 -r 옵션 추가
      local ch
      read -r -p "> '${target_cmd} completion' 내용이 다릅니다. 업데이트하시겠습니까? (y/n): " ch
      if [[ "$ch" == "y" || "$ch" == "Y" ]]; then
        # [수정] mv 실패 시 임시 파일 삭제 및 에러 처리
        sudo mv "$temp_comp" "$target_comp_file" || { rm -f -- "$temp_comp"; error_exit "'${target_cmd} completion' 파일 업데이트 실패" "$LINENO"; }
        echo_i " - '${target_cmd} completion' 파일이 업데이트되었습니다."
        installed=1
      else
        echo_w " - '${target_cmd} completion' 파일 설치를 유지합니다."
        rm -f -- "$temp_comp"
      fi
    else
      echo_w " - '${target_cmd} completion' 파일이 이미 최신입니다."
      rm -f -- "$temp_comp"
    fi
  else
    # [수정] mv 실패 시 임시 파일 삭제 및 에러 처리
    sudo mv "$temp_comp" "$target_comp_file" || { rm -f -- "$temp_comp"; error_exit "'${target_cmd} completion' 파일 설치 실패" "$LINENO"; }
    echo_i " - '${target_cmd} completion' 파일을 설치했습니다."
    installed=1
  fi
  
  # ========================================================
  # Bash Completion 현재 쉘 적용 여부 결정 (실행 방식 감지)
  # ========================================================
  if (( installed == 1 )) && [ -f "$target_comp_file" ]; then
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
      # source(. ./setup-env.sh) 명령으로 스크립트가 실행된 경우 → 부모 쉘이므로 즉시 적용 가능
      source "$target_comp_file" 2>/dev/null || true
      echo_i " - [🛠 ] '${target_cmd}' 자동완성이 현재 터미널에 즉시 적용되었습니다."
    else
      # 서브 쉘(./setup-env.sh)로 실행된 경우 → 안내 메시지 출력
      echo_w " - [💡] '${target_cmd}' 자동완성을 현재 터미널에 즉시 적용하려면 아래 명령을 실행하세요:"
      echo_w "   source \"$target_comp_file\""
      
      _add_notice "### ${target_cmd} 자동완성 추가 작업 ###"
      _add_notice " - 현재 터미널에 즉시 적용하려면 아래 명령을 실행하세요:" 
      _add_notice "   source \"$target_comp_file\""
    fi
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
  local func_name="${FUNCNAME[0]}"
  local tool_url="$1"
  local target_cmd=$(basename "$tool_url")
  
  echo
  echo "############### $func_name - $target_cmd ###############"
  echo "[✨] '$target_cmd' 설치 중..."
  local bin_dir="$HOME/bin"
  local temp_bin="/tmp/${target_cmd}"
  
  # ---------------------------------------------------------
  # curl -f 옵션 추가 및 예외 처리 완화
  # 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
  # 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
  # ---------------------------------------------------------
  if ! curl -sfLo "$temp_bin" "$tool_url"; then
    echo_e " - [❌] '사용자 정의 도구파일' 다운로드 실패"
    echo_e " - [❌] '${target_cmd}' 파일이 존재하지 않아 설치를 생략합니다."
    rm -f -- "$temp_bin"
    
    _add_notice " - [$func_name] [❌] '사용자 정의 도구파일' 다운로드 실패"
    _add_notice " - [$func_name] [❌] '${target_cmd}' 파일이 존재하지 않아 설치를 생략합니다."
    return 0
  fi
  
  if [ -f "$bin_dir/$target_cmd" ]; then
    if ! cmp -s "$temp_bin" "$bin_dir/$target_cmd"; then
      read -r -p "> '$target_cmd' 실행 파일 내용이 다릅니다. 업데이트하시겠습니까? (y/n): " ch
      if [[ "$ch" == "y" || "$ch" == "Y" ]]; then
        mv "$temp_bin" "$bin_dir/$target_cmd" && chmod +x "$bin_dir/$target_cmd"
        echo_i " - '$target_cmd' 실행 파일이 업데이트되었습니다."
      else
        echo_w " - '$target_cmd' 실행 파일 설치를 유지합니다."
        rm -f -- "$temp_bin"
      fi
    else
      echo_w " - '$target_cmd' 실행 파일이 이미 최신입니다."
      rm -f -- "$temp_bin"
    fi
  else
    mkdir -p "$bin_dir" && mv "$temp_bin" "$bin_dir/$target_cmd" && chmod +x "$bin_dir/$target_cmd"
    echo_i " - '$target_cmd' 실행 파일을 설치했습니다."
  fi

  # 공통 함수를 호출하여 completion 다운로드 및 설치 위임 (URL은 tool_url.completion 규칙 적용)
  local completion_url="${tool_url}.completion"
  _install_completion "$completion_url" "$target_cmd"
}

##
# 외부 설정파일의 URL_CUSTOM_TOOL.<식별자> 패턴을 읽어 다수의 사용자 정의 도구를 순차적으로 설치합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_custom_tools() {
  if [ ${#CUSTOM_TOOL_LIST[@]} -lt 1 ]; then  
    echo ""
    echo_w "⚠️  '설정된 커스텀 도구'가 존재하지 않습니다."
  fi

  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  for tool_url in "${CUSTOM_TOOL_LIST[@]}"; do
    if [ -n "$tool_url" ]; then
      _install_custom_tools "$tool_url"
    fi
  done
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
}

##
# 사용자 정의 'installer' 파일을 다운로드하고 설치합니다.
#
# @param $1 사용자 정의 'installer' URL
#
# @return 진행 상황 메시지 (표준 출력)
##
_execute_custom_script() {
  local func_name="${FUNCNAME[0]}"
  local script_url="$1"
  local target_cmd
  target_cmd=$(basename "$script_url")
  # URL을 MD5 해시로 변환하여 고유값으로 사용
  # - URL의 특수문자(/, :, . 등) 문제 완전 회피
  # - 어떤 URL이든 32자 고정 길이의 안전한 키 생성
  local url_hash
  url_hash=$(printf '%s' "$script_url" | md5sum | cut -d' ' -f1)
  local job_flag="$func_name-$url_hash"
  
  local flag="${EXECUTED_JOB_FLAGS[$job_flag]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo
  echo "############### $func_name - $target_cmd ###############"
  echo "[✨] '$target_cmd' 설치 중..."
  
  # ---------------------------------------------------------
  # [보안 0] HTTPS URL만 허용 (평문 전송 및 로컬 경로 차단)
  # ---------------------------------------------------------
  if [[ "$script_url" != https://* ]]; then
    echo_e " - [❌] HTTPS URL만 허용됩니다: $script_url"
    _add_notice " - [$func_name] [❌] HTTPS가 아닌 URL은 허용되지 않습니다: $script_url"
    return 1
  fi
  
  local temp_script="/tmp/${url_hash}"
  # ---------------------------------------------------------
  # curl -f 옵션 추가 및 예외 처리 완화
  # 1. -f 옵션: 404 등 서버 에러 시 다운로드를 실패 처리함
  # 2. || 구문: 파일이 없을 경우 전체 스크립트를 중단하지 않고 설치만 건너뜀
  # ---------------------------------------------------------  
  if ! curl -sfLo "$temp_script" "$script_url"; then
    echo_e " - [❌] '사용자 정의 'installer' 파일' 다운로드 실패 ($script_url)"
    echo_e " - [❌] '${target_cmd}' 파일이 존재하지 않아 설치를 생략합니다."
    rm -f -- "$temp_script"
    
    _add_notice " - [$func_name] [❌] '사용자 정의 설치파일' 다운로드 실패"
    _add_notice " - [$func_name] [❌] '${target_cmd}' 파일이 존재하지 않아 설치를 생략합니다."
    return 0
  fi
  
  # ---------------------------------------------------------
  # [보안 1] 다운로드 파일 무결성 검증
  # ---------------------------------------------------------
  if [ ! -s "$temp_script" ]; then
    echo_e " - [❌] 다운로드된 파일이 비어 있습니다."
    rm -f -- "$temp_script"
    return 1
  fi

  # file 명령어가 설치되어 있는 경우에만 쉘 스크립트/텍스트 여부 검사
  if command -v file &> /dev/null; then
    local file_type
    file_type=$(file -b "$temp_script") # -b 옵션으로 파일명 출력 제외
    if [[ "$file_type" != *"shell script"* && "$file_type" != *"text"* ]]; then
      echo_e " - [❌] 다운로드된 파일이 쉘 스크립트가 아닙니다: $file_type"
      rm -f -- "$temp_script"
      return 1
    fi
  fi

  # ---------------------------------------------------------
  # [보안 2] /tmp 심볼릭 링크 공격 방지
  # ---------------------------------------------------------
  if [ -L "$temp_script" ]; then
    echo_e " - [❌] 심볼릭 링크가 감지되었습니다. 실행을 중단합니다."
    rm -f -- "$temp_script"
    return 1
  fi

  # ---------------------------------------------------------
  # [보안 3] 실행 권한은 소유자만 제한
  # ---------------------------------------------------------
  chmod 700 "$temp_script"

  # ---------------------------------------------------------
  # [보안 4 & 5] 자식 프로세스(Subshell)를 통한 실행 및 결과 검증
  # (주의: 커스텀 스크립트가 부모의 환경변수를 써야하므로 env -i는 제외)
  # ---------------------------------------------------------
  echo_i " - '$target_cmd' 실행 중..."
  
  # 자식 스크립트에서 사용할 수 있도록 부모의 변수와 함수를 명시적으로 상속(Export)
  export -f _add_notice                 # 자식에서 쓸 _add_notice 함수 상속
  export -f error_exit                  # (선택) 자식 스크립트에서 중복 정의할 필요 없이 부모 것 재사용 가능
  export -f echo_e echo_w echo_i # (선택) 색상 출력 함수 재사용 가능

  # 명시적인 /bin/bash 호출로 자식 프로세스에서 안전하게 실행
  if ! /bin/bash "$temp_script"; then
    local exit_code=$?
    echo_e " - [❌] '$target_cmd' 실행 실패 (exit code: $exit_code)"
    rm -f -- "$temp_script"
    
    _add_notice " - [$func_name] [❌] '$target_cmd' 실행 실패 (exit code: $exit_code)"
    return 1
  fi
  
  # 임시 파일 삭제 및 성공 처리
  rm -f -- "$temp_script"
  echo_i " - [🛠 ] '$target_cmd' 실행이 완료되었습니다."
  
  EXECUTED_JOB_FLAGS["$job_flag"]=1
  return 0
}

##
# 외부 설정파일의 URL_CUSTOM_INSTALLER.<식별자> 패턴을 읽어 다수의 사용자 정의 도구를 순차적으로 설치합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_custom_installers() {
  if [ ${#CUSTOM_INSTALLER_LIST[@]} -lt 1 ]; then
    echo ""
    echo_w "⚠️  '설정된 커스텀 installer'가 존재하지 않습니다."
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  for installer_url in "${CUSTOM_INSTALLER_LIST[@]}"; do
    if [ -n "$installer_url " ]; then
      _execute_custom_script "$installer_url"
    fi
  done
    
  EXECUTED_JOB_FLAGS["$func_name"]=1
}

##
# 외부 설정파일의 URL_CUSTOM_COMMAND.<식별자> 패턴을 읽어 다수의 사용자 정의 명령어를 순차적으로 실행합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_custom_commands(){
  if [ ${#CUSTOM_COMMAND_LIST[@]} -lt 1 ]; then
    echo ""
    echo_w "⚠️  '설정된 커스텀 명령어'가 존재하지 않습니다."
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  for command_url in "${CUSTOM_COMMAND_LIST[@]}"; do
    if [ -n "$command_url " ]; then
      _execute_custom_script "$command_url"
    fi
  done
    
  EXECUTED_JOB_FLAGS["$func_name"]=1

}

##
# 사용자를 sudoers 그룹에 등록하고 특정 관리 명령어들의 비밀번호 입력을 면제합니다.
# 외부설정된 NO_PASSWORD_COMMANDS 값을 활용하며, 사용자 입력을 통해 대상을 지정합니다.
# 문법 오류로 인한 sudo 불능 상태를 방지하기 위해 visudo를 통한 사전 검증을 수행합니다.
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
setup_sudoers() {
  if [ -z "${NO_PASSWORD_COMMANDS}" ]; then
    echo ""
    echo_w "⚠️  '비밀번호를 입력 받지 않는 명령어' 목록이 존재하지 않습니다."
    return 0
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"

  if (( flag == 1 )); then
    return 0
  fi

  echo
  echo "############### $func_name ###############"
  echo "[✨] 사용자 sudoers 설정 중..."

  # 1. 기본값으로 사용할 현재 접속 계정 확인
  local current_user="${USER:-$(whoami)}"
  local target_user=""
  local interrupted=0

  # 2. Ctrl+C (SIGINT) 입력 시 전체 종료를 막고 플래그만 변경하도록 트랩 설정
  trap 'interrupted=1' SIGINT

  # 3. 유효한 사용자 계정이 입력될 때까지 반복
  while true; do

    # 3-1. 사용자 입력 대기
    read -r -p "> [⌨  ] sudoers에 등록할 사용자 계정을 입력하세요 (기본값: $current_user) [취소: Ctrl+C 후 'Enter']: " target_user

    # 3-2. Ctrl+C가 눌렸을 경우 (interrupted 플래그 확인)
    if (( interrupted == 1 )); then
      echo -e "\n - [❌] sudoers 설정을 취소합니다."
      trap - SIGINT
      return 0
    fi

    # 3-3. 입력값이 비어있으면 기본값(현재 사용자)으로 설정
    if [ -z "$target_user" ]; then
      target_user="$current_user"
    fi

    # 3-4. 시스템에 존재하는 사용자인지 검증
    #        존재하지 않으면 경고 메시지 출력 후 재입력 요청
    if ! id "$target_user" &>/dev/null; then
      echo_w " - '$target_user' 사용자가 시스템에 존재하지 않습니다. 다시 입력해 주세요."
      target_user=""   # 초기화 후 루프 재시작
      continue
    fi

    # 3-5. 유효한 사용자 확인 → 루프 종료
    break
  done

  # 4. 입력 종료 후 트랩 해제 (기본 동작으로 복구)
  trap - SIGINT

  local sudoers_file="/etc/sudoers.d/user-$target_user"

  # 5. OS에 따라 패키지 매니저 경로를 추가
  local os_pkg_cmd=""
  if [ "$PKG_MANAGER" == "apt" ]; then
    os_pkg_cmd="/usr/bin/apt, /usr/bin/apt-get, "
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    os_pkg_cmd="/usr/bin/dnf, "
  fi

  local full_no_pw_cmds="${os_pkg_cmd}${NO_PASSWORD_COMMANDS}"

  # 6. 임시 파일을 생성하여 설정 작성
  local tmp_sudoers
  tmp_sudoers=$(mktemp /tmp/sudoers.XXXXXX)

  echo "$target_user ALL=(ALL) ALL" > "$tmp_sudoers"
  echo "$target_user ALL=(ALL) NOPASSWD: $full_no_pw_cmds" >> "$tmp_sudoers"

  # 7. visudo를 이용해 임시 파일 문법 사전 검증 (-c: 검사, -f: 지정 파일)
  if sudo visudo -c -f "$tmp_sudoers" &>/dev/null; then
  
    # [핵심 수정 부분] 읽기 전용(440) 파일에도 안전하고 확실하게 내용을 덮어쓰도록 tee 명령어 사용
    cat "$tmp_sudoers" | sudo tee "$sudoers_file" > /dev/null
    
    sudo chmod 440 "$sudoers_file"
    echo_i " - [🛠 ] $target_user sudoers 설정이 안전하게 업데이트(반영) 되었습니다."
    EXECUTED_JOB_FLAGS["$func_name"]=1
    
    # 작업 완료 후 임시 파일 안전하게 정리
    rm -f -- "$tmp_sudoers"    
  else
    # 검증 실패 시 임시 파일 삭제 후 스크립트 오류 처리
    rm -f -- "$tmp_sudoers"
    
    echo_e " - [❌] 'sudoers' 문법 검증에 실패하여 설정을 취소합니다. (명령어 목록 오타나 콤마 누락 확인 필요)"
    
    _add_notice " - [$func_name] [❌] 'sudoers' 추가 작업 실패"
    _add_notice " - [$func_name] [❌] 'sudoers' 문법 검증에 실패하여 설정을 취소합니다. (명령어 목록 오타나 콤마 누락 확인 필요)"
    return 1
  fi
}

##
# /etc/vim/vimrc 파일에 커스텀 기본 옵션들을 활성화합니다. (vim 패키지 설치는 _install_package가 담당)
#
# @param 없음
#
# @return 진행 상황 메시지 (표준 출력)
##
_install_vim_options() {
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo
  echo "############### $func_name ###############"
  echo "[✨] vim 환경 설정 중..."
  
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
      echo_i " - [💡] $vimrc_file 파일에 커스텀 설정을 추가했습니다."
    else
      echo_w " - $vimrc_file 파일에 이미 커스텀 설정이 존재합니다."
    fi
  else
    echo_e " - [❌] vimrc 파일을 찾지 못해 커스텀 설정을 추가하지 못했습니다."
  fi
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
}

###########################################
###########################################

##
# 외부설정된 RSA_PUBLIC_KEY_LIST 배열을 통해 ~/.ssh/authorized_keys 파일에 여러 공개키를 등록합니다.
##
setup_ssh_key() {
  if [ ${#RSA_PUBLIC_KEY_LIST[@]} -lt 1 ]; then  
    echo ""
    echo_w "⚠️  '등록할 RSA 공개키'가 존재하지 않습니다."
    return 0
  fi
  
  local func_name=${FUNCNAME[0]}
  local flag="${EXECUTED_JOB_FLAGS[$func_name]:-0}"
  
  if (( flag == 1 )); then
    return 0
  fi
  
  echo
  echo "############### $func_name ###############"
  echo "[✨] SSH RSA 키 등록 중..."
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
      echo_i " - [💡] 공개키를 등록했습니다: ${public_key:0:30}..."
    else
      echo_w " - [⚠ ] 이미 등록된 키입니다: ${public_key:0:30}..."
    fi
  done
  
  chmod 600 "$auth_file"
  
  EXECUTED_JOB_FLAGS["$func_name"]=1
}

# ==========================================
# 파라미터 중복 제거 및 우선순위/종속성 처리 로직
# ==========================================
declare -a UNIQUE_ARGS=()
declare -A SEEN_ARGS=()

for arg in "$@"; do
  if [[ -z "${SEEN_ARGS[$arg]}" ]]; then
    UNIQUE_ARGS+=("$arg")
    SEEN_ARGS[$arg]=1
  fi
done

# [규칙 1] "-h, --help" 처리 (가장 최우선 실행 후 종료)
for arg in "${UNIQUE_ARGS[@]}"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    help
    exit 0
  fi
done

# [규칙 2] "--all" 이 있다면 다른 모든 파라미터 무시
if [[ -n "${SEEN_ARGS[--all]}" ]]; then
  UNIQUE_ARGS=("--all")
else
  # [규칙 4 & 5] 종속 옵션(--java-config, --mvn-config) 제거
  declare -a FILTERED_ARGS=()
  for arg in "${UNIQUE_ARGS[@]}"; do
    # --jdk가 있는데 --java-config가 들어왔다면 무시
    if [[ "$arg" == "--java-config" && -n "${SEEN_ARGS[--jdk]}" ]]; then
      continue
    fi
    # --maven이 있는데 --mvn-config가 들어왔다면 무시
    if [[ "$arg" == "--mvn-config" && -n "${SEEN_ARGS[--maven]}" ]]; then
      continue
    fi
    FILTERED_ARGS+=("$arg")
  done
  
  # [규칙 3] "--remove-packages" 가 "--install-packages" 보다 무조건 먼저 실행되도록 재배치
  if [[ -n "${SEEN_ARGS[--remove-packages]}" && -n "${SEEN_ARGS[--install-packages]}" ]]; then
    declare -a REORDERED_ARGS=("--remove-packages")
    for arg in "${FILTERED_ARGS[@]}"; do
      if [[ "$arg" != "--remove-packages" && "$arg" != "--install-packages" ]]; then
        REORDERED_ARGS+=("$arg")
      fi
    done
    REORDERED_ARGS+=("--install-packages")
    UNIQUE_ARGS=("${REORDERED_ARGS[@]}")
  else
    UNIQUE_ARGS=("${FILTERED_ARGS[@]}")
  fi
fi

# 정제된 최종 파라미터($@) 덮어쓰기
set -- "${UNIQUE_ARGS[@]}"

# 기본 설치 옵션 적용 여부 (1: 적용, 그 외: 미적용)
INSTALL_DEFAULT_OPTS=1
APPROVED_OPTS=0

# ==========================================
# 1. 옵션 사전 검사 (Pre-pass)
# ==========================================
for arg in "$@"; do
  case "$arg" in
    --all)
      APPROVED_OPTS=1
      INSTALL_DEFAULT_OPTS=1
      break
      ;;
    --add-sudoers | \
    --custom-tools | \
    --custom-installers | \
    --custom-commands | \
    --install-packages | \
    --remove-packages | \
    --ssh-key )
      APPROVED_OPTS=1
      INSTALL_DEFAULT_OPTS=0
      ;;
  esac  
done

if (( APPROVED_OPTS != 1 )); then
  help "[❌] 지원하는 파라미터가 입력되지 않았습니다." "$LINENO"
  exit 1
fi

# ==========================================
# 2. 필수 기본 설치 진행
# ==========================================
# 패키지 업데이트 실행
_try_pkg_update
# 사전 검사를 무사히 통과했다면(도움말 요청이 아님) 기본 도구들을 설치합니다.
if (( INSTALL_DEFAULT_OPTS == 1 )); then
#   setup_sudoers
#   remove_packages # REMOVE_PACKAGES 기반. 삭제할 도구
#   install_packages # INSTALL_PACKAGES 기반. _install_package 실행
#   setup_custom_tools # URL_CUSTOM_TOOL.<식별정보> 배열 기반 자동 처리
#   setup_custom_installers # URL_CUSTOM_INSTALLER.<식별정보> 배열 기반 자동 처리
#   setup_ssh_key
  _setup_home_bin  
  _setup_git_prompt
  _install_vim_options # `vim` 옵션 적용
fi

# ==========================================
# 3. 메인 실행부 (선택 옵션 처리)
# ==========================================
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ssh-key)
      setup_ssh_key
      shift
      ;;
    --add-sudoers)
      setup_sudoers
      shift
      ;;
    --remove-packages)
      remove_packages
      shift
      ;;
    --install-packages)
      install_packages
      shift
      ;;
    --custom-tools)
      setup_custom_tools
      shift
      ;;
    --custom-installers)
      setup_custom_installers
      shift
      ;;
    --custom-commands)
      setup_custom_commands
      shift
      ;;
    --all)
      setup_sudoers
      remove_packages
      install_packages
      setup_custom_tools
      setup_custom_installers
      setup_custom_commands
      setup_ssh_key
      shift
      ;;
    *)
      echo
      echo_e "############### $1 ###############"
      echo_e "[🛑] 지원하지 않는 옵션입니다. 옵션: $1"
      echo
      shift
      ;;
  esac
done

_announce_notices
echo

exit 0
