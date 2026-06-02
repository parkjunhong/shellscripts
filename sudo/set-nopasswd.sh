#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-06-02
# @desc     : support RHEL 7+, Oracle Linux 7+, Ubuntu 18.04+, RockyOS 8+
# @installation : 
#   1. insert 'source <path>/<파일명>" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/<파일명>' into 
#      etc/bashrc for all users.
# =======================================

FILENAME=$(basename $0)

help(){
  if [ ! -z "$1" ];
  then
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
  echo "사용법(Usage): $FILENAME [옵션] [명령어1] [명령어2] ..."
  echo "지정된 계정에 대해 특정 명령어 그룹의 NOPASSWD 권한을 부여하며, 기존 목록과 병합합니다."
  echo "명령어가 존재하지 않는 경우 설치를 제안합니다."
  echo ""
  echo "옵션:"
  echo "  -u, --user <계정명>    권한을 부여할 대상 시스템 계정 (필수)"
  echo "  -h, --help             도움말 출력"
  echo ""
  echo "예시:"
  echo "  $FILENAME -u admin cat /usr/bin/systemctl htop"
}

check_user_exists() {
  local target_user="$1"
  if id "$target_user" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

TARGET_USER=""
COMMANDS=()

# 파라미터 파싱
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--user)
      TARGET_USER="$2"
      shift 2
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -*)
      help "지원하지 않는 파라미터입니다: $1" "${BASH_LINENO[0]}"
      exit 1
      ;;
    *)
      COMMANDS+=("$1")
      shift
      ;;
  esac
done

if [ -z "$TARGET_USER" ]; then
  help "필수 파라미터인 대상 계정(-u 또는 --user)이 입력되지 않았습니다." "${BASH_LINENO[0]}"
  exit 1
fi

if ! check_user_exists "$TARGET_USER"; then
  help "입력된 계정($TARGET_USER)이 시스템에 존재하지 않습니다." "${BASH_LINENO[0]}"
  exit 1
fi

if [ ${#COMMANDS[@]} -eq 0 ]; then
  help "적용할 명령어가 하나 이상 입력되어야 합니다." "${BASH_LINENO[0]}"
  exit 1
fi

# 1. 패키지 관리자 감지
PKG_MGR="unknown"
if command -v dnf &>/dev/null; then PKG_MGR="dnf"
elif command -v yum &>/dev/null; then PKG_MGR="yum"
elif command -v apt-get &>/dev/null; then PKG_MGR="apt-get"
fi

# 2. 기존 sudoers 파일 파싱 (중복 검사를 위함)
SUDOERS_DIR="/etc/sudoers.d"
SUDOERS_FILE="${SUDOERS_DIR}/${TARGET_USER}_custom_nopasswd"
FINAL_CMDS=()

if sudo test -f "$SUDOERS_FILE"; then
  CMDS_STR=$(sudo awk -F'NOPASSWD: *' '/NOPASSWD:/ {print $2}' "$SUDOERS_FILE")
  IFS=',' read -ra CMDS_ARR <<< "$CMDS_STR"
  for cmd in "${CMDS_ARR[@]}"; do
    cmd=$(echo "$cmd" | xargs)
    if [ -n "$cmd" ]; then
      FINAL_CMDS+=("$cmd")
    fi
  done
fi

# 3. Phase 1: 명령어 존재 여부 확인 및 대화형 설치
echo "======================================================================"
echo "[1단계] 명령어 존재 여부 검증 및 설치"
echo "======================================================================"
RESOLVED_COMMANDS=()

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  resolved=""
  is_path=0
  
  if [[ "$cmd" == */* ]]; then
    is_path=1
    if [ -e "$cmd" ]; then
      resolved=$(realpath "$cmd" 2>/dev/null || readlink -f "$cmd" 2>/dev/null)
    fi
  else
    resolved=$(command -v "$cmd" 2>/dev/null)
  fi

  # 명령어가 시스템에 존재하지 않는 경우
  if [ -z "$resolved" ] || [ ! -e "$resolved" ]; then
    # 경로 형태가 아니고, 패키지 관리자를 사용할 수 있는 경우에만 설치 검증
    if [ "$is_path" -eq 0 ] && [ "$PKG_MGR" != "unknown" ]; then
      is_installable=0
      
      if [ "$PKG_MGR" == "apt-get" ]; then
        if apt-cache show "$cmd" &>/dev/null; then is_installable=1; fi
      elif [[ "$PKG_MGR" == "dnf" || "$PKG_MGR" == "yum" ]]; then
        if $PKG_MGR info "$cmd" &>/dev/null; then is_installable=1; fi
      fi

      if [ "$is_installable" -eq 1 ]; then
        echo ""
        read -p "  [?] '$cmd' 명령어를 찾을 수 없습니다. 패키지 관리자($PKG_MGR)로 설치하시겠습니까? (y/N): " yn
        case $yn in
          [Yy]* ) 
            echo "  >>> '$cmd' 설치를 진행합니다..."
            sudo $PKG_MGR install -y "$cmd"
            
            # 설치 후 재검증
            resolved=$(command -v "$cmd" 2>/dev/null)
            if [ -n "$resolved" ] && [ -e "$resolved" ]; then
              echo "  >>> [성공] 설치 완료 ($resolved)"
            else
              echo "  >>> [실패] 설치되었으나 실행 파일을 찾을 수 없습니다."
            fi
            ;;
          * ) 
            echo "  >>> 설치를 건너뜁니다."
            ;;
        esac
      fi
    fi
  fi
  RESOLVED_COMMANDS[$i]="$resolved"
done
echo ""

# 4. Phase 2: 중복 판별 및 병합 결과 출력
echo "======================================================================"
echo "[2단계] 명령어 병합 및 최종 결과"
echo "======================================================================"
NEW_ADDED=0

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  resolved="${RESOLVED_COMMANDS[$i]}"
  
  if [ -n "$resolved" ] && [ -e "$resolved" ]; then
    is_duplicate=0
    for ext_cmd in "${FINAL_CMDS[@]}"; do
      if [ "$ext_cmd" == "$resolved" ]; then
        is_duplicate=1
        break
      fi
    done

    if [ "$is_duplicate" -eq 1 ]; then
      printf "%-19s -> %-26s (%s)\n" "$cmd" "$resolved" "중복 (제외)"
    else
      printf "%-19s -> %-26s (%s)\n" "$cmd" "$resolved" "신규 (허용)"
      FINAL_CMDS+=("$resolved")
      NEW_ADDED=1
    fi
  else
    printf "%-19s -> %-26s (%s)\n" "$cmd" "NOT_EXIST" "거부"
  fi
done
echo "======================================================================"
echo ""

if [ "$NEW_ADDED" -eq 0 ]; then
  echo "[안내] 새로 추가할 유효한 명령어가 없거나 모두 중복되어 작업을 종료합니다."
  exit 0
fi

if ! sudo test -d "$SUDOERS_DIR"; then
  sudo mkdir -p "$SUDOERS_DIR"
fi

JOINED_CMDS=$(printf ", %s" "${FINAL_CMDS[@]}")
JOINED_CMDS=${JOINED_CMDS:2}

echo "${TARGET_USER} ALL=(ALL) NOPASSWD: ${JOINED_CMDS}" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"

sudo visudo -c -f "$SUDOERS_FILE" &>/dev/null
if [ $? -eq 0 ]; then
  echo "[성공] '${TARGET_USER}' 계정에 대한 NOPASSWD 적용(병합)이 완료되었습니다."
  echo ""
  echo "----------------------------------------------------------------------"
  echo "[$SUDOERS_FILE 파일 내용 확인]"
  sudo cat "$SUDOERS_FILE"
  echo "----------------------------------------------------------------------"
else
  sudo rm -f "$SUDOERS_FILE"
  help "생성된 sudoers 파일의 문법 검증에 실패하여 롤백했습니다." "${BASH_LINENO[0]}"
  exit 1
fi

exit 0

