# 📥 ssl-inst

원격 HTTPS/SSL 서버로부터 실시간 인증서를 직접 다운로드받아, Java 기본 TrustStore(`$JAVA_HOME/lib/security/cacerts`) 및 지정된 추가 cacerts(IDE 또는 사설 Keystore) 파일에 자동 등록(`keytool -import`)하고 SHA-256 지문(Fingerprint) 검증까지 수행하는 SSL 인증서 등록 CLI 도구입니다.

---

## ✨ 주요 특징

1. **원클릭 OpenSSL 실시간 인증서 수집**
   * 별도의 인증서 파일 다운로드 절차 없이 `openssl s_client`를 통해 대상 서버(`-server <도메인>`)의 443 포트에서 PEM 형식의 최신 인증서를 즉시 추출합니다.
2. **Java cacerts 자동 갱신 및 기존 별칭 교체**
   * TrustStore 내에 동일한 별칭(`-alias`)이 이미 존재하는 경우 충돌을 방지하기 위해 기존 인증서를 먼저 안전하게 제거한 뒤 신규 인증서를 등록합니다.
3. **SHA-256 Fingerprint 지문 출력 및 무결성 검증**
   * 등록된 인증서의 실제 SHA-256 지문을 터미널에 출력하여 관리자가 발급 기관과 인증서 유효성을 즉시 검증할 수 있도록 지원합니다.
4. **다중 cacerts 파일 일괄 등록 (`-cacerts_files`)**
   * Java 표준 TrustStore뿐만 아니라 개발용 IDE(IntelliJ 등) cacerts 파일에도 콤마(`,`) 구분자를 통해 한 번에 동시 등록할 수 있습니다.
5. **임시 파일 안전 정리**
   * 작업 완료 또는 오류 시 다운로드된 임시 인증서 파일을 자동으로 안전하게 삭제합니다.
6. **지능형 Bash 자동 완성 (`ssl-inst.completion`)**
   * `-server`에 입력된 도메인명을 기반으로 `-alias` 추천, `/etc/hosts` 호스트 제안, 콤마 분리 파일 경로 자동 완성을 제공합니다.

---

## ⚙️ 파라미터 명세

```bash
ssl-inst -server <서버 주소> -alias <별칭> [-cacerts_files <파일1,파일2,...>]
```

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `-server <서버 주소>` | **필수** | 인증서를 다운로드할 대상 서버 도메인 (예: `auth.example.com`) |
| `-alias <별칭>` | **필수** | TrustStore에 등록할 고유 별칭(Alias) 이름 |
| `-cacerts_files <경로목록>` | 선택 | 추가로 인증서를 등록할 cacerts 파일 경로 목록 (콤마 구분) |
| `-h`, `--help` | 선택 | 도움말 메시지 출력 및 종료 |

> **참고**: Java 시스템 영역 Keystore 수정을 위해 스크립트 실행 시 내부적으로 `sudo` 권한을 요청합니다.

---

## 🚀 사용 예시

```bash
# 1) 원격 서버 인증서를 기본 Java TrustStore에 등록
sudo ./ssl-inst -server auth.example.com -alias auth.example.com

# 2) Java TrustStore 및 IDE cacerts 파일에 동시 등록
sudo ./ssl-inst \
  -server api.example.com \
  -alias api.example.com \
  -cacerts_files ~/.local/share/JetBrains/cacerts
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./ssl-inst --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./ssl-inst --target global
```

