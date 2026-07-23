#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : download deploy resources.
# @license  : Apache License 2.0
# @since    : 2026-07-23
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS, CentOS
# @installation : 
#   1. insert 'source <path>/install-docker-dev-config.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/install-docker-dev-config.sh' into /etc/bashrc for all users.
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
    for func in ${FUNCNAME[@]:1}
    do  
      printf "$formatr" "["$idx"]" $func
      idx=$((idx + 1))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: ./$FILENAME"
  echo ""
  echo "[옵션 (Options)]"
  echo "  -h, --help    이 도움말을 표시하고 종료합니다."
}

##
# 에러 메시지를 출력하고 스크립트를 종료합니다.
#
# @param $1 {string} (출력할 메시지)
#
# @return (표준 에러로 출력 후 exit 1)
##
die() {
  help "[ERROR] $*" "$LINENO"
  exit 1
}

trap 'help "스크립트 실행 중 오류가 발생했습니다." "$LINENO"' ERR

##
# 원격 URL에서 파일을 다운로드합니다. (curl 또는 wget 하이브리드 사용)
#
# @param $1 {string} 다운로드할 파일의 원격 URL
# @param $2 {string} 저장할 로컬 파일 경로
#
# @return (다운로드 성공 시 0, 실패 시 1 반환)
##
download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -sSLf -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    return 1
  fi
}

##
# git-getpr.sh 스크립트의 존재 여부 및 무결성을 검증하고 처리합니다.
#
# @param 없음
#
# @return (무결성 검증 및 설치 결과 출력, PATH 안내 필요 시 전역 변수 설정)
##
ensure_git_getpr() {
  local remote_url="https://raw.githubusercontent.com/parkjunhong/shellscripts/refs/heads/main/git/git-getpr.sh"
  local tmp_file
  tmp_file=$(mktemp)
  local download_success=0

  if download_file "$remote_url" "$tmp_file"; then
    download_success=1
  else
    echo "⚠️  네트워크 연결이 불안정하여 'git-getpr.sh' 최신 버전을 확인할 수 없습니다."
  fi

  local local_path
  # 로컬에 존재하는지 확인 (없으면 빈 문자열)
  local_path=$(command -v git-getpr.sh || true)

  if [[ -z "$local_path" ]]; then
    # 2. 존재하지 않는 경우
    if [[ $download_success -eq 0 ]]; then
       die "'git-getpr.sh'가 설치되어 있지 않으며, 네트워크 문제로 다운로드할 수 없습니다."
    fi
    echo "ℹ️  'git-getpr.sh'가 시스템에 존재하지 않습니다. 자동 다운로드를 진행합니다..."
    
    local target_dir="$HOME/bin"
    # 중간 경로 자동 생성 방어 로직 적용
    mkdir -p "$target_dir"
    local_path="$target_dir/git-getpr.sh"
    
    cp "$tmp_file" "$local_path"
    chmod +x "$local_path"
    
    # 2-2. 동적 PATH 설정으로 멈춤 없는 실행 연속성 보장
    export PATH="$target_dir:$PATH"
    NEED_PATH_GUIDE=1
    echo "✅ '$local_path'에 설치를 완료했습니다."
  else
    # 3. 존재하는 경우
    if [[ $download_success -eq 1 ]]; then
      # cmp 명령어로 바이트 단위 무결성 일치 확인
      if ! cmp -s "$local_path" "$tmp_file"; then
        # 3-2. 일치하지 않는 경우
        echo "ℹ️  'git-getpr.sh'의 내용이 원격 저장소와 다릅니다. 업데이트를 진행합니다..."
        local backup_path="${local_path}.$(date +%Y%m%d%H%M%S).bak"
        cp "$local_path" "$backup_path"
        echo "💾 기존 파일 백업 완료: $backup_path"
        
        # 파일 덮어쓰기 전 쓰기 권한 확인 (시스템 경로에 있을 경우 대비)
        if [ -w "$local_path" ]; then
          cp "$tmp_file" "$local_path"
          chmod +x "$local_path"
          echo "✅ 최신 버전으로 업데이트를 완료했습니다."
        else
          echo "⚠️  '$local_path'에 대한 쓰기 권한이 없어 업데이트를 건너뜁니다."
        fi
      fi
      # 3-1. 일치하는 경우 별도 액션 없이 바로 기능 실행
    fi
  fi
  rm -f "$tmp_file"
  echo "================================================================================"
}

##
# 특정 자원을 다운로드하는 git-getpr.sh 명령을 실행합니다.
#
# @param $1 {string} 다운로드할 자원 식별 키 (docker, docker-compose, os_version, deploy.sh)
#
# @return (실행 결과 및 로그 출력)
##
execute_download() {
  local res_key="$1"
  
  case "$res_key" in
    docker)
      echo "📥 [1/4] 'docker' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker
      echo ""
      ;;
    docker-compose)
      echo "📥 [2/4] 'docker-compose' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker-compose
      echo ""
      ;;
    os_version)
      echo "📥 [3/4] 'workdir/install' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource workdir/install --output-path workdir/install
      echo ""
      ;;
    deploy.sh)
      echo "📥 [4/4] 'workdir/deploy.sh' 파일 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type file --resource workdir/deploy.sh --output-path workdir/deploy.sh
      echo ""
      ;;
    *)
      echo "⚠️ 매핑되지 않은 식별자입니다: $res_key (무시됨)"
      ;;
  esac
}

# 1~3단계: 스크립트 필수 의존성 파일(git-getpr.sh) 검증 및 자동 설치
NEED_PATH_GUIDE=0
ensure_git_getpr

TARGET_RESOURCES=""

# 옵션 파싱
if [[ "$#" -gt 0 ]]; then
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help "" ""
    exit 0
  elif [[ "$1" == -* ]]; then
    die "알 수 없는 옵션입니다: $1"
  else
    TARGET_RESOURCES="$1"
  fi
fi

if [[ -z "${TARGET_RESOURCES}" ]]; then
  echo "🚀 [배포 환경 구성] 관련 자원 다운로드를 시작합니다..."
  echo "================================================================================"
  echo "다운로드할 자원을 선택해 주세요 (콤마(,)로 구분하여 여러 개 입력 가능, 전체는 '*' 입력)."
  echo "  - [1] Dockerfile 및 실행 스크립트 (docker 디렉토리)"
  echo "  - [2] docker-compose 및 제어 스크립트 (docker-compose 디렉토리)"
  echo "  - [3] 지원가능한 운영체제 및 버전 정보 (workdir/install 디렉토리)"
  echo "  - [4] 배포 스크립트 (workdir/deploy.sh 파일)"
  echo "================================================================================"
  read -r -p "입력 (예: 1, 2, 또는 *) : " TARGET_RESOURCES
fi

if [[ -z "${TARGET_RESOURCES}" ]]; then
  die "다운로드할 자원이 입력되지 않았습니다."
fi

# 글로빙(Globbing) 문자 확장을 방어하기 위해 특수문자 처리 임시 비활성화
set -f

echo "================================================================================"
if [[ "${TARGET_RESOURCES}" == "*" || "${TARGET_RESOURCES}" == "all" ]]; then
  execute_download "docker"
  execute_download "docker-compose"
  execute_download "os_version"
  execute_download "deploy.sh"
else
  IFS=',' read -ra ADDR <<< "${TARGET_RESOURCES}"
  
  for item in "${ADDR[@]}"; do
    cleaned_item=$(echo "$item" | xargs)
    
    local mapped_item=""
    case "$cleaned_item" in
      1) mapped_item="docker" ;;
      2) mapped_item="docker-compose" ;;
      3) mapped_item="os_version" ;;
      4) mapped_item="deploy.sh" ;;
      *) 
        echo "⚠️ 지원하지 않는 번호입니다: $cleaned_item (무시됨)"
        continue
        ;;
    esac
    
    execute_download "$mapped_item"
  done
fi

# 글로빙 기능 원상 복구
set +f

echo "✅ 모든 자원 다운로드가 완료되었습니다!"
echo "================================================================================"
echo "📖 설명에 관한 자세한 사항은 아래 가이드 링크를 확인해 주시기 바랍니다."
echo "🔗 https://gitlab.ymtech.co.kr/parkjunhong-workspaces/thisnthat/blob/main/springproject/guide/deploy/docker-%EB%B0%B0%ED%8F%AC/docker-%EB%B0%B0%ED%8F%AC%EB%B0%A9%EC%8B%9D-%EC%A0%81%EC%9A%A9%EA%B0%80%EC%9D%B4%EB%93%9C.md"
echo "================================================================================"

# 신규 설치 시 $PATH 적용 가이드 안내 (2-2 요청사항)
if [[ "${NEED_PATH_GUIDE}" -eq 1 ]]; then
  echo ""
  echo "🔔 [시스템 PATH 반영 안내] 'git-getpr.sh'가 $HOME/bin 경로에 새로 설치되었습니다."
  echo "다음 로그인 시부터 전역에서 명령어를 인식하도록 하려면 환경변수(\$PATH)에 추가가 필요합니다."
  echo "예시) echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc"
  echo "================================================================================"
fi

exit 0
