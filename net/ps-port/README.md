# 🔌 ps-port

실행 중인 프로세스의 커맨드라인 패턴(이름 또는 인자)을 기반으로 대상 프로세스의 PID를 찾고, 해당 프로세스가 점유 중인 **네트워크 리슨(Listen) 및 연결(Established 등) 포트**를 추적하여 직관적인 테이블 또는 JSON 형식으로 출력하는 프로세스 네트워크 포트 추적 CLI 도구입니다.

---

## ✨ 주요 특징

1. **프로세스 커맨드라인 패턴 기반 포트 탐색**
   * 단순 실행 파일명뿐만 아니라 Java 클래스명, 파이썬 스크립트 경로 등 커맨드라인 인자 패턴 매칭을 통해 프로세스를 정확하게 식별합니다.
2. **다양한 소켓 도구 자동 지원 (`ss` / `netstat` / `lsof`)**
   * 시스템 환경에 설치된 네트워크 유틸리티(`ss`, `netstat`, `lsof`)를 자동 감지하여 가장 빠르고 신뢰성 높은 방식으로 포트 정보를 수집합니다.
3. **네트워크 연결 상태(State) 필터링**
   * `--state` 옵션을 통해 `LISTEN`, `ESTABLISHED`, `TIME_WAIT` 등 특정 연결 상태의 포트만 선별하여 조회할 수 있습니다 (접두어 매칭 지원).
4. **구조화된 JSON 출력 지원 (`--json`, `--pretty`, `--raw`)**
   * 자동화 스크립트나 CI/CD, 모니터링 에이전트와 연동할 수 있도록 정형화된 JSON 배열 포맷 출력을 지원합니다.
5. **최소 권한(`sudo`) 원칙 준수**
   * 스크립트 자체를 `sudo`로 기동할 필요가 없으며, 다른 사용자의 프로세스 소켓 상세 정보를 조회하는 시점에만 내부적으로 권한을 요청합니다.
6. **지능형 Bash 자동 완성 (`ps-port.completion`)**
   * 옵션 및 연결 상태 이름(`LISTEN`, `ESTABLISHED` 등) 자동 완성을 제공합니다.

---

## ⚙️ 파라미터 명세

```bash
ps-port [--match <pattern> | <pattern>] [--state <state>] [--json [--pretty|--raw]] [--help]
```

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<pattern>`, `--match <pattern>` | 선택 | - | 검색할 프로세스 커맨드라인 매칭 패턴 (위치 인자로 직접 전달 가능) |
| `--state <st>` | 선택 | 전체 | 네트워크 소켓 상태 필터링 (접두어 매칭 가능, 예: `LIST`, `EST`, `ESTAB`) |
| `--json` | 선택 | `false` | 조회 결과를 JSON 배열 형태로 출력 |
| `--pretty` | 선택 | `false` | (`--json` 사용 시) 들여쓰기가 적용된 보기 편한 JSON 출력 |
| `--raw` | 선택 | `true` | (`--json` 사용 시) 한 줄로 압축된 Compact JSON 출력 |
| `--help` | 선택 | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 'nginx' 프로세스가 점유 중인 모든 포트 조회
ps-port nginx

# 2) 'java' 프로세스 중 LISTEN 상태인 포트만 조회
ps-port --match "java" --state LISTEN

# 3) 'postgres' 프로세스의 ESTABLISHED 연결 포트 조회 (상태 접두어 사용)
ps-port postgres --state EST

# 4) 결과를 구조화된 JSON 포맷(Pretty)으로 출력
ps-port --match "redis" --json --pretty

# 5) 셸 파이프라인에서 jq 도구와 결합하여 포트 번호만 추출
ps-port "node" --json | jq -r '.[].port'
```
