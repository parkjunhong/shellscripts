# start-wrangler

`start-wrangler`는 Cloudflare Pages 개발 환경(`wrangler pages dev`)을 손쉽게 기동할 수 있도록 실행 디렉터리, 정적 자산 경로, 바인딩 IP 주소 및 HTTPS SSL 인증서 설정을 자동화하여 안전하고 직관적으로 서빙해 주는 CLI 도구입니다.

---

## ✨ 주요 특징

- **바인딩 IP 파라미터화**: 기본값 `0.0.0.0` 외에 개발 환경에 맞게 원하는 바인딩 IP(`--ip`)를 자유롭게 지정할 수 있습니다.
- **경로 자동 해석 및 검증**:
  - 실행 디렉터리(`--run-dir`) 및 정적 웹 리소스 디렉터리(`--public-dir`)의 실제 존재 여부를 사전에 검증합니다.
  - 상대 경로와 절대 경로를 모두 지원하며 물리적 경로(`pwd -P`)로 안전하게 변환합니다.
- **HTTPS 개발 환경 지원**:
  - `--ssl-key` 및 `--ssl-cert` 옵션을 통해 로컬 개발 시에도 HTTPS 프로토콜(`--local-protocol https`)을 손쉽게 활성화할 수 있습니다.
  - SSL 파일의 존재 및 읽기 권한을 실행 전에 사전 검증합니다.
- **배열 기반 안전한 실행**: 인자들을 Bash 배열로 래핑하여 공백이나 특수 문자가 포함된 경로에서도 단어 분리(Word Splitting) 오류 없이 안전하게 실행됩니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--run-dir <디렉토리>` | **필수** | - | Wrangler 명령어가 실행될 프로젝트 루트 디렉터리 |
| `--public-dir <디렉토리>` | **필수** | - | 정적 웹 자산(`public`, `dist` 등) 디렉터리 (상대/절대 경로) |
| `--ip <IP주소>` | 선택 | `0.0.0.0` | 개발 서버 리슨 IP 주소 |
| `--ssl-key <파일경로>` | 선택 | 없음 | HTTPS 활성화용 SSL Key 파일 경로 (`--ssl-cert`와 쌍으로 필요) |
| `--ssl-cert <파일경로>` | 선택 | 없음 | HTTPS 활성화용 SSL Cert 파일 경로 (`--ssl-key`와 쌍으로 필요) |
| `--help` | 선택 | - | 사용법 및 도움말 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 HTTP 개발 서버 실행
```bash
start-wrangler --run-dir ~/dev/my-project --public-dir ./public
```

### 2. 특정 IP(localhost) 바인딩 실행
```bash
start-wrangler --run-dir ~/dev/my-project --public-dir ./dist --ip 127.0.0.1
```

### 3. HTTPS 개발 서버 실행
```bash
start-wrangler --run-dir ~/dev/my-project --public-dir ./public \
  --ssl-key /etc/nginx/cert/dev.key \
  --ssl-cert /etc/nginx/cert/dev.crt
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./start-wrangler --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./start-wrangler --target global
```
