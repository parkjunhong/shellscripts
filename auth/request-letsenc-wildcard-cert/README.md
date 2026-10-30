# 🌟 request-letsenc-wildcard-cert

`certbot`의 수동 DNS 챌린지(`--manual --preferred-challenges=dns`) 방식을 이용하여 루트 도메인(`<domain>`) 및 **와일드카드 도메인(`*.<domain>`)이 통합된 Let's Encrypt SSL/TLS 인증서를 발급·갱신**하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **루트 및 와일드카드 도메인 동시 발급**
   * `--root-domain`에 루트 도메인(예: `example.com`)만 입력하면 `-d example.com -d *.example.com` 구문을 자동으로 구성하여 ACME v2 서버에 인증서를 요청합니다.
2. **환경변수(`LETSENC_INSTDIR`) 기반 안전한 디렉토리 관리**
   * `LETSENC_INSTDIR` 환경변수로 지정된 Certbot 설정 디렉토리 경로를 검증하며, 발급 전 기존 `archive`, `live`, `renewal` 하위 디렉토리의 파일 목록을 출력하고 대화형 승인(`Y/N`)을 거쳐 안전하게 정리합니다.
3. **경로 정규화 보호 장치**
   * 디렉토리 정리 시 경로 정규화 비교를 통해 루트 설정 디렉토리 자체가 오삭제되는 사고를 원천 차단합니다.
4. **지능형 Bash 자동완성 (`request-letsenc-wildcard-cert.completion`)**
   * 이미 입력된 옵션은 중복 추천에서 제외하는 스마트 자동완성을 지원합니다.

---

## ⚙️ 파라미터 및 환경변수 명세

### 1. CLI 파라미터
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--root-domain <도메인>` | **필수** | - | 발급할 기준 루트 도메인 (예: `example.com`) |
| `--email <이메일>` | **필수** | - | Let's Encrypt 만료 알림 및 계정 등록용 이메일 주소 |
| `--help` | 선택 | - | 도움말 메시지를 출력하고 종료합니다. |

### 2. 필수 환경변수
| 환경변수 | 필수 여부 | 예시 값 | 설명 |
| :--- | :---: | :---: | :--- |
| `LETSENC_INSTDIR` | **필수** | `/etc/letsencrypt` | `certbot --config-dir`로 전달할 Let's Encrypt 작업 디렉토리 경로 |

---

## 🚀 사용 예시

### 1. 와일드카드 인증서 발급/갱신 실행
```bash
export LETSENC_INSTDIR="/etc/letsencrypt"

request-letsenc-wildcard-cert \
  --root-domain "example.com" \
  --email "admin@example.com"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./request-letsenc-wildcard-cert --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./request-letsenc-wildcard-cert --target global
```
