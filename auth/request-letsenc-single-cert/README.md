# 📜 request-letsenc-single-cert

쉼표(`,`)로 구분된 도메인 문자열(`--domains`) 또는 도메인 목록 파일(`--file`)을 입력받아 중복을 제거하고 도메인 형식을 검증한 뒤, `certbot certonly --standalone` 모드를 통해 **각 도메인별 단일 Let's Encrypt SSL/TLS 인증서를 일괄 발급**하는 CLI 자동화 도구입니다.

---

## ✨ 주요 특징

1. **다중 도메인 입력 및 병합 지원 (`--domains`, `--file`)**
   * CLI 인자(`--domains`)로 직접 쉼표 구분 도메인 목록을 전달하거나, 줄바꿈으로 작성된 도메인 목록 파일(`--file`)을 전달할 수 있으며, 두 옵션을 동시에 지정하여 병합 처리할 수도 있습니다.
2. **자동 중복 제거 및 도메인 정규식 검증**
   * 입력된 도메인 목록에서 중복 항목을 자동으로 제거(`sort -u`)하고, 유효한 도메인 네임 정규식(`DN_REGEX`)과 일치하는지 사전 검증합니다.
3. **사전 Root 권한 검증 (`ensure_root`)**
   * `certbot` standalone 웹서버 바인딩(80 포트) 및 `/etc/letsencrypt` 접근을 위해 실행 시 `root`(또는 `sudo`) 권한 여부를 즉시 확인합니다.
4. **지능형 Bash 자동완성 (`request-letsenc-single-cert.completion`)**
   * 이미 사용한 옵션은 중복 추천에서 제외하며, `--file` 옵션 뒤에서는 파일 경로 자동완성을 지원합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--domains <도메인목록>` | 선택* | - | 쉼표(`,`)로 구분된 발급 대상 도메인 목록 (`--file`과 최소 택 1 필수) |
| `--file <파일경로>` | 선택* | - | 한 줄에 하나씩 도메인이 기록된 텍스트 파일 경로 (`--domains`와 최소 택 1 필수) |
| `--help` | 선택 | - | 도움말 메시지를 출력하고 종료합니다. |

---

## 🚀 사용 예시

### 1. 쉼표 구분 도메인 목록으로 단일 인증서 일괄 발급
```bash
sudo request-letsenc-single-cert --domains "api.example.com,auth.example.com"
```

### 2. 파일에 정의된 도메인 목록으로 일괄 발급
```bash
sudo request-letsenc-single-cert --file ./domains.txt
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./request-letsenc-single-cert --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./request-letsenc-single-cert --target global
```
