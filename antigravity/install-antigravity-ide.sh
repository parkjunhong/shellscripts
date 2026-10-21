#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : install antigravity-ide.
# @license : Apache License 2.0
# @since : 2026-10-08
# @desc : support RHEL, Oracle Linux, Ubuntu, RockyOS, CentOS
# @installation : 
# 1. insert 'source <path>/install-antigravity-ide.sh.completion" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-antigravity-ide.sh' into '/etc/bashrc' or '/usr/share/bash-completion/completions/' for all users.
# =======================================

set -Eeuo pipefail

FILENAME=$(basename "$0")

##
# 스크립트 사용 방법 및 오류 원인을 출력합니다.
#
# @param $1 {string} (오류 발생 시 원인 메시지)
# @param $2 {string} (오류 발생 라인)
#
# @return (도움말 내용 출력)
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
    printf "$formatl" "line" "${2:-}"
    printf "$formatl" "callstack"
    local idx=1
    for func in "${FUNCNAME[@]:1}"
    do 
      printf "$formatr" "["$idx"]" "$func"
      ((idx++)) || true
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi 
  echo 
  echo "사용법 (Usage): ./$FILENAME [옵션]"
  echo ""
  echo "[설명]"
  echo "  Google Antigravity 공식 저장소에서 다운로드 가능한 Antigravity IDE 버전(2.x 이상) 목록을 조회하고,"
  echo "  사용자가 선택한 버전의 바이너리 패키지를 다운로드하여 시스템(/opt/antigravity-ide)에 설치합니다."
  echo "  전역 실행 심볼릭 링크, 샌드박스 보안 권한 및 데스크톱 바로가기를 자동으로 구성합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --version <버전>       원격 저장소에서 필터링할 버전 식별자 (예: 2, 2.5, 2.5.5)"
  echo "                         지정하지 않으면 2.x 이상의 전체 버전 목록을 출력합니다."
  echo "  --dry-run              실제 다운로드 및 설치를 진행하지 않고 실행될 명령어만 출력합니다."
  echo "  --help                 이 도움말을 출력하고 종료합니다."
  echo ""
  echo "[주의사항]"
  echo "  단축 옵션(-v, -d, -h 등)은 지원하지 않으므로 반드시 Long 옵션을 사용하십시오."
}

# 전역 상태 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
VERSION_INPUT=""
SELECTED_VERSION=""
SELECTED_BUILD_ID=""
SELECTED_DOWNLOAD_URL=""
TARGET_INSTALL_FILE=""
DRY_RUN=false

DOWNLOADED_TEMP_DIR=""
DOWNLOADED_TEMP_FILE=""

##
# 정상 종료, 오류 발생, 또는 사용자 취소 시 다운로드된 임시 파일을 100% 안전하게 정리합니다.
#
# @param 없음
#
# @return (임시 디렉터리 및 파일 제거)
##
cleanup_downloaded_file() {
  local exit_code=$?
  if [ -n "$DOWNLOADED_TEMP_DIR" ] && [ -d "$DOWNLOADED_TEMP_DIR" ]; then
    rm -rf "$DOWNLOADED_TEMP_DIR"
  fi
  exit "$exit_code"
}

trap 'cleanup_downloaded_file' EXIT
trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR
trap 'exit 130' INT
trap 'exit 143' TERM

##
# 기존 설치된 구버전 Antigravity IDE 및 충돌 바이너리를 시스템에서 완전히 삭제합니다.
# (Antigravity Core/Hub 환경은 보존합니다.)
#
# @param 없음
#
# @return (삭제 진행 상태 메시지 출력)
##
remove_legacy_antigravity_ide() {
  echo ">> [1/3] 기존 Antigravity IDE 및 충돌 파일 확인/삭제 중..."
  
  if [ -d "/opt/antigravity-ide" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo rm -rf /opt/antigravity-ide"
    else
      sudo rm -rf /opt/antigravity-ide
    fi
  fi

  if [ -L "/usr/local/bin/antigravity-ide" ] || [ -f "/usr/local/bin/antigravity-ide" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo rm -f /usr/local/bin/antigravity-ide"
    else
      sudo rm -f /usr/local/bin/antigravity-ide
    fi
  fi

  if [ -L "/usr/bin/antigravity-ide" ] || [ -f "/usr/bin/antigravity-ide" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo rm -f /usr/bin/antigravity-ide"
    else
      sudo rm -f /usr/bin/antigravity-ide
    fi
  fi
  
  if [ -d "/usr/share/antigravity-ide" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo rm -rf /usr/share/antigravity-ide"
    else
      sudo rm -rf /usr/share/antigravity-ide
    fi
  fi

  if [ -f "/usr/share/applications/antigravity-ide.desktop" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo rm -f /usr/share/applications/antigravity-ide.desktop"
    else
      sudo rm -f /usr/share/applications/antigravity-ide.desktop
    fi
  fi
  
  echo ">> 기존 Antigravity IDE 정리 완료."
}

##
# 신규 압축 파일을 해제하고, 구조를 동적으로 분석하여 /opt/antigravity-ide 로 배치합니다.
#
# @param $1 {string} 압축 파일 경로 (Dry-Run 모드 시 가상 경로 허용)
#
# @return (파일 설치 상태 메시지 출력)
##
install_new_antigravity_ide() {
  local target_file="$1"
  local temp_dir="/tmp/antigravity_ide_install_temp_$$"

  # 실제 실행(DRY_RUN=false) 시에만 엄격하게 파일 실재 여부 검증
  if [ "$DRY_RUN" = false ] && [ ! -f "$target_file" ]; then
    help "설치 대상 압축 파일을 찾을 수 없습니다 -> '$target_file'" "$LINENO"
    exit 1
  fi

  echo ">> [2/3] 압축 해제 및 디렉터리 구조 분석 진행 중..."
  
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] mkdir -p $temp_dir"
    echo "[DRY-RUN] tar -xzf \"$target_file\" -C $temp_dir"
    echo "[DRY-RUN] sudo mkdir -p /opt/antigravity-ide"
    echo "[DRY-RUN] # 단일 래퍼 디렉터리 감지 시 내부 항목만 /opt/antigravity-ide/ 로 복사"
    echo "[DRY-RUN] sudo cp -r $temp_dir/<extracted-dir>/. /opt/antigravity-ide/"
    echo "[DRY-RUN] sudo chmod -R 755 /opt/antigravity-ide"
    echo "[DRY-RUN] # Ubuntu 24.04 Electron 샌드박스 권한 설정 (chrome-sandbox 존재 시)"
    echo "[DRY-RUN] sudo chown root:root /opt/antigravity-ide/chrome-sandbox"
    echo "[DRY-RUN] sudo chmod 4755 /opt/antigravity-ide/chrome-sandbox"
    echo "[DRY-RUN] rm -rf $temp_dir"
  else
    mkdir -p "$temp_dir"
    tar -xzf "$target_file" -C "$temp_dir"

    sudo mkdir -p /opt/antigravity-ide

    local extracted_items=("$temp_dir"/*)
    local source_dir=""

    if [ ${#extracted_items[@]} -eq 1 ] && [ -d "${extracted_items[0]}" ]; then
      source_dir="${extracted_items[0]}"
    fi

    if [ -n "$source_dir" ]; then
      echo ">> 단일 래퍼 디렉터리 감지됨 [$(basename "$source_dir")] -> 내부 항목을 /opt/antigravity-ide/ 로 복사합니다."
      sudo cp -r "$source_dir"/. /opt/antigravity-ide/
    else
      echo ">> 추출된 전체 항목을 /opt/antigravity-ide/ 로 복사합니다."
      sudo cp -r "$temp_dir"/. /opt/antigravity-ide/
    fi

    sudo chmod -R 755 /opt/antigravity-ide

    if [ -f "/opt/antigravity-ide/chrome-sandbox" ]; then
      sudo chown root:root /opt/antigravity-ide/chrome-sandbox
      sudo chmod 4755 /opt/antigravity-ide/chrome-sandbox
    fi

    rm -rf "$temp_dir"
  fi

  echo ">> 파일 배치 완료."
}

##
# 전역 실행 심볼릭 링크(/usr/local/bin/antigravity-ide) 및 데스크톱 바로가기를 구성합니다.
#
# @param 없음
#
# @return (설정 완료 상태 메시지 출력)
##
configure_antigravity_ide_env() {
  echo ">> [3/3] 시스템 심볼릭 링크 및 데스크톱 환경(GUI) 등록 중..."
  
  local exec_bin=""
  if [ -f "/opt/antigravity-ide/antigravity-ide" ]; then
    exec_bin="/opt/antigravity-ide/antigravity-ide"
  elif [ -f "/opt/antigravity-ide/bin/antigravity-ide" ]; then
    exec_bin="/opt/antigravity-ide/bin/antigravity-ide"
  elif [ -f "/opt/antigravity-ide/code" ]; then
    exec_bin="/opt/antigravity-ide/code"
  fi

  if [ "$DRY_RUN" = true ] || [ -n "$exec_bin" ]; then
    local target_bin="${exec_bin:-/opt/antigravity-ide/antigravity-ide}"
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] sudo chmod +x $target_bin"
      echo "[DRY-RUN] sudo ln -sf $target_bin /usr/local/bin/antigravity-ide"
    else
      sudo chmod +x "$target_bin"
      sudo ln -sf "$target_bin" /usr/local/bin/antigravity-ide
    fi
  else
    echo "경고: 실행 바이너리를 찾을 수 없어 심볼릭 링크 생성을 건너뜁니다."
  fi

  local icon_path=""
  if [ "$DRY_RUN" = false ]; then
    if [ -f "/opt/antigravity-ide/resources/app/resources/linux/code.png" ]; then
      icon_path="/opt/antigravity-ide/resources/app/resources/linux/code.png"
    else
      icon_path=$(find /opt/antigravity-ide -maxdepth 5 -type f \( -name "*antigravity*.png" -o -name "*icon*.png" -o -name "code.png" \) 2>/dev/null | head -n 1 || true)
    fi
  fi
  local final_icon="${icon_path:-antigravity-ide}"

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] cat <<EOF | sudo tee /usr/share/applications/antigravity-ide.desktop > /dev/null"
    echo "[DRY-RUN] [Desktop Entry 내용을 /usr/share/applications/antigravity-ide.desktop 에 등록]"
  else
    cat <<EOF | sudo tee /usr/share/applications/antigravity-ide.desktop > /dev/null
[Desktop Entry]
Name=Antigravity IDE
Comment=Antigravity Agentic IDE
Exec=/usr/local/bin/antigravity-ide %F
Icon=$final_icon
Terminal=false
Type=Application
StartupNotify=true
StartupWMClass=antigravity-ide
Categories=Development;IDE;Utility;
MimeType=text/plain;inode/directory;
EOF
    sudo update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
  fi
  
  echo ">> Antigravity IDE 설정이 완료되었습니다."
}

##
# 전달된 버전 필터 조건(--version)의 유효성을 검증합니다.
# (2.x 이상 버전만 지원하므로 2로 시작하는 버전 형식인지 확인합니다.)
#
# @param $1 {string} 사용자가 입력한 버전 문자열
#
# @return (유효하지 않은 경우 오류 메시지 출력 후 종료)
##
validate_version_input() {
  local ver="$1"

  # 허용 문자 및 기본 버전 형식 검사 (숫자와 점으로 구성된 버전 식별자)
  if [[ ! "$ver" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "" >&2
    echo "================================================================================" >&2
    echo "❌ [오류] 잘못된 버전 형식입니다: '$ver'" >&2
    echo "   - 버전은 숫자와 점(.)으로만 지정해야 합니다. (예: 2, 2.5, 2.5.5)" >&2
    echo "================================================================================" >&2
    exit 1
  fi

  local major="${ver%%.*}"
  if (( major < 2 )); then
    echo "" >&2
    echo "================================================================================" >&2
    echo "❌ [오류] 지원하지 않는 메이저 버전입니다: '$ver'" >&2
    echo "   - 이 스크립트는 Antigravity IDE 2.x 이상 버전만 지원합니다. (예: --version 2)" >&2
    echo "================================================================================" >&2
    exit 1
  fi
}

##
# Google Antigravity IDE 공식 배포 저장소(Auto-Updater Releases API 및 배포 포털)에서
# 다운로드 가능한 2.x 이상의 linux-x64 버전 목록을 자동으로 수집하여 최신순으로 반환합니다.
#
# @param $1 {string} 필터링할 버전 접두사 (빈 문자열이면 2.x 이상 전체 조회)
#
# @return {string} "버전|빌드ID|다운로드URL" 형식의 줄바꿈 구분 목록 (표준 출력)
##
fetch_available_versions() {
  local filter_ver="${1:-}"

  if ! command -v python3 >/dev/null 2>&1; then
    help "원격 버전 목록 조회 및 파싱을 위해 'python3'가 시스템에 필요합니다." "$LINENO"
    exit 1
  fi

  python3 - "$filter_ver" <<'PY'
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

filter_ver = sys.argv[1].strip()
cdn_base = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable"
target_suffix = "/linux-x64/Antigravity%20IDE.tar.gz"

# key: (version, build_id) -> url
discovered = {}

def add_candidate(ver_str, build_str, custom_url=""):
    # 메이저 버전 2 이상만 허용
    parts = ver_str.split(".")
    try:
        if int(parts[0]) < 2:
            return
    except Exception:
        return

    # 필터 조건 확인: 정확히 일치하거나 '필터.'으로 시작하는 하위 버전 매칭
    if filter_ver:
        if not (ver_str == filter_ver or ver_str.startswith(filter_ver + ".")):
            return

    url = custom_url if custom_url else f"{cdn_base}/{ver_str}-{build_str}{target_suffix}"
    discovered[(ver_str, build_str)] = url

def fetch_url_text(url, timeout=10):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")

# 1. 공식 Auto-Updater Cloud Run Releases 엔드포인트 조회 (Antigravity IDE 릴리즈 목록)
try:
    rel_data = json.loads(fetch_url_text("https://antigravity-auto-updater-974169037036.us-central1.run.app/releases", timeout=10))
    if isinstance(rel_data, list):
        for item in rel_data:
            if isinstance(item, dict):
                v = str(item.get("version", "")).strip()
                b = str(item.get("execution_id") or item.get("build_id") or item.get("build") or "").strip()
                if re.match(r"^[0-9]+(?:\.[0-9]+)+$", v) and re.match(r"^[0-9]+$", b):
                    add_candidate(v, b)
except Exception:
    pass

# 2. 공식 다운로드 페이지(antigravity.google/download) 내 IDE 링크 보조 탐색
try:
    dl_html = fetch_url_text("https://antigravity.google/download", timeout=8)
    for m in re.finditer(r"https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/([0-9]+(?:\.[0-9]+)+)-([0-9]+)/linux-x64/Antigravity(?:%20|\s)IDE\.tar\.gz", dl_html):
        add_candidate(m.group(1), m.group(2))
except Exception:
    pass

# 3. GCS 버킷 내 antigravity-ide 프리픽스가 존재할 경우 보조 탐색
try:
    api_url = "https://storage.googleapis.com/storage/v1/b/antigravity-public/o?prefix=antigravity-ide/&delimiter=/"
    data = json.loads(fetch_url_text(api_url, timeout=8))
    for prefix in data.get("prefixes", []):
        m = re.match(r"^antigravity-ide/([0-9]+(?:\.[0-9]+)+)-([0-9]+)/$", prefix)
        if m:
            v, b = m.group(1), m.group(2)
            if (v, b) not in discovered:
                add_candidate(v, b)
except Exception:
    pass

def parse_ver_key(item):
    ver_str, build_str = item[0]
    ver_nums = [int(x) for x in ver_str.split(".")]
    try:
        build_num = int(build_str)
    except Exception:
        build_num = 0
    return (ver_nums, build_num)

# 최신 버전이 위로 오도록 내림차순 정렬
sorted_items = sorted(discovered.items(), key=parse_ver_key, reverse=True)

for (ver_str, build_str), url in sorted_items:
    print(f"{ver_str}|{build_str}|{url}")
PY
}

##
# 원격 URL로부터 설치용 압축 아카이브를 다운로드합니다.
# Dry-Run 모드인 경우 실제 다운로드를 수행하지 않고 curl 실행 명령만 시뮬레이션 출력합니다.
#
# @param $1 {string} 다운로드 대상 파일 URL
# @param $2 {string} 저장할 로컬 파일 경로
#
# @return (다운로드 완료 상태 출력)
##
download_installation_package() {
  local download_url="$1"
  local output_path="$2"

  echo ">> Antigravity IDE 패키지 다운로드 준비..."
  echo "   - 원격 주소 : $download_url"
  echo "   - 대상 경로 : $output_path"

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] curl -fSL --progress-bar \"$download_url\" -o \"$output_path\""
    return 0
  fi

  if ! curl -fSL --progress-bar "$download_url" -o "$output_path"; then
    echo "" >&2
    echo "================================================================================" >&2
    echo "❌ [오류] 설치 파일 다운로드에 실패하였습니다." >&2
    echo "   - 시도 URL: $download_url" >&2
    echo "   - 네트워크 연결 상태 및 저장소 주소를 확인하십시오." >&2
    echo "================================================================================" >&2
    exit 1
  fi

  if [ ! -s "$output_path" ]; then
    echo "❌ [오류] 다운로드된 파일이 비어 있습니다 (0 Byte) -> '$output_path'" >&2
    exit 1
  fi

  if ! tar -tzf "$output_path" >/dev/null 2>&1; then
    echo "❌ [오류] 다운로드된 파일이 손상되었거나 올바른 gzip 압축 형식이 아닙니다." >&2
    exit 1
  fi

  echo ">> 다운로드 및 파일 무결성 검증 완료."
}

##
# Google Antigravity IDE 원격 저장소에서 버전 목록을 조회하여 출력하고,
# 사용자가 선택한 버전의 설치 패키지를 다운로드(또는 Dry-Run 설정)합니다.
#
# @param 없음
#
# @return (전역 변수 SELECTED_VERSION, SELECTED_BUILD_ID, SELECTED_DOWNLOAD_URL, TARGET_INSTALL_FILE 확정)
##
resolve_install_source() {
  if [ -n "$VERSION_INPUT" ]; then
    validate_version_input "$VERSION_INPUT"
    echo ">> Google Antigravity 공식 저장소에서 'v${VERSION_INPUT}' 조건에 해당하는 Antigravity IDE 버전 목록을 조회합니다..."
  else
    echo ">> Google Antigravity 공식 저장소에서 다운로드 가능한 전체 Antigravity IDE 버전(2.x 이상) 목록을 조회합니다..."
  fi

  local raw_list=""
  if ! raw_list="$(fetch_available_versions "$VERSION_INPUT")"; then
    echo "" >&2
    echo "================================================================================" >&2
    echo "❌ [오류] 원격 저장소에서 버전 목록을 가져오는 중 오류가 발생했습니다." >&2
    echo "   - 네트워크 연결 상태를 확인하십시오." >&2
    echo "================================================================================" >&2
    exit 1
  fi

  local entries=()
  local line=""
  while IFS= read -r line; do
    [[ -n "$line" ]] && entries+=( "$line" )
  done <<< "$raw_list"

  if [ "${#entries[@]}" -eq 0 ]; then
    echo "" >&2
    echo "================================================================================" >&2
    if [ -n "$VERSION_INPUT" ]; then
      echo "❌ [오류] 요청하신 버전('${VERSION_INPUT}')에 해당하는 Antigravity IDE 설치 패키지를 찾을 수 없습니다." >&2
      echo "   - 입력한 버전 번호가 올바른지 확인하거나, '--version' 옵션 없이 실행하여 전체 버전 목록을 확인하십시오." >&2
    else
      echo "❌ [오류] 다운로드 가능한 Antigravity IDE (2.x 이상) 버전 목록을 찾을 수 없습니다." >&2
      echo "   - 네트워크 연결 상태 또는 공식 배포 저장소 상태를 확인하십시오." >&2
    fi
    echo "================================================================================" >&2
    exit 1
  fi

  echo ""
  echo "================================================================================"
  if [ -n "$VERSION_INPUT" ]; then
    echo " 📋 Antigravity IDE 다운로드 가능 버전 목록 (필터: v${VERSION_INPUT})"
  else
    echo " 📋 Antigravity IDE 다운로드 가능 버전 목록 (전체: 2.x 이상)"
  fi
  echo "--------------------------------------------------------------------------------"
  printf "  %-6s  %-22s  %-20s\n" "[번호]" "버전 (Version)" "빌드 ID (Build ID)"
  echo "--------------------------------------------------------------------------------"

  local idx=1
  local entry ver_str build_str dl_url label_ver
  for entry in "${entries[@]}"; do
    IFS='|' read -r ver_str build_str dl_url <<< "$entry"
    if [ "$idx" -eq 1 ]; then
      label_ver="${ver_str} (latest)"
    else
      label_ver="${ver_str}"
    fi
    printf "  [%4d]  %-22s  %-20s\n" "$idx" "$label_ver" "$build_str"
    ((idx++)) || true
  done
  echo "================================================================================"

  local total="${#entries[@]}"
  local choice=""
  while true; do
    printf "설치할 버전의 번호를 선택하세요 [1-%d] (종료: Enter): " "$total"
    if ! IFS= read -r choice; then
      echo ""
      echo ">> 입력이 종료되어 설치를 취소합니다."
      exit 0
    fi

    # 앞뒤 공백 제거
    choice="$(echo "$choice" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"

    if [[ -z "$choice" ]]; then
      echo ">> 사용자 요청에 의해 설치를 종료합니다."
      exit 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total )); then
      local selected_entry="${entries[$((choice - 1))]}"
      IFS='|' read -r SELECTED_VERSION SELECTED_BUILD_ID SELECTED_DOWNLOAD_URL <<< "$selected_entry"
      break
    fi

    echo "❗ 잘못된 선택입니다. 1부터 ${total} 사이의 번호를 입력하거나 Enter를 눌러 종료하십시오."
  done

  echo ""
  echo ">> [선택 완료] Antigravity IDE v${SELECTED_VERSION} (Build: ${SELECTED_BUILD_ID}) 설치를 진행합니다."

  if ! command -v curl >/dev/null 2>&1; then
    help "설치 패키지 다운로드를 위해 'curl' 바이너리가 시스템에 필요합니다." "$LINENO"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    TARGET_INSTALL_FILE="/tmp/antigravity_ide_v${SELECTED_VERSION}_${SELECTED_BUILD_ID}_dryrun.tar.gz"
    download_installation_package "$SELECTED_DOWNLOAD_URL" "$TARGET_INSTALL_FILE"
    return 0
  fi

  DOWNLOADED_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/antigravity_ide_dl_XXXXXX")"
  DOWNLOADED_TEMP_FILE="${DOWNLOADED_TEMP_DIR}/antigravity-ide-v${SELECTED_VERSION}-${SELECTED_BUILD_ID}.tar.gz"

  download_installation_package "$SELECTED_DOWNLOAD_URL" "$DOWNLOADED_TEMP_FILE"
  TARGET_INSTALL_FILE="$DOWNLOADED_TEMP_FILE"
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 명령줄 인자 배열
#
# @return (없음)
##
main() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --version)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          echo "" >&2
          echo "================================================================================" >&2
          echo "❌ [오류] '--version' 옵션에는 버전 값을 지정해야 합니다. (예: --version 2, --version 2.5.5)" >&2
          echo "   - 전체 버전 목록에서 선택하려면 '--version' 옵션 없이 실행하십시오." >&2
          echo "================================================================================" >&2
          exit 1
        fi
        VERSION_INPUT="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift 1
        ;;
      --help)
        help "" ""
        exit 0
        ;;
      -*)
        help "지원하지 않는 옵션입니다 (단축 옵션은 지원하지 않습니다) -> $1" "$LINENO"
        exit 1
        ;;
      *)
        help "잘못된 파라미터 형식입니다 -> $1" "$LINENO"
        exit 1
        ;;
    esac
  done

  # 설치 소스 확정 (원격 버전 목록 조회 -> 사용자 선택 -> 다운로드)
  resolve_install_source

  if [ "$DRY_RUN" = true ]; then
    echo "================================================================================"
    echo " [DRY-RUN MODE] 실제 시스템은 변경되지 않으며, 실행될 명령어만 출력됩니다."
    echo "================================================================================"
  fi

  remove_legacy_antigravity_ide
  install_new_antigravity_ide "$TARGET_INSTALL_FILE"
  configure_antigravity_ide_env

  echo "================================================================================"
  echo "🎉 [SUCCESS] Antigravity IDE 설치 및 환경 설정이 완료되었습니다."
  echo "================================================================================"
}

main "$@"
exit 0
