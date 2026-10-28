# 🗑️ ssl-del

Java 런타임의 기본 TrustStore(`$JAVA_HOME/lib/security/cacerts`) 및 지정된 추가 cacerts(IDE 또는 사설 Keystore) 파일에서 등록된 특정 SSL/TLS 인증서 별칭(Alias)을 안전하게 조회하고 일괄 삭제하는 인증서 관리 CLI 도구입니다.

---

## ✨ 주요 특징

1. **Java 환경 자동 감지 (Linux & macOS)**
   * `JAVA_HOME` 환경변수가 설정되어 있지 않더라도 시스템 `java` 심볼릭 링크 및 macOS `java_home` 유틸리티를 역추적하여 기본 `cacerts` 파일 경로를 자동으로 식별합니다.
2. **원자적 삭제 및 결과 검증**
   * Java TrustStore에서 `keytool -delete`를 실행한 후, `keytool -list`를 통해 해당 별칭이 완전히 제거되었는지 즉시 검증하고 결과를 보고합니다.
3. **다중 cacerts 파일 일괄 지원 (`-cacerts_files`)**
   * 콤마(`,`) 구분자를 통해 IntelliJ, Eclipse 등 IDE 전용 Keystore 또는 애플리케이션 사설 cacerts 파일 경로를 지정하여 한 번에 동일 별칭의 인증서를 일괄 제거할 수 있습니다.
4. **지능형 Bash 자동 완성 (`ssl-del.completion`)**
   * TrustStore 내에 현재 등록되어 있는 인증서 별칭(Alias) 목록을 `keytool`을 통해 동적으로 조회하여 자동 완성을 추천합니다.
   * `/etc/hosts` 및 `known_hosts` 기반의 서버 도메인 추천과 콤마 구분 다중 파일 경로 완성을 지원합니다.

---

## ⚙️ 파라미터 명세

```bash
ssl-del --server <서버 주소> --alias <별칭> [--cacerts-files <파일1,파일2,...>]
```

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--server <서버 주소>` | **필수** | 대상 서버 도메인 또는 호스트명 (예: `example.com`) |
| `--alias <별칭>` | **필수** | TrustStore에서 삭제할 인증서 별칭(Alias) |
| `--cacerts-files <경로목록>` | 선택 | 기본 Java 외에 추가로 인증서를 삭제할 cacerts 파일 경로 (콤마 구분) |
| `--help` | 선택 | 도움말 메시지 출력 및 종료 |

> **참고**: Java 시스템 영역 Keystore 수정을 위해 스크립트 실행 시 내부적으로 `sudo` 권한을 요청합니다.

---

## 🚀 사용 예시

```bash
# 1) 기본 Java TrustStore에서 특정 인증서 삭제
sudo ./ssl-del --server mycompany.com --alias mycompany.com

# 2) Java TrustStore와 함께 IDE cacerts 파일에서도 일괄 삭제
sudo ./ssl-del \
  --server mycompany.com \
  --alias mycompany.com \
  --cacerts-files ~/.local/share/JetBrains/cacerts,/opt/custom/cacerts
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./ssl-del --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./ssl-del --target global
```

