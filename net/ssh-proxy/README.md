# 🌐 ssh-proxy

프록시(Bastion / Jump) 서버를 경유하여 방화벽 또는 내부 사설망 뒤에 위치한 대상 서버로 SSH 접속하거나, 프록시 서버 자체로 직접 접속할 수 있도록 지원하는 SSH 연결 및 목적지 서비스 관리 CLI 도구입니다.

---

## ✨ 주요 특징

1. **점프 프록시(-J) 자동 연동**
   * `<sts-user>@<sts-host>:<sts-port>/<dest-user>@<dest-server>` 한 줄 형식으로 바스천/점프 서버 경유 설정을 자동 구성합니다 (`ssh -J ...`).
   * 프록시 사용자명 생략 시 현재 로컬 사용자 계정 자동 적용 및 기본 포트(22) 지원.
2. **다이렉트 접속 지원 (`--no-jump`)**
   * 프록시/터널링 서버 자체가 목적지인 경우 점프 프록시 모드를 비활성화하고 해당 서버로 직접 접속합니다.
3. **목적지 서비스(Service) 별칭 관리**
   * `~/.ssh-proxy.services` 설정 파일 기반으로 목적지 호스트/포트 정보를 별칭(Alias)으로 등록, 조회, 삭제, 파일 일괄 가져오기를 지원합니다.
   * 별칭이 등록되지 않은 IP 또는 FQDN 도메인이 입력된 경우에도 직접 대상 호스트로 원활하게 연결됩니다.
4. **안전한 실행 및 인자 보존**
   * `eval` 구문을 원천 배제하고 Bash 배열 기반으로 명령어를 실행하여 셸 인젝션을 방지하고 특수문자 및 추가 SSH 옵션을 온전히 전달합니다.
5. **지능형 Bash 자동 완성 (`ssh-proxy.completion`)**
   * CLI 옵션 자동 완성뿐만 아니라 `--service-delete` 및 `<proxy>/<user>@<TAB>` 입력 시 등록된 서비스 목록을 동적으로 추천합니다.

---

## ⚙️ 파라미터 명세

### 1. 기본 접속 구문
```bash
ssh-proxy [sts-user@]<sts-host>:<sts-port>[/[dest-user@]<dest-server>] [옵션] [추가 SSH 옵션...]
```

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `sts-user` | 선택 | 현재 셸 사용자 | 프록시(점프/바스천) 서버 사용자 계정 |
| `sts-host` | **필수** | - | 프록시 서버 호스트명 또는 IP 주소 |
| `sts-port` | 선택 | `22` | 프록시 서버 SSH 포트 번호 (1 ~ 65535) |
| `dest-user` | 선택 | 현재 셸 사용자 | 최종 목적지 서버 사용자 계정 |
| `dest-server` | 조건부 필수 | - | 등록된 서비스 별칭 또는 목적지 호스트/IP (`--no-jump` 모드에서는 생략 가능) |

### 2. 옵션 플래그
| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--no-jump` | 선택 | 점프 프록시(-J)를 사용하지 않고 프록시 서버 자체로 직접 접속 |
| `--service-list` | 선택 | `~/.ssh-proxy.services`에 등록된 목적지 서비스 목록 출력 |
| `--service-add "<name>=<host> [-p <port>]"` | 선택 | 새로운 목적지 서비스 별칭 추가 또는 갱신 |
| `--service-delete <name>` | 선택 | 등록된 목적지 서비스 별칭 삭제 |
| `--service-file <filepath>` | 선택 | 외부 properties 파일로부터 서비스 목록을 일괄 가져오기 |
| `--help` | 선택 | 도움말 및 사용법 안내 출력 |

---

## 🚀 사용 예시

```bash
# 1) 목적지 서비스 등록
ssh-proxy --service-add "db-internal=10.0.1.50 -p 2222"
ssh-proxy --service-add "web-stage=10.0.2.100"

# 2) 등록된 서비스 목록 조회
ssh-proxy --service-list

# 3) 바스천 프록시를 경유하여 내부 DB 서버 접속 (Jump Proxy 모드)
ssh-proxy bastion.example.com:22/root@db-internal

# 4) 프록시 사용자 계정과 포트 명시 접속
ssh-proxy jumpuser@bastion.example.com:22022/ec2-user@web-stage -i ~/.ssh/id_rsa

# 5) 등록되지 않은 임의의 사설 IP로 직접 점프 접속
ssh-proxy bastion.example.com:22/admin@10.200.1.15

# 6) 점프 없이 바스천 서버 자체로 직접 접속 (--no-jump)
ssh-proxy jumpuser@bastion.example.com:22022 --no-jump

# 7) 목적지 서비스 삭제
ssh-proxy --service-delete db-internal
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./ssh-proxy --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./ssh-proxy --target global
```

