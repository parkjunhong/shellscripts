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
  echo "  Antigravity IDE 바이너리 패키지를 시스템(/opt/antigravity-ide)에 설치하고"
  echo "  전역 실행 심볼릭 링크, 샌드박스 보안 권한 및 데스크톱 바로가기를 구성합니다."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --file <경로>          설치할 로컬 Antigravity IDE 압축 파일(.tar.gz) 경로"
  echo "  --version <버전>       원격 저장소에서 다운로드하여 설치할 버전 번호 (예: 2, 2.1.0)"
  echo "  --dry-run              실제 설치를 진행하지 않고 실행될 명령어만 출력합니다."
  echo "  --help                 이 도움말을 출력하고 종료합니다."
  echo ""
  echo "[주의사항]"
  echo "  단축 옵션(-f, -v, -d, -h 등)은 지원하지 않으므로 반드시 Long 옵션을 사용하십시오."
  echo "  --file 옵션이 전달되지 않은 경우에만 --version 옵션을 통해 원격에서 파일을 다운로드하여 설치합니다."
}

# 전역 상태 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
FILE_INPUT=""
VERSION_INPUT=""
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
# 지정한 버전에 해당하는 다운로드 메타데이터 파일(.url)을 조회하여 실제 다운로드 URL을 반환합니다.
#
# @param $1 {string} 버전 식별자 (예: 2, 2.1.0)
#
# @return {string} 정제된 실제 다운로드 URL (표준 출력)
##
fetch_download_url() {
  local ver="$1"

  if [[ ! "$ver" =~ ^[0-9a-zA-Z._-]+$ ]]; then
    help "유효하지 않은 버전 문자열 형식입니다 -> '$ver'" "$LINENO"
    exit 1
  fi

  local meta_url="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/antigravity/download-antigravity-ide-v${ver}.url"
  echo ">> 원격 버전 메타데이터 확인 중: $meta_url" >&2

  if ! command -v curl >/dev/null 2>&1; then
    help "원격 버전 조회를 위해 'curl' 바이너리가 시스템에 필요합니다." "$LINENO"
    exit 1
  fi

  local raw_content=""
  if ! raw_content="$(curl -fsSL --connect-timeout 10 "$meta_url" 2>/dev/null)"; then
    echo "" >&2
    echo "================================================================================" >&2
    echo "❌ [오류] 지원하지 않는 버전입니다: 'v${ver}'" >&2
    echo "   - 원격 메타데이터 파일을 찾을 수 없습니다 -> $meta_url" >&2
    echo "   - 제공되는 버전 정보를 다시 확인한 후 실행하십시오." >&2
    echo "================================================================================" >&2
    exit 1
  fi

  local clean_url=""
  clean_url="$(echo "$raw_content" | tr -d '\r' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | head -n 1)"

  if [[ -z "$clean_url" || ! "$clean_url" =~ ^https?:// ]]; then
    echo "================================================================================" >&2
    echo "❌ [오류] 원격 메타데이터 파일 내 유효한 다운로드 URL이 존재하지 않습니다." >&2
    echo "   - 조회 URL: $meta_url" >&2
    echo "   - 내용: '$clean_url'" >&2
    echo "================================================================================" >&2
    exit 1
  fi

  echo "$clean_url"
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
# 전달된 옵션을 분석하여 로컬 파일 또는 원격 다운로드 방식을 통해 최종 설치 파일을 결정합니다.
#
# @param 없음
#
# @return (전역 변수 TARGET_INSTALL_FILE 확정)
##
resolve_install_source() {
  # 1. --file 옵션이 우선적으로 전달된 경우 (Dry-Run 여부와 무관하게 로컬 파일 실재성 검증)
  if [ -n "$FILE_INPUT" ]; then
    if [ ! -f "$FILE_INPUT" ]; then
      help "지정한 로컬 설치 파일이 존재하지 않습니다 -> '$FILE_INPUT'" "$LINENO"
      exit 1
    fi
    if [ ! -r "$FILE_INPUT" ]; then
      help "지정한 로컬 설치 파일에 대한 읽기 권한이 없습니다 -> '$FILE_INPUT'" "$LINENO"
      exit 1
    fi
    TARGET_INSTALL_FILE="$FILE_INPUT"
    echo ">> [소스 확인] 지정된 로컬 파일로 설치를 진행합니다: $TARGET_INSTALL_FILE"
    return 0
  fi

  # 2. --file 옵션이 없고 --version 옵션이 전달된 경우
  if [ -n "$VERSION_INPUT" ]; then
    local target_dl_url=""
    target_dl_url="$(fetch_download_url "$VERSION_INPUT")"

    if [ "$DRY_RUN" = true ]; then
      TARGET_INSTALL_FILE="/tmp/antigravity_ide_v${VERSION_INPUT}_dryrun.tar.gz"
      echo ">> [소스 확인] 원격 v${VERSION_INPUT} 버전 패키지를 다운로드하여 설치할 예정입니다."
      echo "   - 다운로드 대상 URL: $target_dl_url"
      download_installation_package "$target_dl_url" "$TARGET_INSTALL_FILE"
      return 0
    fi

    DOWNLOADED_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/antigravity_ide_dl_XXXXXX")"
    DOWNLOADED_TEMP_FILE="${DOWNLOADED_TEMP_DIR}/antigravity-ide-v${VERSION_INPUT}.tar.gz"

    download_installation_package "$target_dl_url" "$DOWNLOADED_TEMP_FILE"
    TARGET_INSTALL_FILE="$DOWNLOADED_TEMP_FILE"
    return 0
  fi

  # 3. --file 과 --version 둘 다 없는 경우
  help "설치할 로컬 파일(--file) 또는 버전(--version)을 지정해야 합니다." "$LINENO"
  exit 1
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 명령줄 인자 배열
#
# @return (없음)
##
main() {
  if [ $# -eq 0 ]; then
    help "실행 파라미터가 누락되었습니다." "$LINENO"
    exit 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --file)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--file 옵션에는 파일 경로를 지정해야 합니다." "$LINENO"
          exit 1
        fi
        FILE_INPUT="$2"
        shift 2
        ;;
      --version)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--version 옵션에는 버전 식별자를 지정해야 합니다 (예: 2)." "$LINENO"
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

  # 설치 소스 확정 (로컬 파일 검증 또는 원격 버전 다운로드)
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
