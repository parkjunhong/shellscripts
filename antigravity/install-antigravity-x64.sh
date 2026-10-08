#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : install antigravity.
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
    echo "  -f, --file <path>    다운로드한 신규 Antigravity 압축 파일(.tar.gz) 경로"
    echo "  -d, --dry-run        실제 설치를 진행하지 않고 실행될 명령어만 출력합니다."
    echo "  -h, --help           이 도움말을 출력합니다."
}

##
# 기존 설치된 구버전 Antigravity 및 충돌 바이너리, 손상된 아이콘을 시스템에서 정리합니다.
#
# @param none
#
# @return 정리 진행 상태 메시지 출력
##
remove_legacy_antigravity() {
    echo ">> [1/3] 기존 Antigravity 및 충돌 파일 확인/삭제 중..."
    
    # 1. /opt/antigravity 디렉토리 정리
    if [ -d "/opt/antigravity" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -rf /opt/antigravity"
        else
            sudo rm -rf /opt/antigravity
        fi
    fi

    # 2. /usr/local/bin 심볼릭 링크 정리
    if [ -L "/usr/local/bin/antigravity" ] || [ -f "/usr/local/bin/antigravity" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/local/bin/antigravity"
        else
            sudo rm -f /usr/local/bin/antigravity
        fi
    fi

    # 3. /usr/bin 충돌 링크 정리 (/usr/share/antigravity/bin/antigravity 링크)
    if [ -L "/usr/bin/antigravity" ] || [ -f "/usr/bin/antigravity" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/bin/antigravity"
        else
            sudo rm -f /usr/bin/antigravity
        fi
    fi
    
    # 4. /usr/share 레거시 패키지 디렉토리 정리
    if [ -d "/usr/share/antigravity" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -rf /usr/share/antigravity"
        else
            sudo rm -rf /usr/share/antigravity
        fi
    fi

    # 5. 기존 desktop 엔트리 파일 정리
    if [ -f "/usr/share/applications/antigravity.desktop" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/share/applications/antigravity.desktop"
        else
            sudo rm -f /usr/share/applications/antigravity.desktop
        fi
    fi

    # 6. 이전 손상된 시스템 아이콘 정리
    if [ -f "/usr/share/icons/hicolor/512x512/apps/antigravity.png" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo rm -f /usr/share/icons/hicolor/512x512/apps/antigravity.png"
        else
            sudo rm -f /usr/share/icons/hicolor/512x512/apps/antigravity.png
        fi
    fi
    
    echo ">> 기존 버전 정리 완료."
}

##
# 신규 압축 파일을 해제하고, 최상위 래퍼 디렉토리(antigravity-x64) 내부 항목만 /opt/antigravity 로 복사합니다.
#
# @param $1 {String} 다운로드 받은 tar.gz 파일 경로
#
# @return 파일 설치 상태 메시지 출력
##
install_new_antigravity() {
    local target_file="$1"
    local temp_dir="/tmp/antigravity_core_install"

    if [ ! -f "$target_file" ]; then
        help "파일을 찾을 수 없습니다: $target_file" "${LINENO}"
        exit 1
    fi

    echo ">> [2/3] 압축 해제 및 파일 배치 진행 중..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] mkdir -p $temp_dir"
        echo "[DRY-RUN] tar -xzf \"$target_file\" -C $temp_dir"
        echo "[DRY-RUN] sudo mkdir -p /opt/antigravity"
        echo "[DRY-RUN] # antigravity-x64 내부 항목만 /opt/antigravity/ 로 배치 (디렉토리 중첩 방지)"
        echo "[DRY-RUN] sudo cp -r $temp_dir/antigravity-x64/. /opt/antigravity/"
        echo "[DRY-RUN] sudo chmod -R 755 /opt/antigravity"
        echo "[DRY-RUN] # Ubuntu 24.04 샌드박스 보안 권한 부여"
        echo "[DRY-RUN] sudo chown root:root /opt/antigravity/chrome-sandbox"
        echo "[DRY-RUN] sudo chmod 4755 /opt/antigravity/chrome-sandbox"
        echo "[DRY-RUN] rm -rf $temp_dir"
    else
        mkdir -p "$temp_dir"
        tar -xzf "$target_file" -C "$temp_dir"

        sudo mkdir -p /opt/antigravity

        # 실제 추출된 최상위 디렉토리(antigravity-x64) 감지
        local source_dir=""
        if [ -d "$temp_dir/antigravity-x64" ]; then
            source_dir="$temp_dir/antigravity-x64"
        elif [ -d "$temp_dir/Antigravity-x64" ]; then
            source_dir="$temp_dir/Antigravity-x64"
        else
            local items=("$temp_dir"/*)
            if [ ${#items[@]} -eq 1 ] && [ -d "${items[0]}" ]; then
                source_dir="${items[0]}"
            fi
        fi

        if [ -n "$source_dir" ]; then
            echo ">> 추출 디렉토리 [$(basename "$source_dir")] 내부 항목들을 /opt/antigravity/ 로 배치합니다."
            sudo cp -r "$source_dir"/. /opt/antigravity/
        else
            echo ">> 추출된 전체 항목을 /opt/antigravity/ 로 배치합니다."
            sudo cp -r "$temp_dir"/. /opt/antigravity/
        fi

        sudo chmod -R 755 /opt/antigravity

        # Ubuntu 24.04 환경을 위한 chrome-sandbox 권한 보정
        if [ -f "/opt/antigravity/chrome-sandbox" ]; then
            sudo chown root:root /opt/antigravity/chrome-sandbox
            sudo chmod 4755 /opt/antigravity/chrome-sandbox
        fi

        rm -rf "$temp_dir"
    fi

    echo ">> 파일 배치 완료."
}

##
# 무결성이 검증된 PNG 아이콘을 추출/설정하고 전역 심볼릭 링크 및 데스크톱 엔트리를 구성합니다.
#
# @param none
#
# @return 설정 완료 상태 메시지 출력
##
configure_antigravity_env() {
    echo ">> [3/3] 시스템 환경 변수 및 GUI 바로가기(아이콘 복구 포함) 등록 중..."
    
    local exec_bin="/opt/antigravity/antigravity"
    local asar_file="/opt/antigravity/resources/app.asar"
    local icon_file="/opt/antigravity/icon.png"

    # 1. 심볼릭 링크 생성
    if [ "$DRY_RUN" = true ] || [ -f "$exec_bin" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] sudo ln -sf $exec_bin /usr/local/bin/antigravity"
        else
            sudo ln -sf "$exec_bin" /usr/local/bin/antigravity
        fi
    else
        echo "경고: 실행 파일($exec_bin)을 찾을 수 없어 심볼릭 링크 생성을 건너뜁니다."
    fi

    # 2. PNG 바이너리 청크 파서 기반 아이콘 추출 및 무결성 검증
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] # app.asar 내 PNG 바이너리 청크 무결성 검증 파싱 수행"
        echo "[DRY-RUN] sudo python3 - \"$asar_file\" \"$icon_file\""
        echo "[DRY-RUN] # 추출 실패 시 /opt/antigravity-ide 공식 아이콘으로 대체"
        echo "[DRY-RUN] sudo cp $icon_file /usr/share/icons/hicolor/512x512/apps/antigravity.png"
    else
        if [ -f "$asar_file" ]; then
            echo ">> app.asar 내에서 정밀 PNG 청크 파싱을 통해 아이콘을 추출합니다..."
            sudo python3 - "$asar_file" "$icon_file" <<'PY'
import os, struct, sys

asar_path = sys.argv[1]
out_path = sys.argv[2]

if not os.path.exists(asar_path):
    sys.exit(1)

with open(asar_path, "rb") as f:
    data = f.read()

png_magic = b"\x89PNG\r\n\x1a\n"
start = 0
candidates = []

# PNG 매직 넘버 검색 후 IEND 청크까지 완전한 블록 슬라이싱
while True:
    pos = data.find(png_magic, start)
    if pos == -1:
        break
    curr = pos + 8
    valid = False
    width, height = 0, 0
    while curr + 8 <= len(data):
        chunk_len = struct.unpack(">I", data[curr:curr+4])[0]
        chunk_type = data[curr+4:curr+8]
        chunk_total = 8 + chunk_len + 4
        if curr + chunk_total > len(data):
            break
        if chunk_type == b"IHDR" and chunk_len >= 8:
            width, height = struct.unpack(">II", data[curr+8:curr+16])
        curr += chunk_total
        if chunk_type == b"IEND":
            valid = True
            break
    if valid:
        chunk_data = data[pos:curr]
        candidates.append((chunk_data, width, height, len(chunk_data)))
        start = curr
    else:
        start = pos + 8

if candidates:
    # 정방형 고해상도 아이콘 우선 선택
    square_candidates = [c for c in candidates if c[1] == c[2] and c[1] >= 64]
    if square_candidates:
        best = max(square_candidates, key=lambda c: (c[1], c[3]))
    else:
        best = max(candidates, key=lambda c: c[3])
    with open(out_path, "wb") as f:
        f.write(best[0])
PY
        fi

        # MIME 타입 검증 및 폴백 처리
        local is_valid_png=false
        if [ -f "$icon_file" ]; then
            local mime=$(file -b --mime-type "$icon_file" 2>/dev/null)
            if [ "$mime" = "image/png" ]; then
                is_valid_png=true
            else
                echo "경고: 추출된 파일이 유효한 PNG가 아니므로 손상된 파일을 제거합니다."
                sudo rm -f "$icon_file"
            fi
        fi

        # asar 추출 실패 시 Antigravity IDE 아이콘으로 폴백
        if [ "$is_valid_png" = false ]; then
            echo ">> Antigravity IDE 공식 아이콘 대체 탐색 중..."
            local fallback_icon=$(find /opt/antigravity-ide -type f \( -name "code.png" -o -name "*antigravity*.png" -o -name "*icon*.png" \) 2>/dev/null | head -n 1)
            if [ -n "$fallback_icon" ] && [ -f "$fallback_icon" ]; then
                echo ">> Antigravity IDE 공식 아이콘을 대체 등록합니다: $fallback_icon"
                sudo cp "$fallback_icon" "$icon_file"
                is_valid_png=true
            fi
        fi

        # 최종 시스템 아이콘 테마 경로 등록
        if [ "$is_valid_png" = true ]; then
            sudo mkdir -p /usr/share/icons/hicolor/512x512/apps
            sudo cp "$icon_file" /usr/share/icons/hicolor/512x512/apps/antigravity.png
        fi
    fi

    # 3. Desktop Entry 파일 생성
    local icon_entry=""
    if [ "$DRY_RUN" = true ] || [ -f "$icon_file" ]; then
        icon_entry="Icon=/opt/antigravity/icon.png"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] cat <<EOF | sudo tee /usr/share/applications/antigravity.desktop > /dev/null"
        echo "[DRY-RUN] [Desktop Entry 내용을 /usr/share/applications/antigravity.desktop 에 등록]"
    else
        cat <<EOF | sudo tee /usr/share/applications/antigravity.desktop > /dev/null
[Desktop Entry]
Name=Antigravity
Comment=Antigravity Platform
Exec=/usr/local/bin/antigravity %U
${icon_entry}
Terminal=false
Type=Application
Categories=Development;Utility;
EOF
        sudo update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    fi
    
    echo ">> 환경 설정 및 아이콘 등록이 완료되었습니다."
}

if [ $# -eq 0 ]; then
    help "파라미터가 누락되었습니다." "${LINENO}"
    exit 1
fi

FILE_PATH="./Antigravity.tar.gz"

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

remove_legacy_antigravity
install_new_antigravity "$FILE_PATH"
configure_antigravity_env

exit 0
