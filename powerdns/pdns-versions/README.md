# 🐳 pdns-versions

운영 중인 Docker 기반 PowerDNS 스택(**PowerDNS Auth**, **PowerDNS Recursor**, **PowerDNS dnsdist**, **PowerDNS-Admin**, **MariaDB**)의 각 컨테이너 실행 상태 및 내부 바이너리 버전을 일괄 점검하고, 미설치 또는 정지된 구성요소에 대해 직관적인 상태 메시지를 제공하는 CLI 점검 도구입니다.

---

## ✨ 주요 특징

1. **지능형 2단계 컨테이너 감지 (Discovery)**
   * 기본 컨테이너 이름(`pdns-auth`, `pdns-recursor`, `pdns-dnsdist`, `pdns-admin`, `mariadb`)으로 우선 탐색합니다.
   * 컨테이너 이름이 다를 경우 이미지 이름 키워드(`pdns-auth`, `pdns-recursor`, `dnsdist`, `pda-legacy`, `mariadb`)를 기반으로 실행 중인 컨테이너를 자동 식별합니다.
2. **컴포넌트별 최적화된 바이너리 및 메타데이터 버전 추출**
   * `pdns_server`, `pdns_recursor`, `dnsdist`, `mariadbd`(또는 `mariadb`/`mysqld`) 내부 바이너리를 실행하여 실제 릴리즈 버전을 추출합니다.
   * 웹 애플리케이션인 PowerDNS-Admin은 내부 환경변수, 소스 메타데이터(`__version__`), 이미지 릴리즈 태그 순으로 정확히 판별합니다.
3. **직관적인 상태 표시 및 트러블슈팅 가이드**
   * 컨테이너 상태에 따라 `[🟢  실행 중]`, `[🔴  정지 중]`, `[❌  미설치]`로 구분하여 터미널에 표시합니다.
   * 정지된 컨테이너가 존재할 경우 컨테이너 시작 명령어(`docker start <이름>`)를 즉시 안내합니다.
4. **터미널 테이블 및 JSON 출력 지원**
   * `column -t`를 활용하여 터미널 폭에 맞춘 가독성 높은 테이블 렌더링을 제공합니다.
   * CI/CD, 모니터링 시스템 연계를 위한 표준 JSON 포맷(`--json`)을 기본 지원합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--auth <name>` | 선택 | `pdns-auth` | PowerDNS Auth 컨테이너 이름 직접 지정 |
| `--recursor <name>` | 선택 | `pdns-recursor` | PowerDNS Recursor 컨테이너 이름 직접 지정 |
| `--dnsdist <name>` | 선택 | `pdns-dnsdist` | PowerDNS dnsdist 컨테이너 이름 직접 지정 |
| `--admin <name>` | 선택 | `pdns-admin` | PowerDNS-Admin 컨테이너 이름 직접 지정 |
| `--db <name>` | 선택 | `mariadb` | MariaDB 컨테이너 이름 직접 지정 |
| `-j, --json` | 선택 | `false` | 점검 결과를 표준 JSON 포맷으로 출력 |
| `-v, --verbose` | 선택 | `false` | 내부 명령어 실행 원본 출력(Raw Output)도 함께 표시 |
| `-h, --help` | 선택 | - | 사용법 및 옵션 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 기본 설정으로 전체 컴포넌트 버전 점검
pdns-versions

# 2) JSON 포맷으로 출력 (모니터링 또는 파이프라인 연계)
pdns-versions --json

# 3) 특정 컨테이너 이름을 직접 지정하여 점검
pdns-versions --auth my-pdns-auth --recursor my-recursor

# 4) 내부 실행 디버그 메시지 함께 확인
pdns-versions --verbose
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./pdns-versions --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./pdns-versions --target global
```
