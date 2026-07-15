#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : download deploy resources.
# @license  : Apache License 2.0
# @since    : 2026-07-15
# @desc     : support RHEL, Oracle Linux, Ubuntu, RockyOS
# @installation : 
#   1. insert 'source <path>/download-deploy-resources.sh" into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/download-deploy-resources.sh' into 
#      etc/bashrc for all users.
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
# 특정 자원을 다운로드하는 git-getpr.sh 명령을 실행합니다.
# 중간 경로가 없는 경우 디렉토리를 자동 생성하여 안정성을 확보합니다.
#
# @param $1 {string} 다운로드할 자원 식별 키 (docker, docker-compose, install, deploy.sh)
#
# @return (실행 결과 및 로그 출력)
##
execute_download() {
  local res_key="$1"
  
  case "$res_key" in
    docker)
      echo "📥 'docker' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker
      echo ""
      ;;
    docker-compose)
      echo "📥 'docker-compose' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource docker-compose
      echo ""
      ;;
    os_version)
      echo "📥 'workdir/install' 디렉토리 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type directory --resource workdir/install --output-path workdir/install
      echo ""
      ;;
    deploy.sh)
      echo "📥 'workdir/deploy.sh' 파일 자원을 가져오는 중입니다..."
      git-getpr.sh --git-url https://github.com/parkjunhong --project maven-deploy-config --branch main --resource-type file --resource workdir/deploy.sh --output-path workdir/deploy.sh
      echo ""
      ;;
    *)
      echo "⚠️ 알 수 없는 자원 식별자입니다: $res_key (무시됨)"
      ;;
  esac
}

TARGET_RESOURCES=""

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
  echo "다운로드할 자원을 선택해 주세요 (콤마(,)로 구분하여 여러 개 입력 가능, 전체는 'all' 입력)."
  echo "  - [1] Dockerfile 및 실행 스크립트 (docker 디렉토리)"
  echo "  - [2] docker-compose 및 제어 스크립트 (docker-compose 디렉토리)"
  echo "  - [3] 지원가능한 운영체제 및 버전 정보 (workdir/install 디렉토리)"
  echo "  - [4] 배포 스크립트 (workdir/deploy.sh 파일)"
  echo "  - [*] 전체"
  echo "================================================================================"
  read -r -p "입력 (예: 1, 2, 또는 *) : " TARGET_RESOURCES
fi

if [[ -z "${TARGET_RESOURCES}" ]]; then
  die "다운로드할 자원이 입력되지 않았습니다."
fi

# 글로빙(Globbing) 문자 확장을 방어하기 위해 특수문자 처리 임시 비활성화
set -f

echo "================================================================================"
if [[ "${TARGET_RESOURCES}" == "*" ]]; then
  execute_download "docker"
  execute_download "docker-compose"
  execute_download "os_version"
  execute_download "deploy.sh"
else
  IFS=',' read -ra ADDR <<< "${TARGET_RESOURCES}"
  
  for item in "${ADDR[@]}"; do
    # 2) 사용자가 선택한 번호(1,2,3,4)에 매핑된 키워드를 사용
    cleaned_item=$(echo "$item" | xargs)
    
    mapped_item=""
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

exit 0
