#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : install antigravity-ide.
# @license : Apache License 2.0
# @since : 2026-10-01
# @desc : support Ubuntu 24.04, RHEL, Oracle Linux, RockyOS
# @installation :
# 1. insert 'source <path>/<파일명>" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into etc/bashrc for all users.
# =======================================

FILENAME=$(basename $0)
DRY_RUN=false

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
        for func in ${FUNCNAME[@]:1}
        do
            printf "$formatr" "["$idx"]" $func
            ((idx++))
        done
        printf "$formatl" "cause" "$1"
        echo "================================================================================"
    fi
    echo
    # TODO: Usage 내용 작성
    echo "Usage: ./$FILENAME [options]"
    echo "Options:"
    echo "  -f, --file <path>    다운로드한 Antigravity IDE 압축 파일(.tar.gz) 경로"
    echo "  -d, --dry-run        실제 설치를 진행하지 않고 실행될 명령어만 출력합니다."
    echo "  -h, --help           이 도움말을 출력합니다."
}

##
# 기존 설치된 구버전 Antigravity IDE 및 충돌 바이너리를 시스템에서 완전히 삭제합니다.
# (Antigravity Core/Hub 환경은 보존합니다.)
#
# @param none
#
# @return 삭제 진행 상태 메시지 출력
##
remove_legacy_antigravity_ide() {
    echo ">> [1/3] 기존 Antigravity IDE 및 충돌 파일 확인/삭제 중..."
    
    # 1. /opt/antigravity-ide 디렉토리 정리
    if [ -d "/opt/antigravity-ide" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -rf /opt/antigravity-ide"
        else
            sudo rm -rf /opt/antigravity-ide
        fi
    fi

    # 2. /usr/local/bin 심볼릭 링크 정리
    if [ -L "/usr/local/bin/antigravity-ide" ] || [ -f "/usr/local/bin/antigravity-ide" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/local/bin/antigravity-ide"
        else
            sudo rm -f /usr/local/bin/antigravity-ide
        fi
    fi

    # 3. /usr/bin 충돌 링크 정리
    if [ -L "/usr/bin/antigravity-ide" ] || [ -f "/usr/bin/antigravity-ide" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/bin/antigravity-ide"
        else
            sudo rm -f /usr/bin/antigravity-ide
        fi
    fi
    
    # 4. /usr/share 레거시 데이터 정리
    if [ -d "/usr/share/antigravity-ide" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -rf /usr/share/antigravity-ide"
        else
            sudo rm -rf /usr/share/antigravity-ide
        fi
    fi

    # 5. 데스크톱 엔트리 파일 정리
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
# @param $1 {String} 다운로드 받은 tar.gz 파일 경로
#
# @return 파일 설치 상태 메시지 출력
##
install_new_antigravity_ide() {
    local target_file="$1"
    local temp_dir="/tmp/antigravity_ide_install_temp"

    if [ ! -f "$target_file" ]; then
        help "파일을 찾을 수 없습니다: $target_file" "${LINENO}"
        exit 1
    fi

    echo ">> [2/3] 압축 해제 및 디렉토리 구조 분석 진행 중..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] mkdir -p $temp_dir"
        echo "[DRY-RUN] tar -xzf \"$target_file\" -C $temp_dir"
        echo "[DRY-RUN] sudo mkdir -p /opt/antigravity-ide"
        echo "[DRY-RUN] # 단일 래퍼 디렉토리 감지 시 내부 항목만 /opt/antigravity-ide/ 로 복사"
        echo "[DRY-RUN] sudo chmod -R 755 /opt/antigravity-ide"
        echo "[DRY-RUN] # Ubuntu 24.04 Electron 샌드박스 권한 설정 (chrome-sandbox 존재 시)"
        echo "[DRY-RUN] sudo chown root:root /opt/antigravity-ide/chrome-sandbox"
        echo "[DRY-RUN] sudo chmod 4755 /opt/antigravity-ide/chrome-sandbox"
        echo "[DRY-RUN] rm -rf $temp_dir"
    else
        mkdir -p "$temp_dir"
        tar -xzf "$target_file" -C "$temp_dir"

        sudo mkdir -p /opt/antigravity-ide

        # 임시 디렉토리 내부 항목 검사 (공백 포함 디렉토리명 대응)
        local extracted_items=("$temp_dir"/*)
        local source_dir=""

        if [ ${#extracted_items[@]} -eq 1 ] && [ -d "${extracted_items[0]}" ]; then
            source_dir="${extracted_items[0]}"
        fi

        if [ -n "$source_dir" ]; then
            echo ">> 단일 래퍼 디렉토리 감지됨 [$(basename "$source_dir")] &rarr; 내부 항목을 /opt/antigravity-ide/ 로 복사합니다."
            sudo cp -r "$source_dir"/. /opt/antigravity-ide/
        else
            echo ">> 추출된 전체 항목을 /opt/antigravity-ide/ 로 복사합니다."
            sudo cp -r "$temp_dir"/. /opt/antigravity-ide/
        fi

        sudo chmod -R 755 /opt/antigravity-ide

        # Ubuntu 24.04 환경을 위한 chrome-sandbox 보안 권한 설정
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
# @param none
#
# @return 설정 완료 상태 메시지 출력
##
configure_antigravity_ide_env() {
    echo ">> [3/3] 시스템 심볼릭 링크 및 데스크톱 환경(GUI) 등록 중..."
    
    # 실행 바이너리 위치 탐색
    local exec_bin=""
    if [ -f "/opt/antigravity-ide/antigravity-ide" ]; then
        exec_bin="/opt/antigravity-ide/antigravity-ide"
    elif [ -f "/opt/antigravity-ide/bin/antigravity-ide" ]; then
        exec_bin="/opt/antigravity-ide/bin/antigravity-ide"
    elif [ -f "/opt/antigravity-ide/code" ]; then
        exec_bin="/opt/antigravity-ide/code"
    fi

    # --dry-run 모드이거나 유효한 바이너리가 감지된 경우
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

    # 패키지 내부 아이콘 파일 탐색 (VS Code 리소스 또는 png/svg)
    local icon_path=""
    if [ "$DRY_RUN" = false ]; then
        if [ -f "/opt/antigravity-ide/resources/app/resources/linux/code.png" ]; then
            icon_path="/opt/antigravity-ide/resources/app/resources/linux/code.png"
        else
            icon_path=$(find /opt/antigravity-ide -maxdepth 5 -type f \( -name "*antigravity*.png" -o -name "*icon*.png" -o -name "code.png" \) 2>/dev/null | head -n 1)
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
    fi
    
    echo ">> Antigravity IDE 설정이 완료되었습니다."
}

if [ $# -eq 0 ]; then
    help "파라미터가 누락되었습니다." "${LINENO}"
    exit 1
fi

FILE_PATH="./Antigravity-IDE.tar.gz"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            help
            exit 0
            ;;
        -f|--file)
            FILE_PATH="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift 1
            ;;
        *)
            help "알 수 없는 옵션입니다: $1" "${LINENO}"
            exit 1
            ;;
    esac
done

if [ -z "$FILE_PATH" ]; then
    help "설치할 파일을 지정해야 합니다." "${LINENO}"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    echo "================================================================================"
    echo " [DRY-RUN MODE] 실제 시스템은 변경되지 않으며, 실행될 명령어만 출력됩니다."
    echo "================================================================================"
fi

remove_legacy_antigravity_ide
install_new_antigravity_ide "$FILE_PATH"
configure_antigravity_ide_env

exit 0
