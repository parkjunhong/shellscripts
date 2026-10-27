# 🔒 Security (Security & Certificate Management Scripts)

SSL/TLS 인증서 다운로드·설치·삭제 라이프사이클 관리 및 보안 인증 시스템(Authelia) 암호화 해시 생성을 지원하는 보안 관리 유틸리티 스크립트 모음입니다.

---

## 📂 도구 목록 및 디렉토리 구조

모든 도구는 표준 **Canonical Directory** 구조로 배치되어 있으며, 각 디렉토리 내에 독립 실행 스크립트, Bash 자동 완성(`.completion`), 상세 `README.md`를 포함합니다.

| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`authelia-crypto-hash`** | Docker 기반 Authelia 암호화 해시(Argon2, bcrypt, scrypt 등) 안전 생성 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/security/authelia-crypto-hash/README.md) |
| **`ssl-inst`** | 원격 SSL/TLS 서버 인증서 다운로드 및 Java / IDE cacerts 자동 등록 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/security/ssl-inst/README.md) |
| **`ssl-del`** | Java TrustStore 및 추가 cacerts 파일에서 특정 인증서 별칭 일괄 삭제 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/security/ssl-del/README.md) |

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 개인 실행 경로(`~/bin` 또는 `~/.local/bin`) 또는 전역 경로(`/usr/local/bin`)에 설치하여 바로 사용할 수 있습니다.

### `scriptctl` 도구를 사용한 간편 설치
저장소의 `utils/scriptctl` 유틸리티를 사용하면 스크립트와 Bash 자동 완성을 시스템에 한 번에 설치할 수 있습니다:

```bash
# 예: authelia-crypto-hash 설치 (개인 환경: ~/bin)
../../utils/scriptctl/scriptctl install --script ./authelia-crypto-hash/authelia-crypto-hash --target local

# 예: ssl-inst 설치
../../utils/scriptctl/scriptctl install --script ./ssl-inst/ssl-inst --target local
```
