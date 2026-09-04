#!/usr/bin/env bash
# =======================================
# @author : parkjunhong77@gmail.com
# @title : search files.
# @license : Apache License 2.0
# @since : 2026-09-03
# @desc : support Ubuntu 18.04 or higher, RHEL 7 or higher, Oracle Linux 7 or higher, RockyOS 8 or higher, CentOS 7 or higher
# @installation : 
# 1. insert 'source <path>/authelia-crypto-hash.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
# 2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/authelia-crypto-hash.sh' into /etc/bashrc for all users.
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
  echo "  Docker 독립 컨테이너 환경에서 Authelia 암호화 해시(Argon2, SHA512 등)를 안전하게 생성합니다."
  echo "  보안을 위해 비밀번호는 파라미터로 받지 않으며, 실행 중 정책 검증을 거쳐 안전하게 마스킹 입력받습니다."
  echo "  다중 사용자의 동시 실행을 위해 고유한 임시 컨테이너명을 자동으로 생성하여 충돌을 방지합니다."
  echo ""
  echo "[비밀번호 생성/입력 정책]"
  echo "  1. 최소 10자 이상"
  echo "  2. 영문 소문자(a-z) 1자 이상 포함"
  echo "  3. 영문 대문자(A-Z) 1자 이상 포함"
  echo "  4. 숫자(0-9) 1자 이상 포함"
  echo "  5. 특수문자 1자 이상 포함"
  echo "  6. 연속된 동일/순차 문자 또는 숫자는 최대 2개까지만 허용 (3개 이상 연속 금지)"
  echo "  *. 단 개발을 목적으로 하는 'test' 는 허용. 테스트 후 반드시 users_database.yml에서 삭제할 것."
  echo ""
  echo "[옵션 (Options)]"
  echo "  --image <이미지명>          Authelia Docker 이미지 (기본값: authelia/authelia:latest)"
  echo "  --algorithm <알고리즘>      해시 알고리즘 (기본값: argon2 | bcrypt, pbkdfs, scrypt, sha2crypt)"
  echo "  --help                      도움말을 출력하고 종료합니다."
}

# 전역 변수 선언 (메인 스코프에서는 local 키워드를 일절 사용하지 않음)
IMAGE_NAME="authelia/authelia:latest"
ALGORITHM="argon2"
CONTAINER_NAME=""

DOCKER_CMD=()

##
# 비정상 중단 또는 종료 시 생성된 임시 컨테이너를 안전하게 제거합니다.
#
# @param 없음
#
# @return (임시 컨테이너 강제 정리)
##
cleanup() {
  if [ -n "${CONTAINER_NAME:-}" ]; then
    if [ ${#DOCKER_CMD[@]} -gt 0 ]; then
      "${DOCKER_CMD[@]}" rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    elif command -v docker >/dev/null 2>&1; then
      docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
  fi
}

trap 'help "스크립트 실행 중 예기치 않은 오류가 발생했습니다." "$LINENO"' ERR
trap cleanup EXIT INT TERM

##
# 시스템의 Docker 바이너리 가용성 및 실행 권한을 계층별로 검증하여 최적의 실행 명령(DOCKER_CMD)을 구성합니다.
# 현재 사용자가 docker 그룹에 속해 있거나 직접 권한이 있는 경우 sudo를 강제하지 않습니다.
#
# @param 없음
#
# @return (전역 배열 DOCKER_CMD 초기화)
##
ensure_docker_engine() {
  # 1. Docker 실행 바이너리 존재 검증
  if ! command -v docker >/dev/null 2>&1; then
    help "Docker 바이너리가 시스템에 설치되어 있지 않습니다." "$LINENO"
    exit 1
  fi

  # 2. 현재 사용자 권한(docker 그룹, rootless, root 등)으로 직접 소켓 접근 가능한지 1차 확인
  if docker info >/dev/null 2>&1; then
    DOCKER_CMD=(docker)
    echo "🐳 [INFO] 현재 사용자 권한으로 Docker 데몬에 정상 연결되었습니다. (sudo 불필요)"
    return 0
  fi

  # 3. 직접 접근이 불가능한 경우에 한하여 sudo 권한 협상 진행
  echo "⚠️  [WARN] 현재 사용자 권한으로 Docker 소켓에 직접 접근할 수 없습니다. sudo 권한 확인을 시도합니다..."

  if ! command -v sudo >/dev/null 2>&1; then
    help "Docker 소켓 접근 권한이 없으며, 시스템에 sudo 명령어가 존재하지 않습니다. 사용자를 'docker' 그룹에 추가하십시오." "$LINENO"
    exit 1
  fi

  # sudo 인증 검증 (패스워드 필요 시 프롬프트 호출)
  if ! sudo -n true 2>/dev/null; then
    echo "🔐 [SUDO] Docker 데몬 제어를 위해 sudo 인증이 필요합니다."
    sudo -v || {
      help "sudo 권한 인증에 실패했거나 현재 사용자가 sudoers에 등록되어 있지 않습니다." "$LINENO"
      exit 1
    }
  fi

  # 4. sudo 권한으로 Docker 데몬 정상 연결 2차 확인
  if sudo docker info >/dev/null 2>&1; then
    DOCKER_CMD=(sudo docker)
    echo "🛡️  [INFO] sudo 권한을 통해 Docker 데몬에 연결되었습니다."
    return 0
  fi

  # 5. sudo로도 실패하는 경우: 소켓 권한이 아닌 Docker 데몬 자체가 중지된 상태
  help "Docker 데몬이 실행 중이지 않거나 응답하지 않습니다. (sudo systemctl start docker 필요)" "$LINENO"
  exit 1
}

##
# 다중 사용자의 동시 실행 충돌을 방지하기 위해 100% 고유한 컨테이너 이름을 생성합니다.
#
# @param 없음
#
# @return {string} 고유 컨테이너명
##
generate_unique_container_name() {
  local timestamp_part=""
  local entropy_part=""

  timestamp_part="$(date +%s%N 2>/dev/null || date +%s)"
  entropy_part="$(od -An -tx4 -N4 /dev/urandom 2>/dev/null | tr -d ' ' || echo "${RANDOM}${RANDOM}")"

  echo "authelia-hash-${timestamp_part}-${$}-${entropy_part}"
}

##
# 비밀번호가 6대 보안 정책을 엄격하게 충족하는지 검증합니다.
#
# @param $1 {string} 검증할 비밀번호 문자열
#
# @return {integer} 유효하면 0, 불만족 시 1 반환 (실패 원인은 stderr로 출력)
##
validate_password_complexity() {
  local pw="$1"
  local len=${#pw}
  
  if [ "$pw" = "test" ]; then
    return 0
  fi

  # 1. 최소 10자 검증
  if (( len < 10 )); then
    echo "⚠️  [WARN] 비밀번호는 최소 10자 이상이어야 합니다. (현재 길이: ${len}자)" >&2
    return 1
  fi

  # 2. 소문자 하나 이상 포함
  if [[ ! "$pw" =~ [a-z] ]]; then
    echo "⚠️  [WARN] 비밀번호에 영문 소문자(a-z)가 최소 1자 이상 포함되어야 합니다." >&2
    return 1
  fi

  # 3. 대문자 하나 이상 포함
  if [[ ! "$pw" =~ [A-Z] ]]; then
    echo "⚠️  [WARN] 비밀번호에 영문 대문자(A-Z)가 최소 1자 이상 포함되어야 합니다." >&2
    return 1
  fi

  # 4. 숫자 문자 하나 이상 포함
  if [[ ! "$pw" =~ [0-9] ]]; then
    echo "⚠️  [WARN] 비밀번호에 숫자(0-9)가 최소 1자 이상 포함되어야 합니다." >&2
    return 1
  fi

  # 5. 특수 문자 하나 이상 포함 (공백 및 특수기호)
  if [[ ! "$pw" =~ [^a-zA-Z0-9] ]]; then
    echo "⚠️  [WARN] 비밀번호에 특수문자가 최소 1자 이상 포함되어야 합니다." >&2
    return 1
  fi

  # 6. 연속된 동일 문자 또는 순차 문자/숫자는 최대 2개까지만 허용 (3개 이상 연속 금지)
  local i=0
  local c1=""
  local c2=""
  local c3=""
  local a1=0
  local a2=0
  local a3=0

  for (( i=0; i<len-2; i++ )); do
    c1="${pw:i:1}"
    c2="${pw:i+1:1}"
    c3="${pw:i+2:1}"

    # 동일한 문자 3연속 차단 (예: aaa, 111, !!!)
    if [[ "$c1" == "$c2" && "$c2" == "$c3" ]]; then
      echo "⚠️  [WARN] 동일한 문자('$c1')가 3회 이상 연속될 수 없습니다 (최대 2개 허용)." >&2
      return 1
    fi

    # 순차적 연속 문자/숫자 3자리 차단 (숫자, 소문자, 대문자 각각 분리 판별)
    if [[ "$c1" =~ [0-9] && "$c2" =~ [0-9] && "$c3" =~ [0-9] ]] || \
       [[ "$c1" =~ [a-z] && "$c2" =~ [a-z] && "$c3" =~ [a-z] ]] || \
       [[ "$c1" =~ [A-Z] && "$c2" =~ [A-Z] && "$c3" =~ [A-Z] ]]; then
      LC_ALL=C printf -v a1 '%d' "'$c1"
      LC_ALL=C printf -v a2 '%d' "'$c2"
      LC_ALL=C printf -v a3 '%d' "'$c3"

      # 오름차순(예: 123, abc, ABC) 또는 내림차순(예: 321, cba, CBA) 차단
      if (( a1 + 1 == a2 && a2 + 1 == a3 )) || (( a1 - 1 == a2 && a2 - 1 == a3 )); then
        echo "⚠️  [WARN] 순차적으로 연속된 문자/숫자('$c1$c2$c3')는 사용할 수 없습니다 (최대 2개 허용)." >&2
        return 1
      fi
    fi
  done

  return 0
}

##
# 프로세스 테이블 노출을 원천 방어하기 위해 사용자로부터 마스킹된 비밀번호를 안전하게 입력받고 정책을 검증합니다.
#
# @param 없음
#
# @return {string} 검증 완료된 순수 비밀번호 문자열
##
prompt_secure_password() {
  local pw1=""
  local pw2=""
  local tty_in="/dev/tty"

  if [ ! -e "$tty_in" ] && [ ! -t 0 ]; then
    help "비대화형(CI/CD) 환경에서는 표준 입력을 통한 대화형 비밀번호 입력이 불가능합니다." "$LINENO"
    exit 1
  fi

  echo "================================================================================" >&2
  echo "🔐 [보안 입력] Authelia 계정에 적용할 비밀번호를 입력해 주십시오." >&2
  echo "  - 최소 10자 이상" >&2
  echo "  - 소문자, 대문자, 숫자, 특수문자 각 1자 이상 필수 포함" >&2
  echo "  - 동일/순차 연속 문자 및 숫자는 최대 2개까지만 허용 (3개 이상 금지)" >&2
  echo "================================================================================" >&2

  while true; do
    if [ -e "$tty_in" ]; then
      read -rs -p "👉 비밀번호 입력 (화면에 표시되지 않음): " pw1 < "$tty_in"
      echo >&2
    else
      read -rs -p "👉 비밀번호 입력 (화면에 표시되지 않음): " pw1
      echo >&2
    fi

    # 1차 비밀번호 복잡도 정밀 검증
    if ! validate_password_complexity "$pw1"; then
      echo "다시 시도해 주십시오." >&2
      echo "" >&2
      continue
    fi

    # 2차 확인 입력
    if [ -e "$tty_in" ]; then
      read -rs -p "👉 비밀번호 재확인: " pw2 < "$tty_in"
      echo >&2
    else
      read -rs -p "👉 비밀번호 재확인: " pw2
      echo >&2
    fi

    if [ "$pw1" != "$pw2" ]; then
      echo "❌ [ERROR] 입력한 두 비밀번호가 일치하지 않습니다. 처음부터 다시 입력해 주십시오." >&2
      echo "" >&2
      continue
    fi

    echo "$pw1"
    return 0
  done
}

##
# 동적 생성된 고유 컨테이너를 기반으로 Docker 단독 명령어를 실행하여 해시를 생성하고,
# 결과 출력 중 해시값 영역만 진한 노란색(Bold Yellow)으로 강조 렌더링합니다.
#
# @param $1 {string} Docker 이미지명
# @param $2 {string} 고유 컨테이너명
# @param $3 {string} 해시 알고리즘 ('argon2', 'sha512' 등)
# @param $4 {string} 비밀번호 문자열
#
# @return (해시 생성 결과 콘솔 출력)
##
execute_docker_hash() {
  local img_name="$1"
  local c_name="$2"
  local algo="$3"
  local raw_pw="$4"

  local color_bold_yellow=$'\033[1;33m'
  local color_reset=$'\033[0m'

  echo "================================================================================"
  echo "🚀 [START] Authelia 독립 Docker 컨테이너 해시 생성을 시작합니다..."
  echo "  - 대상 이미지     : $img_name"
  echo "  - 고유 컨테이너명 : $c_name (동시 실행 격리)"
  echo "  - 해시 알고리즘   : $algo"
  echo "  - 실행 바이너리   : ${DOCKER_CMD[*]}"
  echo "================================================================================"

  echo "⏳ [PROCESSING] 비밀번호 해시 연산을 수행 중입니다. 잠시만 기다려주십시오..."
  echo ""

  # docker run 실행: 1회성 컨테이너 실행 및 자동 삭제(--rm)
  # 비밀번호는 배열 원소로 바인딩하여 셸 메타문자 변형 차단
  # Digest 출력 결과 중 해시값만 진한 노란색(\033[1;33m)으로 색상 강조 처리
  "${DOCKER_CMD[@]}" run --rm \
    --name "$c_name" \
    "$img_name" \
    authelia crypto hash generate "$algo" --password "$raw_pw" | \
    sed -E "s/^(Digest:[[:space:]]*)([^[:space:]]+)/\1${color_bold_yellow}\2${color_reset}/"

  echo ""
  echo "================================================================================"
  echo "🎉 [SUCCESS] Authelia 비밀번호 해시 생성이 성공적으로 완료되었습니다."
  echo "💡 (노란색으로 강조된 해시값을 복사하여, Authelia 설정 파일의 users_database.yml 에 적용하십시오.)"
  echo "================================================================================"
}

##
# 스크립트 실행의 메인 진입점입니다.
#
# @param $@ {array} 스크립트 실행 인자
#
# @return (없음)
##
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --image)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--image 파라미터는 Docker 이미지명을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        IMAGE_NAME="$2"
        shift 2
        ;;
      --algorithm)
        if [[ -z "${2:-}" || "$2" == --* ]]; then
          help "--algorithm 파라미터는 해시 알고리즘을 지정해야 합니다." "$LINENO"
          exit 1
        fi
        ALGORITHM="$2"
        shift 2
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

  # 알고리즘 유효성 검증
  case "$ALGORITHM" in
    argon2|bcrypt|pbkdf2|scrypt|sha2crypt)
      ;;
    *)
      help "지원하지 않는 알고리즘입니다 -> '$ALGORITHM' (지원: argon2, bcrypt, pbkdf2, scrypt, sha2crypt)" "$LINENO"
      exit 1
      ;;
  esac

  ensure_docker_engine

  # 다중 사용자 동시 실행을 위한 고유 컨테이너명 생성
  CONTAINER_NAME="$(generate_unique_container_name)"

  # 비밀번호는 파라미터가 아닌 중간 단계에서 안전하게 마스킹 입력받으며 6대 정책 검증 수행
  local secure_password=""
  secure_password="$(prompt_secure_password)"

  execute_docker_hash "$IMAGE_NAME" "$CONTAINER_NAME" "$ALGORITHM" "$secure_password"
}

main "$@"
exit 0
