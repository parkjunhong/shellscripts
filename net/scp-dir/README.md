# 📦 scp-dir

`sshpass` 도구를 이용하여 비밀번호 기반 SSH 인증을 자동화하고, 원격 서버에 대상 디렉토리를 자동 생성한 후 로컬 파일 또는 디렉토리를 안전하게 복사(SCP)하는 파일 전송 CLI 도구입니다.

---

## ✨ 주요 특징

1. **`sshpass` 의존성 자동 확인 및 대화형 설치 지원**
   * 시스템에 `sshpass`가 설치되어 있지 않은 경우, 사용자에게 설치 의사를 묻고(`y/N`) OS 패키지 관리자(`apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `brew` 등)를 자동 감지하여 원클릭으로 설치를 진행합니다.
2. **비밀번호 노출 방지 보안 강화**
   * 커맨드라인 프로세스 목록(`ps aux`)에 비밀번호 평문이 노출되지 않도록 `SSHPASS` 환경변수 방식(`sshpass -e`)을 적용하여 안전하게 인증을 처리합니다.
   * 커맨드라인에서 비밀번호 옵션을 생략하면 대화형 마스킹 입력 프롬프트를 자동으로 제공합니다.
3. **원격 대상 디렉토리 자동 생성 (`mkdir -p`)**
   * 파일 전송 전 대상 서버에 목적지 디렉토리가 존재하는지 확인하고, 미존재 시 원격에서 `mkdir -p`를 선행 실행하여 전송 실패를 원천 방지합니다.
4. **철저한 사전 유효성 검증**
   * 필수 파라미터(호스트, 원본 경로, 대상 경로) 및 로컬 원본 파일/디렉토리 존재 여부, 포트 번호 범위를 사전에 엄격히 검증합니다.
5. **지능형 Bash 자동 완성 (`scp-dir.completion`)**
   * 옵션 플래그 자동 완성뿐만 아니라 로컬 파일/디렉토리 경로 완성, 알려진 호스트(`/etc/hosts`, `known_hosts`) 목록 추천을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
scp-dir --host <대상호스트> --src <소스경로> --dest <원격대상경로> [옵션...]
```

### 필수 옵션
| 옵션 | 설명 |
| :--- | :--- |
| `--host <host>` | 대상 원격 서버 호스트 (IP 주소 또는 도메인) |
| `--src, --source <src>` | 전송할 로컬 원본 파일 또는 디렉토리 경로 |
| `--dest, --destination <dest>` | 원격 서버 대상 디렉토리 경로 |

### 선택 옵션
| 옵션 | 기본값 | 설명 |
| :--- | :---: | :--- |
| `--user, --username <user>` | `$USER` | 원격 서버 사용자 계정 (생략 시 현재 셸 사용자) |
| `--port <port>` | `22` | 원격 SSH 포트 번호 (1 ~ 65535) |
| `--passwd, --password <pwd>` | - | 원격 서버 접속 비밀번호 (생략 시 대화형 마스킹 입력) |
| `--ssh-option <option>` | - | ssh/scp 추가 옵션 (예: `--ssh-option "ConnectTimeout=10"`) |
| `--help` | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

```bash
# 1) 기본 전송 (비밀번호 대화형 마스킹 입력)
./scp-dir --host 192.168.1.100 --src ./my-app --dest /opt/deploy

# 2) 원격 사용자 및 포트 지정 전송
./scp-dir --user deployer --host 192.168.1.100 --port 2222 --src ./config.json --dest /etc/my-app/

# 3) 비밀번호 파라미터 직접 지정 전송
./scp-dir --user root --host 10.0.0.5 --passwd "mypassword" --src ./dist/ --dest /var/www/html/

# 4) SSH 연결 타임아웃 옵션 추가 전송
./scp-dir --host 192.168.1.50 --src ./archive.tar.gz --dest /data/backup/ --ssh-option "ConnectTimeout=5"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./scp-dir --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./scp-dir --target global
```

