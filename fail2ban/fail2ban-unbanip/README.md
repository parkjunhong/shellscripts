# 🛡️ fail2ban-unbanip

`fail2ban-client`를 래핑하여 현재 활성화된 **Fail2ban 감옥(Jail) 목록과 각 감옥에 차단된 IP 현황을 대화형(Interactive) 테이블로 조회**하고, 번호 선택만으로 **단일 또는 다중 IP 차단을 손쉽게 해제(`unbanip`)**하는 관리 도구입니다.

---

## ✨ 주요 특징

1. **전체 Jail 및 차단 IP 현황 한눈에 조회**
   * 실행 즉시 활성화된 모든 Fail2ban Jail을 순회하며 각 Jail별 **현재 차단 수(`Currently banned`)**와 **차단된 IP 목록(`Banned IP list`)**을 정렬된 표 형태로 출력합니다.
2. **대화형(Interactive) 번호 선택 및 다중 IP 일괄 해제**
   * 복잡한 `fail2ban-client set <jail> unbanip <ip>` 명령어나 긴 IP 주소를 직접 타이핑할 필요 없이, 화면에 표시된 Jail 번호(`#`)와 IP 번호(`[01]`, `[02]` 등)를 입력하여 해제할 수 있습니다.
   * IP 번호 입력 시 콤마(`,`)로 구분(예: `1,3,4`)하여 여러 개의 차단 IP를 한 번에 일괄 해제할 수 있으며, 중복 입력된 번호는 자동으로 제거됩니다.
3. **해제 후 실시간 상태 재조회 및 검증**
   * 차단 해제 명령 수행 후 각 IP별 성공/실패 요약을 출력하고, 해당 Jail의 최신 상태(`fail2ban-client status <jail>`)를 즉시 다시 조회하여 차단이 정상 해제되었는지 검증합니다.
4. **데몬 연결 사전 점검 및 권한 자동 처리**
   * 실행 시 `fail2ban-client ping`을 통해 데몬 구동 상태 및 소켓 응답(`pong`)을 먼저 검증하며, 일반 사용자 실행 시 내부적으로 `sudo` 권한을 확인합니다.

---

## 🔄 동작 흐름

1. **데몬 점검**: `fail2ban-client` 설치 여부 및 데몬 동작 상태(`ping`) 확인
2. **전체 현황 출력 및 Jail 선택**: 활성화된 전체 Jail 목록과 차단 현황 표를 출력하고 대상 Jail 번호(`#`) 입력 대기 (`Enter` 입력 시 즉시 종료)
3. **선택한 Jail 상세 조회 및 IP 선택**: 해당 Jail의 상세 상태와 번호가 부여된 차단 IP 목록을 출력하고 해제할 IP 번호(콤마 구분 다중 선택 가능) 입력 대기
4. **차단 해제 및 결과 확인**: 선택한 IP들에 대해 `unbanip`을 실행하고 최신 Jail 상태를 재출력

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--help` | 선택 | 도움말 및 진행 순서 안내를 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 대화형 모드로 Fail2ban 차단 IP 조회 및 해제 실행
./fail2ban-unbanip

# 도움말 확인
./fail2ban-unbanip --help
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./fail2ban-unbanip --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./fail2ban-unbanip --target global
```

