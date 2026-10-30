#!/usr/bin/env bash
# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : firewall-cmd-set-priority.sh: Firewalld Zone Priority Initializer
# @license  : Apache License 2.0
# @since    : 2026-06-23
# @desc     : support Ubuntu 24.04+, RockyOS 9+, RHEL 9+, CentOS Stream 9+
# =======================================

SCRIPT_NAME="$(basename "$0")"

##
# 명령어를 실행하고 실패 시 부모 스크립트와 화면에 에러를 로깅한 뒤 즉시 종료합니다.
#
# @param $@ {array} 실행할 명령어 및 인자
#
# @return 성공 시 0, 실패 시 exit 1
##
run_cmd() {
  local -a cmd=("$@")

  echo
  echo "${cmd[*]}"

  if ! "${cmd[@]}"; then
    echo_e " - [ERROR] 명령어 실행 실패: ${cmd[*]}"
    _add_notice " - [$SCRIPT_NAME] [ERROR] 방화벽 설정 실패: ${cmd[*]}"
    exit 1
  fi
}

# ==============================================================================
# 1. Firewalld 서비스 구동 및 상태 검증
# ==============================================================================
echo_i " - [시스템] firewalld 서비스 상태를 확인합니다..."

if ! systemctl is-active --quiet firewalld; then
  echo_w " - [경고] firewalld가 실행 중이 아닙니다. 서비스를 강제로 시작합니다."
  if ! sudo systemctl enable --now firewalld; then
    echo_e " - [ERROR] firewalld 서비스를 시작할 수 없습니다."
    _add_notice " - [$SCRIPT_NAME] [ERROR] firewalld 서비스 구동 실패로 설정을 중단합니다."
    exit 1
  fi
  echo_i " - [성공] firewalld 서비스를 실행했습니다."
fi

# ==============================================================================
# 2. Firewalld 데몬 응답 대기 (초기화 지연 방어)
# ==============================================================================
MAX_WAIT=5
count=0
while ! sudo firewall-cmd --state &>/dev/null; do
  if (( count >= MAX_WAIT )); then
    echo_e " - [ERROR] firewalld 데몬 응답 대기 시간 초과 (${MAX_WAIT}초)"
    _add_notice " - [$SCRIPT_NAME] [ERROR] firewalld 데몬 초기화 실패로 설정을 중단합니다."
    exit 1
  fi
  echo " - [대기] firewalld 초기화 대기 중... ($((count+1))/$MAX_WAIT)"
  sleep 1
  ((count++))
done

# ==============================================================================
# 3. 방화벽 룰 적용 (Zone Priority 설정)
# ==============================================================================
run_cmd sudo firewall-cmd --permanent --zone=trusted  --set-priority=-10
run_cmd sudo firewall-cmd --permanent --zone=work     --set-priority=-7
run_cmd sudo firewall-cmd --permanent --zone=internal --set-priority=-4
run_cmd sudo firewall-cmd --permanent --zone=external --set-priority=-1

run_cmd sudo firewall-cmd --reload

echo_i " - [성공] 방화벽 설정이 완벽하게 적용 및 저장되었습니다."
exit 0
