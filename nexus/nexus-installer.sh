#!/usr/bin/env bash

# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-08-13
# @desc : support RHEL 9 or higher, Oracle Linux 9 or higher, Ubuntu 24.04 or higher, RockyOS 10 or higher, CentOS Stream 9 or higher
# @installation : 
# 1. insert 'source <path>/nexus-installer.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/nexus-installer.sh' into /etc/bashrc for all users.
# =======================================

set -Eeuo pipefail

readonly FILENAME=$(basename "$0")
readonly TEMP_ARCHIVE="/tmp/nexus_download_pkg.tar.gz"
readonly TEMP_EXTRACT_DIR="/tmp/nexus_extract_tmp"
readonly INSTANCES_DIR="/etc/sonatype/instances"

ACTION=""
DOWNLOAD_URL=""
PACKAGE_FILE=""
BASE_INSTALL_DIR="/opt/sonatype"
NEXUS_VERSION_OPT=""
NEXUS_USER="nexus"
NEXUS_PORT="8081"

HAS_INVALID_UNINSTALL_OPTIONS=false
IS_DRY_RUN=false

##
# 도움말 출력 및 에러 발생 시 호출 스택 정보를 표시하는 함수
#
# @param $1 {string} 에러 원인 메시지
# @param $2 {number} 에러 발생 라인 번호
#
# @return stdout
##
help(){
  if [ ! -z "${1:-}" ];
  then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "${2:-UNKNOWN}"
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
  echo "사용법: $FILENAME [작업] [옵션]"
  echo "Sonatype Nexus Repository 다중 인스턴스 설치 및 언인스톨 스크립트"
  echo
  echo "필수 작업 선택 (둘 중 하나 필수):"
  echo "      --install              Nexus 서비스 설치 실행"
  echo "      --uninstall            기 설치된 Nexus 서비스 및 파일 완전 삭제"
  echo
  echo "공통 옵션:"
  echo "      --dry-run              실제 시스템 변경 없이 작업 과정 시뮬레이션 수행"
  echo "      --help                 도움말 출력"
  echo
  echo "설치(--install) 전용 옵션:"
  echo "  --download-url <URL>       Nexus 설치 패키지 다운로드 URL (--file 옵션과 상호 배타적)"
  echo "  --file <파일경로>          Nexus 설치 패키지 로컬 파일 경로 (--download-url 옵션과 상호 배타적)"
  echo "  --install-dir <경로>       Nexus 상위 설치 디렉토리 (기본값: /opt/sonatype)"
  echo "  --version <버전>           Nexus 버전 명시 지정 (미지정 시 URL/파일명에서 자동 추출)"
  echo "  --user <계정명>            Nexus 실행 전용 시스템 계정 (기본값: nexus)"
  echo "  --port <포트번호>          Nexus HTTP 서비스 포트 (기본값: 8081)"
}

##
# 스크립트 종료 또는 오류 발생 시 임시 자원을 정돈하는 트랩 함수
#
# @return null
##
cleanup() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo -e "\n[❌] 오류가 발생하여 작업이 중단되었습니다. 임시 자원을 정리합니다." >&2
  fi
  rm -f "$TEMP_ARCHIVE" 2>/dev/null || true
  rm -rf "$TEMP_EXTRACT_DIR" 2>/dev/null || true
}
trap cleanup EXIT ERR

##
# URL 또는 파일명으로부터 Nexus 버전 정보를 정밀 추출하는 함수
#
# @param $1 {string} 다운로드 URL 또는 파일 경로
# @param $2 {string} 명시적 버전 문자열 (선택 사항)
#
# @return stdout 정제된 버전 문자열
##
extract_nexus_version() {
  local source_str="$1"
  local explicit_ver="${2:-}"

  if [ -n "$explicit_ver" ]; then
    echo "$explicit_ver"
    return 0
  fi

  local ver
  ver=$(echo "$source_str" | grep -oP 'nexus-\K[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' || true)

  if [ -z "$ver" ]; then
    ver=$(echo "$source_str" | sed -nE 's/.*nexus-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+).*/\1/p')
  fi

  if [ -z "$ver" ]; then
    help "설치 소스에서 Nexus 버전을 자동 추출할 수 없습니다. --version 옵션으로 버전을 명시하세요." "$LINENO"
    exit 1
  fi

  echo "$ver"
}

##
# 다운로드 URL의 접근 유효성을 검증하는 함수
#
# @param $1 {string} 다운로드 URL
#
# @return null
##
validate_download_url() {
  local url="$1"
  echo "[🔍] 다운로드 URL 접근 유효성 검증 중 -> $url"

  if command -v curl &> /dev/null; then
    if ! curl --output /dev/null --silent --head --fail -L "$url"; then
      help "지정한 URL에 접근할 수 없거나 파일이 존재하지 않습니다: $url" "$LINENO"
      exit 1
    fi
  elif command -v wget &> /dev/null; then
    if ! wget --spider -q "$url"; then
      help "지정한 URL에 접근할 수 없거나 파일이 존재하지 않습니다: $url" "$LINENO"
      exit 1
    fi
  else
    help "curl 또는 wget 유틸리티가 필요합니다." "$LINENO"
    exit 1
  fi
  echo "[✅] URL 유효성 검증 완료."
}

##
# 로컬 패키지 파일의 존재 유무 및 읽기 권한을 검증하는 함수
#
# @param $1 {string} 로컬 패키지 파일 경로
#
# @return null
##
validate_package_file() {
  local file_path="$1"
  echo "[🔍] 로컬 패키지 파일 유효성 검증 중 -> $file_path"

  if [ ! -f "$file_path" ]; then
    help "지정한 로컬 패키지 파일이 존재하지 않거나 일반 파일이 아닙니다: $file_path" "$LINENO"
    exit 1
  fi

  if [ ! -r "$file_path" ]; then
    help "지정한 로컬 패키지 파일에 대한 읽기 권한이 없습니다: $file_path" "$LINENO"
    exit 1
  fi
  echo "[✅] 로컬 패키지 파일 유효성 검증 완료."
}

##
# 사전 필수 실행 조건, Sudo 권한 및 포트 중복을 검증하는 함수
#
# @param $1 {string} 포트 번호
# @param $2 {string} 상위 설치 디렉토리 경로
#
# @return null
##
check_prerequisites() {
  local port="$1"
  local base_dir="$2"

  if ! sudo -v &>/dev/null; then
    help "이 스크립트는 계정 및 서비스 설정을 위해 sudo 권한이 필요합니다." "$LINENO"
    exit 1
  fi

  if ! command -v tar &> /dev/null; then
    help "tar 압축 해제 유틸리티가 설치되어 있지 않습니다." "$LINENO"
    exit 1
  fi

  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
    help "유효하지 않은 포트 번호입니다 (1024-65535 범위 허용): $port" "$LINENO"
    exit 1
  fi

  if command -v ss &> /dev/null; then
    if ss -tulpn | grep -q ":$port "; then
      help "지정한 포트($port)가 이미 다른 프로세스에 의해 사용 중입니다." "$LINENO"
      exit 1
    fi
  fi
}

##
# 기존 설치된 인스턴스와의 버전 및 포트 충돌 여부를 점검하는 함수
#
# @param $1 {string} Nexus 버전 (INSTANCE_ID)
# @param $2 {string} 포트 번호
#
# @return 0(이상없음) / exit 0 또는 1(충돌시)
##
check_instance_conflicts() {
  local instance_id="$1"
  local target_port="$2"

  if [ ! -d "$INSTANCES_DIR" ]; then
    return 0
  fi

  local meta_file="$INSTANCES_DIR/${instance_id}.info"
  if [ -f "$meta_file" ]; then
    local exist_dir exist_port exist_ver
    exist_dir=$(grep '^INSTALL_DIR=' "$meta_file" | cut -d'=' -f2- | tr -d '"')
    exist_port=$(grep '^NEXUS_PORT=' "$meta_file" | cut -d'=' -f2- | tr -d '"')
    exist_ver=$(grep '^NEXUS_VERSION=' "$meta_file" | cut -d'=' -f2- | tr -d '"')

    echo "[ℹ️] 동일한 버전($instance_id)으로 등록된 기존 인스턴스가 존재합니다."
    echo "================================================================================"
    echo " - 버전      : $exist_ver"
    echo " - 설치 경로 : $exist_dir"
    echo " - 서비스 포트: $exist_port"
    echo "================================================================================"
    echo "[⚠️] 이미 해당 버전의 Nexus가 설치되어 있습니다. 재설치하려면 먼저 '--uninstall' 명령을 실행하여 해당 인스턴스를 삭제하세요."
    exit 0
  fi

  local file
  for file in "$INSTANCES_DIR"/*.info; do
    if [ -f "$file" ]; then
      local exist_port exist_dir
      exist_port=$(grep '^NEXUS_PORT=' "$file" | cut -d'=' -f2- | tr -d '"')
      exist_dir=$(grep '^INSTALL_DIR=' "$file" | cut -d'=' -f2- | tr -d '"')

      if [ "$exist_port" == "$target_port" ]; then
        help "입력한 포트($target_port)는 기존 인스턴스($exist_dir)에서 이미 등록되어 사용 중입니다." "$LINENO"
        exit 1
      fi
    fi
  done
}

##
# Nexus 실행 전용 시스템 계정을 생성하는 함수 (드라이 런 가상화 분기 처리)
#
# @param $1 {string} 계정명
# @param $2 {boolean} 드라이 런 플래그 (true/false)
#
# @return stdout
##
create_nexus_user() {
  local username="$1"
  local dry_run="${2:-false}"

  if [ "$dry_run" = true ]; then
    echo "[DRY-RUN] [👤] 시스템 계정 '$username' 생성 예정 (명령: sudo useradd -r -s /bin/false \"$username\")"
    return 0
  fi

  if id "$username" &>/dev/null; then
    echo "[ℹ️] 시스템 계정 '$username'이(가) 이미 존재합니다."
  else
    echo "[👤] Nexus 전용 시스템 계정 '$username' 생성 중..."
    sudo useradd -r -s /bin/false "$username"
  fi
}

##
# Nexus 패키지(URL 다운로드 또는 로컬 파일)를 확보하고 압축을 해제하여 구성하는 함수
#
# @param $1 {string} 다운로드 URL 또는 로컬 파일 경로
# @param $2 {string} 바이너리 설치 디렉토리
# @param $3 {string} 데이터 디렉토리
# @param $4 {boolean} 드라이 런 플래그 (true/false)
# @param $5 {boolean} 로컬 파일 사용 여부 (true/false)
#
# @return null
##
download_and_extract() {
  local source_path="$1"
  local inst_dir="$2"
  local data_dir="$3"
  local dry_run="${4:-false}"
  local is_local="${5:-false}"

  local parent_inst_dir
  parent_inst_dir=$(dirname "$inst_dir")

  local target_tar=""

  if [ "$is_local" = true ]; then
    echo "[📂] 지정된 로컬 패키지 파일 사용 -> $source_path"
    target_tar="$source_path"
  else
    echo "[📥] Nexus 패키지 실제 다운로드 시작 -> $source_path"
    if command -v curl &> /dev/null; then
      curl -L "$source_path" -o "$TEMP_ARCHIVE"
    else
      wget "$source_path" -O "$TEMP_ARCHIVE"
    fi
    echo "[✅] 설치 패키지 실제 다운로드 완료 -> $TEMP_ARCHIVE"
    target_tar="$TEMP_ARCHIVE"
  fi

  mkdir -p "$TEMP_EXTRACT_DIR"
  echo "[📦] 패키지 무결성 검증을 위한 임시 압축 해제 진행 중..."
  tar -xzf "$target_tar" -C "$TEMP_EXTRACT_DIR"

  local extracted_nexus_dir
  extracted_nexus_dir=$(find "$TEMP_EXTRACT_DIR" -maxdepth 1 -type d -name "nexus-3*" | head -n 1)

  if [ -z "$extracted_nexus_dir" ]; then
    help "압축 파일 내에서 Nexus 바이너리 디렉토리를 찾을 수 없습니다." "$LINENO"
    exit 1
  fi

  if [ "$dry_run" = true ]; then
    echo "[DRY-RUN] [📂] 상위 설치 디렉토리 생성 예정 -> $parent_inst_dir (sudo mkdir -p \"$parent_inst_dir\")"
    echo "[DRY-RUN] [📂] 데이터 디렉토리 생성 예정 -> $data_dir (sudo mkdir -p \"$data_dir\")"
    echo "[DRY-RUN] [🚀] 바이너리 배치 예정 -> $extracted_nexus_dir -> $inst_dir"
    local default_work_dir
    default_work_dir=$(find "$TEMP_EXTRACT_DIR" -maxdepth 1 -type d -name "sonatype-work" | head -n 1)
    if [ -n "$default_work_dir" ] && [ -d "$default_work_dir" ]; then
      echo "[DRY-RUN] [⚙️] 기본 데이터 구조 복사 예정 -> $default_work_dir/* -> $data_dir/"
    fi
  else
    if [ ! -d "$parent_inst_dir" ]; then
      echo "[📂] 상위 설치 디렉토리 자동 생성 -> $parent_inst_dir"
      sudo mkdir -p "$parent_inst_dir"
    fi

    if [ ! -d "$data_dir" ]; then
      echo "[📂] 데이터 디렉토리 자동 생성 -> $data_dir"
      sudo mkdir -p "$data_dir"
    fi

    if [ -d "$inst_dir" ]; then
      echo "[⚠️] 기존 설치 디렉토리가 존재하여 덮어씁니다 -> $inst_dir"
      sudo rm -rf "$inst_dir"
    fi

    echo "[🚀] 바이너리 디렉토리 이동 -> $inst_dir"
    sudo mv "$extracted_nexus_dir" "$inst_dir"

    local default_work_dir
    default_work_dir=$(find "$TEMP_EXTRACT_DIR" -maxdepth 1 -type d -name "sonatype-work" | head -n 1)
    if [ -n "$default_work_dir" ] && [ -d "$default_work_dir" ]; then
      echo "[⚙️] 기본 데이터 구조 복사 진행 -> $data_dir"
      sudo cp -rn "$default_work_dir"/* "$data_dir"/ 2>/dev/null || true
    fi
  fi

  if [ "$is_local" = false ]; then
    rm -f "$TEMP_ARCHIVE" 2>/dev/null || true
    echo "[🗑️] 다운로드된 임시 파일 삭제 완료 -> $TEMP_ARCHIVE"
  fi
  rm -rf "$TEMP_EXTRACT_DIR" 2>/dev/null || true
}

##
# Nexus JVM 옵션, 실행 계정, 포트 설정 함수 (드라이 런 가상화 분기 처리)
#
# @param $1 {string} 바이너리 설치 디렉토리
# @param $2 {string} 데이터 디렉토리
# @param $3 {string} 실행 계정명
# @param $4 {string} 포트 번호
# @param $5 {boolean} 드라이 런 플래그 (true/false)
#
# @return stdout
##
configure_nexus() {
  local inst_dir="$1"
  local data_dir="$2"
  local username="$3"
  local port="$4"
  local dry_run="${5:-false}"

  if [ "$dry_run" = true ]; then
    echo "[DRY-RUN] [⚙️] Nexus 실행 계정 설정 예정 -> $inst_dir/bin/nexus.rc (run_as_user=\"$username\")"
    echo "[DRY-RUN] [⚙️] Nexus HTTP 포트 설정 예정 -> $inst_dir/etc/nexus-default.properties (application-port=$port)"
    echo "[DRY-RUN] [⚙️] JVM 옵션 데이터 경로 설정 예정 -> $inst_dir/bin/nexus.vmoptions (-Dkaraf.data=$data_dir/nexus3)"
    echo "[DRY-RUN] [🔒] 파일 소유권 변경 예정 -> $inst_dir, $data_dir (sudo chown -R $username:$username)"
    return 0
  fi

  echo "[⚙️] Nexus 실행 계정 지정 -> $username"
  echo "run_as_user=\"$username\"" | sudo tee "$inst_dir/bin/nexus.rc" > /dev/null

  echo "[⚙️] Nexus HTTP 포트 변경 설정 -> $port"
  local prop_file="$inst_dir/etc/nexus-default.properties"
  if [ -f "$prop_file" ]; then
    sed -i "s/application-port=[0-9]*/application-port=$port/g" "$prop_file"
  fi

  echo "[⚙️] JVM 옵션 데이터 경로 설정 분리 적용 -> $data_dir"
  local vmoptions_file="$inst_dir/bin/nexus.vmoptions"
  if [ -f "$vmoptions_file" ]; then
    local escaped_data_dir
    escaped_data_dir=$(echo "$data_dir/nexus3" | sed 's/\//\\\//g')
    sed -i "s/-Dkaraf.data=.*/-Dkaraf.data=$escaped_data_dir/g" "$vmoptions_file"
    sed -i "s/-Djava.io.tmpdir=.*/-Djava.io.tmpdir=$escaped_data_dir\/tmp/g" "$vmoptions_file"
  fi

  sudo mkdir -p "$data_dir/nexus3/tmp"

  echo "[🔒] 파일 소유권 변경 진행 중 -> $username"
  sudo chown -R "$username:$username" "$inst_dir"
  sudo chown -R "$username:$username" "$data_dir"
}

##
# Systemd 서비스 등록 및 자동 실행을 활성화하는 함수 (드라이 런 가상화 분기 처리)
#
# @param $1 {string} 바이너리 설치 디렉토리
# @param $2 {string} 실행 계정명
# @param $3 {string} 서비스 유닛명
# @param $4 {boolean} 드라이 런 플래그 (true/false)
#
# @return stdout
##
setup_systemd_service() {
  local inst_dir="$1"
  local username="$2"
  local service_name="$3"
  local dry_run="${4:-false}"

  local service_file="/etc/systemd/system/${service_name}.service"

  if [ "$dry_run" = true ]; then
    echo "[DRY-RUN] [⚙️] Systemd 서비스 파일 생성 예정 -> $service_file"
    echo "--------------------------------------------------------------------------------"
    echo "[Unit]"
    echo "Description=Sonatype Nexus Repository Service ($service_name)"
    echo "After=network.target"
    echo
    echo "[Service]"
    echo "Type=forking"
    echo "LimitNOFILE=65536"
    echo "User=$username"
    echo "Group=$username"
    echo "ExecStart=$inst_dir/bin/nexus start"
    echo "ExecStop=$inst_dir/bin/nexus stop"
    echo "Restart=on-abort"
    echo
    echo "[Install]"
    echo "WantedBy=multi-user.target"
    echo "--------------------------------------------------------------------------------"
    echo "[DRY-RUN] [⚙️] Systemd 서비스 활성화 예정 (sudo systemctl daemon-reload && sudo systemctl enable $service_name)"
    return 0
  fi

  echo "[⚙️] Systemd 서비스 등록 중 -> $service_file"
  cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=Sonatype Nexus Repository Service ($service_name)
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=$username
Group=$username
ExecStart=$inst_dir/bin/nexus start
ExecStop=$inst_dir/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable "$service_name"
}

##
# 설치 메타데이터(installation-data) 저장을 담당하는 함수 (드라이 런 가상화 분기 처리)
#
# @param $1 {string} 인스턴스 ID (버전)
# @param $2 {string} Nexus 버전
# @param $3 {string} 설치 디렉토리
# @param $4 {string} 데이터 디렉토리
# @param $5 {string} 실행 계정명
# @param $6 {string} 서비스 포트
# @param $7 {string} 서비스 유닛명
# @param $8 {boolean} 드라이 런 플래그 (true/false)
#
# @return stdout
##
save_installation_data() {
  local instance_id="$1"
  local version="$2"
  local inst_dir="$3"
  local data_dir="$4"
  local username="$5"
  local port="$6"
  local service_name="$7"
  local dry_run="${8:-false}"

  local meta_file="$INSTANCES_DIR/${instance_id}.info"

  if [ "$dry_run" = true ]; then
    echo "[DRY-RUN] [⚙️] 인스턴스 메타데이터(installation-data) 파일 생성 예정 -> $meta_file"
    echo "--------------------------------------------------------------------------------"
    echo "INSTANCE_ID=\"$instance_id\""
    echo "NEXUS_VERSION=\"$version\""
    echo "INSTALL_DIR=\"$inst_dir\""
    echo "DATA_DIR=\"$data_dir\""
    echo "NEXUS_USER=\"$username\""
    echo "NEXUS_PORT=\"$port\""
    echo "SERVICE_NAME=\"$service_name\""
    echo "INSTALLED_AT=\"$(date '+%Y-%m-%d %H:%M:%S')\""
    echo "--------------------------------------------------------------------------------"
    return 0
  fi

  if [ ! -d "$INSTANCES_DIR" ]; then
    sudo mkdir -p "$INSTANCES_DIR"
  fi

  echo "[⚙️] 인스턴스 메타데이터(installation-data) 저장 중 -> $meta_file"
  cat <<EOF | sudo tee "$meta_file" > /dev/null
INSTANCE_ID="$instance_id"
NEXUS_VERSION="$version"
INSTALL_DIR="$inst_dir"
DATA_DIR="$data_dir"
NEXUS_USER="$username"
NEXUS_PORT="$port"
SERVICE_NAME="$service_name"
INSTALLED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
  sudo chmod 644 "$meta_file"
}

##
# 언인스톨 대상을 저장된 메타데이터 모음에서 탐색하여 로드하는 함수
#
# @return 0(성공시) / exit 1(실패시)
##
resolve_uninstall_target() {
  if [ ! -d "$INSTANCES_DIR" ] || [ -z "$(ls -A "$INSTANCES_DIR"/*.info 2>/dev/null)" ]; then
    echo "[❌] 등록된 Nexus 설치 정보(installation-data)를 찾을 수 없습니다." >&2
    exit 1
  fi

  local instance_files=()
  local file
  for file in "$INSTANCES_DIR"/*.info; do
    if [ -f "$file" ]; then
      instance_files+=("$file")
    fi
  done

  local total_count="${#instance_files[@]}"
  if [ "$total_count" -eq 0 ]; then
    echo "[❌] 등록된 Nexus 설치 정보(installation-data)가 존재하지 않습니다." >&2
    exit 1
  fi

  local selected_file=""

  if [ "$total_count" -eq 1 ]; then
    selected_file="${instance_files[0]}"
    local v d p u
    v=$(grep '^NEXUS_VERSION=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
    d=$(grep '^INSTALL_DIR=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
    p=$(grep '^NEXUS_PORT=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
    u=$(grep '^NEXUS_USER=' "$selected_file" | cut -d'=' -f2- | tr -d '"')

    echo "[ℹ️] 단일 Nexus 인스턴스가 감지되었습니다."
    echo "================================================================================"
    echo " - 버전      : $v"
    echo " - 설치 경로 : $d"
    echo " - 서비스 포트: $p"
    echo " - 실행 계정 : $u"
    echo "================================================================================"

    if [ -t 0 ]; then
      local confirm_ans=""
      read -r -p "이 인스턴스를 삭제하시겠습니까? (y/N): " confirm_ans || { echo -e "\n[ℹ️] 입력 취소되었습니다."; exit 0; }
      if [[ ! "$confirm_ans" =~ ^[yY]$ ]]; then
        echo "[ℹ️] 언인스톨 작업이 취소되었습니다."
        exit 0
      fi
    fi
  else
    if [ ! -t 0 ]; then
      echo "[❌] 비대화형(Non-TTY) 환경에서는 감지된 다중 인스턴스 중 선택을 진행할 수 없습니다." >&2
      exit 1
    fi

    echo
    echo "================================================================================"
    echo "📌 삭제할 Nexus 인스턴스를 선택해 주세요 (총 $total_count 개 감지됨)"
    echo "================================================================================"

    local idx=1
    for file in "${instance_files[@]}"; do
      local v d p u
      v=$(grep '^NEXUS_VERSION=' "$file" | cut -d'=' -f2- | tr -d '"')
      d=$(grep '^INSTALL_DIR=' "$file" | cut -d'=' -f2- | tr -d '"')
      p=$(grep '^NEXUS_PORT=' "$file" | cut -d'=' -f2- | tr -d '"')
      u=$(grep '^NEXUS_USER=' "$file" | cut -d'=' -f2- | tr -d '"')
      printf "[%2d] 버전: %-10s | 포트: %-5s | 계정: %-10s | 경로: %s\n" "$idx" "$v" "$p" "$u" "$d"
      ((idx++))
    done
    echo "[ q] 언인스톨 취소 (Exit)"
    echo "================================================================================"

    local user_choice=""
    read -r -p "삭제할 인스턴스 번호를 입력하세요 [1-$total_count] (취소: q): " user_choice || { echo -e "\n[ℹ️] 입력 취소되었습니다."; exit 0; }

    if [[ "$user_choice" =~ ^[qQ]$ ]]; then
      echo "[ℹ️] 언인스톨 작업이 취소되었습니다."
      exit 0
    fi

    if ! [[ "$user_choice" =~ ^[0-9]+$ ]] || [ "$user_choice" -lt 1 ] || [ "$user_choice" -gt "$total_count" ]; then
      echo "[❌] 유효하지 않은 선택입니다: '$user_choice'. 올바른 번호를 선택해야 합니다." >&2
      exit 1
    fi

    selected_file="${instance_files[$((user_choice - 1))]}"
  fi

  TARGET_INSTANCE_ID=$(grep '^INSTANCE_ID=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  NEXUS_VERSION=$(grep '^NEXUS_VERSION=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  INSTALL_DIR=$(grep '^INSTALL_DIR=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  DATA_DIR=$(grep '^DATA_DIR=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  NEXUS_USER=$(grep '^NEXUS_USER=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  NEXUS_PORT=$(grep '^NEXUS_PORT=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  SERVICE_NAME=$(grep '^SERVICE_NAME=' "$selected_file" | cut -d'=' -f2- | tr -d '"')
  TARGET_META_FILE="$selected_file"

  return 0
}

##
# 특정 Nexus 인스턴스 및 서비스, 계정, 디렉토리, 메타데이터를 완전 삭제하는 함수 (드라이 런 가상화 처리)
#
# @param $1 {string} 인스턴스 ID
# @param $2 {string} 바이너리 설치 디렉토리
# @param $3 {string} 데이터 디렉토리
# @param $4 {string} 실행 계정명
# @param $5 {string} Systemd 서비스명
# @param $6 {string} 메타데이터 파일 경로
# @param $7 {boolean} 드라이 런 플래그 (true/false)
#
# @return stdout
##
uninstall_nexus_instance() {
  local inst_id="$1"
  local inst_dir="$2"
  local data_dir="$3"
  local username="$4"
  local service_name="$5"
  local meta_file="$6"
  local dry_run="${7:-false}"

  if ! sudo -v &>/dev/null; then
    help "언인스톨 작업을 진행하기 위해 sudo 권한이 필요합니다." "$LINENO"
    exit 1
  fi

  if [ "$inst_dir" == "/" ] || [ "$data_dir" == "/" ] || [ -z "$inst_dir" ] || [ -z "$data_dir" ]; then
    help "삭제 대상 경로가 유효하지 않거나 루트(/) 디렉토리입니다." "$LINENO"
    exit 1
  fi

  if [ "$dry_run" = true ]; then
    echo
    echo "================================================================================"
    echo "📌 Nexus 인스턴스 언인스톨 드라이 런(Dry-Run) 시뮬레이션을 시작합니다."
    echo "================================================================================"
    echo " - 인스턴스 ID : $inst_id"
    echo " - 바이너리 경로 : $inst_dir"
    echo " - 데이터 경로   : $data_dir"
    echo " - Systemd 서비스: $service_name"
    echo " - 실행 계정     : $username"
    echo "================================================================================"
    echo "[DRY-RUN] [⚙️] Systemd 서비스 중지 및 비활성화 예정 (sudo systemctl stop $service_name && sudo systemctl disable $service_name)"
    echo "[DRY-RUN] [⚙️] Systemd 서비스 파일 삭제 및 데몬 리로드 예정 (/etc/systemd/system/${service_name}.service)"
    echo "[DRY-RUN] [📂] 바이너리 디렉토리 삭제 예정 (sudo rm -rf \"$inst_dir\")"
    echo "[DRY-RUN] [📂] 데이터 디렉토리 삭제 예정 (sudo rm -rf \"$data_dir\")"

    local user_shared=false
    local file
    for file in "$INSTANCES_DIR"/*.info; do
      if [ -f "$file" ] && [ "$file" != "$meta_file" ]; then
        local other_user
        other_user=$(grep '^NEXUS_USER=' "$file" | cut -d'=' -f2- | tr -d '"')
        if [ "$other_user" == "$username" ]; then
          user_shared=true
          break
        fi
      fi
    done

    if [ "$user_shared" = false ]; then
      echo "[DRY-RUN] [👤] 미공유 전용 시스템 계정 삭제 예정 (sudo userdel \"$username\")"
    else
      echo "[DRY-RUN] [ℹ️] 타 인스턴스 공유 계정이므로 삭제하지 않고 유지 예정 ($username)"
    fi

    echo "[DRY-RUN] [🗑️] 인스턴스 메타데이터 파일 삭제 예정 (sudo rm -f \"$meta_file\")"
    echo "================================================================================"
    echo "[✅] Nexus 언인스톨 드라이 런(Dry-Run) 시뮬레이션 완료! (실제 시스템 변경 사항 없음)"
    echo "================================================================================"
    return 0
  fi

  echo "[🗑️] Nexus 인스턴스 언인스톨 작업을 시작합니다..."
  echo " - 인스턴스 ID : $inst_id"
  echo " - 바이너리 경로 : $inst_dir"
  echo " - 데이터 경로   : $data_dir"
  echo " - Systemd 서비스: $service_name"
  echo " - 실행 계정     : $username"

  local service_file="/etc/systemd/system/${service_name}.service"
  if [ -f "$service_file" ] || systemctl is-active --quiet "$service_name" 2>/dev/null; then
    echo "[⚙️] Systemd 서비스($service_name) 중지 및 비활성화 중..."
    sudo systemctl stop "$service_name" 2>/dev/null || true
    sudo systemctl disable "$service_name" 2>/dev/null || true
    if [ -f "$service_file" ]; then
      sudo rm -f "$service_file"
      sudo systemctl daemon-reload
    fi
    echo "[✅] Systemd 서비스 제거 완료."
  fi

  if [ -d "$inst_dir" ]; then
    echo "[📂] 바이너리 디렉토리 삭제 중 -> $inst_dir"
    sudo rm -rf "$inst_dir"
  fi

  if [ -d "$data_dir" ]; then
    echo "[📂] 데이터 디렉토리 삭제 중 -> $data_dir"
    sudo rm -rf "$data_dir"
  fi

  local user_shared=false
  local file
  for file in "$INSTANCES_DIR"/*.info; do
    if [ -f "$file" ] && [ "$file" != "$meta_file" ]; then
      local other_user
      other_user=$(grep '^NEXUS_USER=' "$file" | cut -d'=' -f2- | tr -d '"')
      if [ "$other_user" == "$username" ]; then
        user_shared=true
        break
      fi
    fi
  done

  if [ "$user_shared" = false ] && id "$username" &>/dev/null; then
    echo "[👤] 다른 인스턴스에서 사용하지 않는 시스템 계정이므로 삭제합니다 -> $username"
    sudo userdel "$username" 2>/dev/null || true
  else
    echo "[ℹ️] 시스템 계정 '$username'은(는) 다른 Nexus 인스턴스에서 사용 중이므로 유지합니다."
  fi

  if [ -f "$meta_file" ]; then
    echo "[🗑️] 인스턴스 메타데이터 파기 중 -> $meta_file"
    sudo rm -f "$meta_file"
  fi

  echo "[✅] Nexus 인스턴스($inst_id)가 성공적으로 완벽 제거되었습니다."
}

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      if [ -n "$ACTION" ]; then
        help "--install 옵션과 --uninstall 옵션은 동시에 사용할 수 없습니다." "$LINENO"
        exit 1
      fi
      ACTION="install"
      shift 1
      ;;
    --uninstall)
      if [ -n "$ACTION" ]; then
        help "--install 옵션과 --uninstall 옵션은 동시에 사용할 수 없습니다." "$LINENO"
        exit 1
      fi
      ACTION="uninstall"
      shift 1
      ;;
    --dry-run)
      IS_DRY_RUN=true
      shift 1
      ;;
    --download-url)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 다운로드 URL이 누락되었습니다." "$LINENO"
        exit 1
      fi
      DOWNLOAD_URL="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --file)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 파일 경로가 누락되었습니다." "$LINENO"
        exit 1
      fi
      PACKAGE_FILE="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --install-dir)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 상위 설치 디렉토리 경로가 누락되었습니다." "$LINENO"
        exit 1
      fi
      BASE_INSTALL_DIR="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --version)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 버전 정보가 누락되었습니다." "$LINENO"
        exit 1
      fi
      NEXUS_VERSION_OPT="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --user)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 계정명이 누락되었습니다." "$LINENO"
        exit 1
      fi
      NEXUS_USER="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --port)
      if [ -z "${2:-}" ] || [[ "$2" =~ ^-- ]]; then
        help "옵션 '$1' 에 포트 번호가 누락되었습니다." "$LINENO"
        exit 1
      fi
      NEXUS_PORT="$2"
      HAS_INVALID_UNINSTALL_OPTIONS=true
      shift 2
      ;;
    --help)
      help
      exit 0
      ;;
    *)
      help "알 수 없는 옵션: $1" "$LINENO"
      exit 1
      ;;
  esac
done

if [ -z "$ACTION" ]; then
  help "작업 모드(--install 또는 --uninstall) 중 하나를 반드시 지정해야 합니다." "$LINENO"
  exit 1
fi

if [ "$ACTION" = "uninstall" ]; then
  if [ "$HAS_INVALID_UNINSTALL_OPTIONS" = true ]; then
    help "--uninstall 작업 실행 시에는 --install-dir, --file, --version, --user, --port, --download-url 등 설치 전용 옵션을 함께 지정할 수 없습니다. (--dry-run 가능)" "$LINENO"
    exit 1
  fi

  resolve_uninstall_target
  uninstall_nexus_instance "$TARGET_INSTANCE_ID" "$INSTALL_DIR" "$DATA_DIR" "$NEXUS_USER" "$SERVICE_NAME" "$TARGET_META_FILE" "$IS_DRY_RUN"

elif [ "$ACTION" = "install" ]; then
  if [ -n "$DOWNLOAD_URL" ] && [ -n "$PACKAGE_FILE" ]; then
    help "--download-url 옵션과 --file 옵션은 동시에 사용할 수 없습니다. 둘 중 하나만 지정하세요." "$LINENO"
    exit 1
  fi

  if [ -z "$DOWNLOAD_URL" ] && [ -z "$PACKAGE_FILE" ]; then
    help "설치를 위해 --download-url 또는 --file 옵션 중 하나가 반드시 필요합니다." "$LINENO"
    exit 1
  fi

  is_local_file=false
  pkg_source=""
  if [ -n "$PACKAGE_FILE" ]; then
    is_local_file=true
    pkg_source="$PACKAGE_FILE"
    validate_package_file "$PACKAGE_FILE"
  else
    pkg_source="$DOWNLOAD_URL"
    validate_download_url "$DOWNLOAD_URL"
  fi

  NEXUS_VERSION=$(extract_nexus_version "$pkg_source" "$NEXUS_VERSION_OPT")
  SERVICE_INSTALL_DIR="${BASE_INSTALL_DIR}/nexus-${NEXUS_VERSION}"
  DATA_DIR="${BASE_INSTALL_DIR}/sonatype-work"
  INSTANCE_ID="${NEXUS_VERSION}"
  SERVICE_NAME="nexus-${INSTANCE_ID}"

  check_instance_conflicts "$INSTANCE_ID" "$NEXUS_PORT"
  check_prerequisites "$NEXUS_PORT" "$BASE_INSTALL_DIR"

  if [ "$IS_DRY_RUN" = true ]; then
    echo
    echo "================================================================================"
    echo "📌 Nexus 인스턴스 설치 드라이 런(Dry-Run) 시뮬레이션을 시작합니다."
    echo "================================================================================"
  fi

  create_nexus_user "$NEXUS_USER" "$IS_DRY_RUN"
  download_and_extract "$pkg_source" "$SERVICE_INSTALL_DIR" "$DATA_DIR" "$IS_DRY_RUN" "$is_local_file"
  configure_nexus "$SERVICE_INSTALL_DIR" "$DATA_DIR" "$NEXUS_USER" "$NEXUS_PORT" "$IS_DRY_RUN"
  setup_systemd_service "$SERVICE_INSTALL_DIR" "$NEXUS_USER" "$SERVICE_NAME" "$IS_DRY_RUN"
  save_installation_data "$INSTANCE_ID" "$NEXUS_VERSION" "$SERVICE_INSTALL_DIR" "$DATA_DIR" "$NEXUS_USER" "$NEXUS_PORT" "$SERVICE_NAME" "$IS_DRY_RUN"

  if [ "$IS_DRY_RUN" = true ]; then
    echo "================================================================================"
    echo "[✅] Nexus 드라이 런(Dry-Run) 시뮬레이션 완료! (실제 시스템 변경 사항 없음)"
    echo "================================================================================"
  else
    echo "[✅] Nexus 인스턴스 설치 및 Systemd 서비스($SERVICE_NAME) 등록 완료! ('sudo systemctl start $SERVICE_NAME' 명령으로 실행)"
  fi
fi

exit 0