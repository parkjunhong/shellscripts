#!/usr/bin/env bash

# 부모 스크립트에서 넘겨준 $func_name (또는 파일명) 활용을 위해 변수 지정
SCRIPT_NAME=$(basename "$0")

run_cmd() {
    local -a cmd=("$@")

    echo
    echo "${cmd[*]}"
    
    # [수정] 명령어 실행 결과를 if ! 로 검사하여 실패 시 분기 처리
    if ! "${cmd[@]}"; then
        # 1. 터미널 화면에 부모의 색상 함수(echo_e)로 즉시 에러 출력
        echo_e " - [ERROR] 명령어 실행 실패: ${cmd[*]}"
        
        # 2. 부모의 공지사항 기록 함수(_add_notice)를 호출하여 최종 결과창에 남김
        _add_notice " - [$SCRIPT_NAME] [ERROR] 방화벽 설정 실패: ${cmd[*]}"
        
        # 3. 에러 발생 시 자식 스크립트 즉시 중단 (부모에게 실패 상태 코드 1 반환)
        # 만약 여기서 부모 스크립트 전체를 완전히 강제 종료시키고 싶다면 
        # exit 1 대신 부모의 error_exit "메시지" "$LINENO" 를 호출하셔도 됩니다.
        exit 1
    fi
}

# (이하 명령어 동일)
run_cmd sudo firewall-cmd --permanent --zone=trusted  --set-priority=-10
run_cmd sudo firewall-cmd --permanent --zone=work     --set-priority=-7
run_cmd sudo firewall-cmd --permanent --zone=internal --set-priority=-4
run_cmd sudo firewall-cmd --permanent --zone=external --set-priority=-1
run_cmd sudo firewall-cmd --permanent --zone=external --set-priority=-1

run_cmd sudo firewall-cmd --reload

exit 0
