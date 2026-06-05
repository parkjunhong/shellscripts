#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : search files.
# @license  : Apache License 2.0
# @since    : 2026-06-05
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
  echo "지정된 대상(계정/그룹)에 대해 상세 Sudoers 정책(호스트, 권한, 옵션)을 부여하고 병합합니다."
  echo ""
  echo "대상 옵션 (택 1 필수):"
  echo "  -u, --user <계정명>    권한을 부여할 대상 시스템 계정"
  echo "  -g, --group <그룹명>   권한을 부여할 대상 시스템 그룹"
  echo ""
  echo "정책 옵션 (선택):"
  echo "  -H, --host <호스트>    명령어 실행을 허용할 호스트 (기본값: ALL)"
  echo "  -r, --runas <사용자>   명령어 실행 시 빌려올 권한 (기본값: ALL)"
  echo "                         예: oracle, :dba, tomcat:was 등 (자동 포맷팅 지원)"
  echo "  -o, --option <옵션>    Sudoers 태그 옵션 (기본값: NONE)"
  echo "                         비밀번호 면제 규칙을 생성하려면 명시적으로 'NOPASSWD'를 입력해야 합니다."
  echo "                         복수 옵션이 필요한 경우 콤마(,)로 연결하여 입력합니다."
  echo "                         [지원 옵션 상세]"
  echo "                         - NONE       : 별도의 태그 옵션이 없는 표준 권한 설정을 적용합니다. (비밀번호 필수)"
  echo "                         - NOPASSWD   : 비밀번호 입력 없이 명령어 실행을 허용합니다."
  echo "                         - PASSWD     : 비밀번호 입력을 강제로 요구합니다."
  echo "                         - NOEXEC     : 명령어 내부에서 하위 쉘 및 외부 명령 실행을 차단합니다."
  echo "                         - EXEC       : 하위 쉘 실행 차단을 해제하고 허용합니다."
  echo "                         - SETENV     : 사용자의 기존 환경변수를 sudo 실행 시에도 유지합니다."
  echo "                         - NOSETENV   : 환경변수 유지를 차단하고 안전하게 초기화합니다."
  echo "                         - LOG_INPUT  : 명령어 실행 시 사용자의 표준 입력을 로그에 기록합니다."
  echo "                         - NOLOG_INPUT: 표준 입력 로그 기록을 중지합니다."
  echo "  -h, --help             도움말 출력"
  echo ""
  echo "예시:"
  echo "  $FILENAME -u ymtech ALL"
  echo "  $FILENAME -u ymtech -o NOPASSWD /usr/bin/cat /usr/bin/systemctl"
  echo "  $FILENAME -g devops -H web-server-01 -o NOPASSWD,NOEXEC /usr/bin/systemctl"
}

##
# 대상 계정이 시스템에 존재하는지 검증합니다.
#
# @param $1 {string} 계정명
#
# @return 계정이 존재하면 0, 존재하지 않으면 1 반환
##
check_user_exists() {
  if id "$1" &>/dev/null; then return 0; else return 1; fi
}

##
# 대상 그룹이 시스템에 존재하는지 검증합니다.
#
# @param $1 {string} 그룹명
#
# @return 그룹이 존재하면 0, 존재하지 않으면 1 반환
##
check_group_exists() {
  if getent group "$1" &>/dev/null; then return 0; else return 1; fi
}

##
# 기존 Sudoers 설정 파일에서 완벽하게 일치하는 정책 라인을 찾아 명령어를 추출하고 나머지를 보존합니다.
#
# @return 파싱 작업이 정상 완료되면 0 반환
##
parse_existing_sudoers() {
  if sudo test -f "$SUDOERS_FILE"; then
    while IFS= read -r line || [ -n "$line" ]; do
      local is_match=0
      local cmds_str=""
      
      if [ "$PARAM_OPTION" != "NONE" ] && [ -n "$PARAM_OPTION" ]; then
        if [[ "$line" == "${MATCH_PREFIX}"* ]]; then
          is_match=1
          cmds_str=$(echo "$line" | sed "s/^${MATCH_PREFIX} *//")
        fi
      else
        if [[ "$line" == "${MATCH_PREFIX}"* ]]; then
          local remaining=$(echo "$line" | sed "s/^${MATCH_PREFIX} *//")
          if [[ "$remaining" != *"NOPASSWD:"* && "$remaining" != *"PASSWD:"* && "$remaining" != *"NOEXEC:"* && "$remaining" != *"EXEC:"* && "$remaining" != *"SETENV:"* && "$remaining" != *"NOSETENV:"* && "$remaining" != *"LOG_INPUT:"* && "$remaining" != *"NOLOG_INPUT:"* ]]; then
            is_match=1
            cmds_str="$remaining"
          fi
        fi
      fi

      if [ "$is_match" -eq 1 ]; then
        local cmds_arr=()
        IFS=',' read -ra cmds_arr <<< "$cmds_str"
        for cmd in "${cmds_arr[@]}"; do
          cmd=$(echo "$cmd" | xargs)
          if [ -n "$cmd" ]; then FINAL_CMDS+=("$cmd"); fi
        done
      else
        if [ -n "$line" ]; then PRESERVED_LINES+=("$line"); fi
      fi
    done < <(sudo cat "$SUDOERS_FILE")
  fi
  return 0
}

##
# 입력받은 명령어 목록의 실재 여부를 검증하고 시스템에 존재하지 않는 경우 설치를 제안합니다.
#
# @return 검증 및 설치 프로세스가 종료되면 0 반환
##
validate_and_install_commands() {
  echo ""
  echo "[✨] 명령어 존재 여부 검증 및 설치"
  echo "----------------------------------------------------------------------"
  
  for i in "${!COMMANDS[@]}"; do
    local cmd="${COMMANDS[$i]}"
    local resolved=""
    local is_path=0
    
    if [ "$cmd" = "ALL" ]; then
      resolved="ALL"
    elif [[ "$cmd" == */* ]]; then
      is_path=1
      if [ -e "$cmd" ]; then resolved=$(realpath "$cmd" 2>/dev/null || readlink -f "$cmd" 2>/dev/null); fi
    else
      resolved=$(command -v "$cmd" 2>/dev/null)
    fi

    if [ -z "$resolved" ] || [ ! -e "$resolved" ]; then
      if [ "$cmd" != "ALL" ] && [ "$is_path" -eq 0 ] && [ "$PKG_MGR" != "unknown" ]; then
        local is_installable=0
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
              resolved=$(command -v "$cmd" 2>/dev/null)
              if [ -n "$resolved" ] && [ -e "$resolved" ]; then echo "  >>> [성공] 설치 완료 ($resolved)"; else echo "  >>> [실패] 설치 실패."; fi
              ;;
            * ) echo "  >>> 설치를 건너뜁니다." ;;
          esac
        fi
      fi
    fi
    RESOLVED_COMMANDS[$i]="$resolved"
  done
  echo ""
  return 0
}

##
# 최종 권한 규칙 구조를 파일에 기입하고 visudo 엔진으로 문법 정합성을 검증합니다.
#
# @return 문법 통과 시 파일 가독을 위한 cat 출력 후 0 반환
##
write_and_verify_sudoers() {
  if ! sudo test -d "$SUDOERS_DIR"; then sudo mkdir -p "$SUDOERS_DIR"; fi

  local joined_cmds=$(printf ", %s" "${FINAL_CMDS[@]}")
  joined_cmds=${joined_cmds:2}

  {
    for line in "${PRESERVED_LINES[@]}"; do echo "$line"; done
    echo "${MATCH_PREFIX} ${joined_cmds}"
  } | sudo tee "$SUDOERS_FILE" > /dev/null

  sudo chmod 0440 "$SUDOERS_FILE"

  sudo visudo -c -f "$SUDOERS_FILE" &>/dev/null
  if [ $? -ne 0 ]; then
    sudo rm -f "$SUDOERS_FILE"
    help "생성된 sudoers 파일의 문법 검증에 실패하여 롤백했습니다." "${BASH_LINENO[0]}"
    exit 1
  fi
  return 0
}

# 변수 초기화 및 파라미터 제어 변수 선언
TARGET_TYPE=""
TARGET_NAME=""
TARGET_PREFIX=""
PARAM_HOST="ALL"
PARAM_RUNAS="(ALL)"
PARAM_OPTION="NONE"
COMMANDS=()

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--user)
      if [ -n "$TARGET_TYPE" ]; then help "대상은 계정(-u) 또는 그룹(-g) 중 하나만 지정해야 합니다." "${BASH_LINENO[0]}"; exit 1; fi
      TARGET_TYPE="user"
      TARGET_NAME="$2"
      TARGET_PREFIX="$2"
      shift 2
      ;;
    -g|--group)
      if [ -n "$TARGET_TYPE" ]; then help "대상은 계정(-u) 또는 그룹(-g) 중 하나만 지정해야 합니다." "${BASH_LINENO[0]}"; exit 1; fi
      TARGET_TYPE="group"
      TARGET_NAME="$2"
      TARGET_PREFIX="%${2}"
      shift 2
      ;;
    -H|--host)
      PARAM_HOST="$2"
      shift 2
      ;;
    -r|--runas)
      raw_runas="$2"
      if [[ "$raw_runas" != \(* ]]; then
        if [[ "$raw_runas" == *:* ]]; then
          u=$(echo "$raw_runas" | cut -d: -f1)
          g=$(echo "$raw_runas" | cut -d: -f2)
          if [ -n "$g" ] && [[ "$g" != %* ]]; then g="%${g}"; fi
          PARAM_RUNAS="(${u}:${g})"
        else
          PARAM_RUNAS="(${raw_runas})"
        fi
      else
        PARAM_RUNAS="$raw_runas"
      fi
      shift 2
      ;;
    -o|--option)
      PARAM_OPTION="$2"
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

if [ -z "$TARGET_TYPE" ]; then
  help "필수 파라미터인 대상 계정(-u) 또는 그룹(-g)이 입력되지 않았습니다." "${BASH_LINENO[0]}"
  exit 1
fi

if [ "$TARGET_TYPE" == "user" ] && ! check_user_exists "$TARGET_NAME"; then
  help "입력된 계정($TARGET_NAME)이 시스템에 존재하지 않습니다." "${BASH_LINENO[0]}"
  exit 1
elif [ "$TARGET_TYPE" == "group" ] && ! check_group_exists "$TARGET_NAME"; then
  help "입력된 그룹($TARGET_NAME)이 시스템에 존재하지 않습니다." "${BASH_LINENO[0]}"
  exit 1
fi

if [ ${#COMMANDS[@]} -eq 0 ]; then
  help "적용할 명령어가 하나 이상 입력되어야 합니다." "${BASH_LINENO[0]}"
  exit 1
fi

SUDOERS_DIR="/etc/sudoers.d"
if [ "$TARGET_TYPE" == "user" ]; then
  SUDOERS_FILE="${SUDOERS_DIR}/user-${TARGET_NAME}"
else
  SUDOERS_FILE="${SUDOERS_DIR}/group-${TARGET_NAME}"
fi

if [ "$PARAM_OPTION" != "NONE" ] && [ -n "$PARAM_OPTION" ]; then
  MATCH_PREFIX="${TARGET_PREFIX} ${PARAM_HOST}=${PARAM_RUNAS} ${PARAM_OPTION}:"
else
  MATCH_PREFIX="${TARGET_PREFIX} ${PARAM_HOST}=${PARAM_RUNAS}"
fi

PKG_MGR="unknown"
if command -v dnf &>/dev/null; then PKG_MGR="dnf"
elif command -v yum &>/dev/null; then PKG_MGR="yum"
elif command -v apt-get &>/dev/null; then PKG_MGR="apt-get"
fi

FINAL_CMDS=()
PRESERVED_LINES=()
RESOLVED_COMMANDS=()

parse_existing_sudoers
validate_and_install_commands

echo ""
echo "[✨] 명령어 병합 및 최종 결과"
echo "----------------------------------------------------------------------"
NEW_ADDED=0

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  resolved="${RESOLVED_COMMANDS[$i]}"
  
  if [ -n "$resolved" ]; then
    is_duplicate=0
    
    # [교정 요점 1] 기존 목록에 이미 'ALL' 권한이 등록되어 있는 경우
    # 신규로 어떤 명령어가 들어오든 무의미하므로 즉시 중복(제외) 처리합니다.
    for ext_cmd in "${FINAL_CMDS[@]}"; do
      if [ "$ext_cmd" == "ALL" ]; then
        is_duplicate=1
        break
      fi
    done
    
    if [ "$is_duplicate" -eq 1 ]; then
      printf "%-19s -> %-26s [%s]\n" "$cmd" "$resolved" "중복 (제외)"
      continue
    fi
    
    # [교정 요점 2] 새로 추가하려는 명령어 자체가 전역 권한 'ALL'인 경우
    # 기존에 누적되어 있던 하위 개별 명령어들을 모두 흡수하므로 배열을 비우고 ALL만 삽입합니다.
    if [ "$resolved" == "ALL" ]; then
      FINAL_CMDS=("ALL")
      NEW_ADDED=1
      printf "%-19s -> %-26s [%s]\n" "$cmd" "$resolved" "신규 (기존 명령어 대체 허용)"
      continue
    fi

    # 3. 일반적인 동일 명령어 중복 체크
    for ext_cmd in "${FINAL_CMDS[@]}"; do
      if [ "$ext_cmd" == "$resolved" ]; then
        is_duplicate=1; break
      fi
    done

    if [ "$is_duplicate" -eq 1 ]; then
      printf "%-19s -> %-26s [%s]\n" "$cmd" "$resolved" "중복 (제외)"
    else
      printf "%-19s -> %-26s [%s]\n" "$cmd" "$resolved" "신규 (허용)"
      FINAL_CMDS+=("$resolved")
      NEW_ADDED=1
    fi
  else
    printf "%-19s -> %-26s [%s]\n" "$cmd" "NOT_EXIST" "거부"
  fi
done

echo ""

if [ "$NEW_ADDED" -eq 0 ]; then
  echo
  echo "[안내] 새로 추가할 유효한 명령어가 없거나 모두 중복되어 작업을 종료합니다."
else
  write_and_verify_sudoers
fi

echo
echo "======================================================================"
echo "[🎯] '${TARGET_NAME}'(${TARGET_TYPE}) 대상에 대한 Sudoers 적용이 완료되었습니다."
echo "----------------------------------------------------------------------"
echo "[$SUDOERS_FILE 파일 내용 확인]"
echo ""
sudo cat "$SUDOERS_FILE"
echo ""
echo "======================================================================"

exit 0
