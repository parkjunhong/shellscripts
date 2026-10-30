# 🚀 send-certificate

Let's Encrypt를 통해 발급된 와일드카드 인증서 원본(`cert1.pem`, `chain1.pem`, `fullchain1.pem`, `privkey1.pem`)을 **4가지 포맷(`pem`, Nginx용 `sslca`, `pkcs12`, Java `jks`)**으로 일괄 변환하고, 서비스 목록 설정 파일(`services-list.txt`)에 정의된 다수의 원격 서버로 `scp` 전송 및 `ssh` 사후 명령어(서비스 재기동 등)를 자동 수행하는 통합 인증서 변환·배포 도구입니다.

---

## ✨ 주요 특징

1. **4종 인증서 포맷 원스톱 일괄 변환**
   * `pem`: Let's Encrypt 원본 PEM 파일(`cert1.pem`, `chain1.pem`, `fullchain1.pem`, `privkey1.pem`)
   * `sslca`: Nginx 등 웹서버 적용을 위한 `.crt`(`fullchain1.pem` 복사본) 및 `.key`(`openssl pkey` 변환본)
   * `pkcs12`: OpenSSL 기반 표준 `.p12` 키스토어 번들 생성
   * `jks`: `.p12`를 기반으로 Java KeyStore(`.jks`)를 생성하고, 최신 **ISRG Root X1 CA** 및 **Intermediate CA** 인증서까지 체인에 자동 주입
2. **원격 서버 SSH Host Key 변경 자동 복구 및 재시도 (`handle_host_key_changed`)**
   * `scp` 전송 또는 `ssh` 사후 명령 실행 중 원격 서버 재설치 등으로 인한 `REMOTE HOST IDENTIFICATION HAS CHANGED` 오류가 감지되면, 자동으로 `ssh-keygen -R <host>`를 실행하여 기존 호스트 키를 제거하고 `StrictHostKeyChecking=accept-new` 옵션으로 즉시 재전송/재실행을 수행합니다.
3. **유연한 배포 제어 및 시뮬레이션 모드**
   * `--target-ca`: `pem,sslca,pkcs12,jks` 중 특정 유형의 서버만 선별하여 배포 가능
   * `--no-send`: 변환만 수행하고 원격 서버 전송 및 CLI 실행은 생략
   * `--no-delete`: 배포 완료 후 생성된 변환 디렉토리(`ssl_ca`, `pkcs12`, `jks`)를 삭제하지 않고 보존
   * `--dry-run`: `--no-send`와 `--no-delete`를 동시에 활성화하여 안전하게 변환 결과 검증
4. **지능형 Bash 자동완성 (`send-certificate.completion`)**
   * 파일 경로(`--service-files`, `--ssh-key`) 및 콤마(`,`) 구분 다중 인증서 유형(`--target-ca`) 자동완성을 지원합니다.

---

## ⚙️ 파라미터 및 설정 명세

### 1. CLI 파라미터
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--wildcard-domain <도메인>` | **필수** | - | 대상 와일드카드 기준 루트 도메인 (예: `example.com`) |
| `--service-files <파일경로>` | **필수** | - | 배포 대상 서버 및 사후 명령어가 정의된 설정 파일 경로 ([`services-list.txt`](services-list.txt) 참조) |
| `--ssh-key <파일경로>` | **필수** | - | 원격 서버 `scp`/`ssh` 접속에 사용할 SSH 개인키 파일 경로 |
| `--p12-pwd <비밀번호>` | **필수** | - | PKCS#12(`.p12`) 및 JKS(`.jks`) 생성에 사용할 비밀번호 (공백 제외 4자 이상) |
| `--target-ca <유형목록>` | 선택 | 전체 (`pem,sslca,pkcs12,jks`) | 전송할 인증서 유형을 쉼표(`,`)로 구분하여 지정 |
| `--no-send` | 선택 | 비활성 | 원격 서버로 파일을 전송하지 않고 변환만 수행 |
| `--no-delete` | 선택 | 비활성 | 작업 종료 후 변환된 임시 인증서 디렉토리를 삭제하지 않고 유지 |
| `--dry-run` | 선택 | 비활성 | `--no-send`와 `--no-delete`를 동시에 활성화 |
| `--help` | 선택 | - | 도움말 메시지를 출력하고 종료합니다. |

### 2. 필수 환경변수
| 환경변수 | 필수 여부 | 예시 값 | 설명 |
| :--- | :---: | :---: | :--- |
| `LETSENC_INSTDIR` | **필수** | `/etc/letsencrypt` | Let's Encrypt `archive/<domain>` 디렉토리가 위치한 루트 경로 |

### 3. 서비스 목록 파일 포맷 ([`services-list.txt`](services-list.txt))
각 라인은 세미콜론(`;`)으로 구분된 3개의 필드로 구성됩니다 (`#` 주석 및 빈 줄 무시):
```text
<type>;<userid>@<target>:/absolute/path[;<cli>]
```
- **`<type>`**: `pem` | `sslca` | `pkcs12` | `jks`
- **`<userid>@<target>:/absolute/path`**: 인증서 파일들이 복사될 원격 서버 계정, 호스트(IP/도메인), 절대 경로
- **`<cli>`** *(선택)*: 파일 전송 성공 후 원격 서버에서 실행할 명령어 (예: `sudo systemctl reload nginx`)

---

## 🚀 사용 예시

### 1. 전체 서비스 대상 인증서 변환 및 일괄 원격 배포
```bash
export LETSENC_INSTDIR="/etc/letsencrypt"

send-certificate \
  --wildcard-domain "example.com" \
  --service-files ./services-list.txt \
  --ssh-key ~/.ssh/id_rsa \
  --p12-pwd "MyKeystorePass123!"
```

### 2. 특정 포맷(`sslca`, `pkcs12`)만 시뮬레이션(`--dry-run`) 검증
```bash
export LETSENC_INSTDIR="/etc/letsencrypt"

send-certificate \
  --wildcard-domain "example.com" \
  --service-files ./services-list.txt \
  --ssh-key ~/.ssh/id_rsa \
  --p12-pwd "MyKeystorePass123!" \
  --target-ca sslca,pkcs12 \
  --dry-run
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./send-certificate --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./send-certificate --target global
```
