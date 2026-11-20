# 🛡️ patch-info

다양한 Linux 배포판(Ubuntu, Debian, RHEL, Rocky Linux, AlmaLinux, CentOS, Fedora, openSUSE, SLES, Arch Linux, Alpine Linux) 및 macOS 환경에서 설치된 패키지/프로그램/모듈의 빌드 버전 정보를 확인하고, 로컬 및 온라인 체인지로그(Changelog)에서 보안 패치(CVE 번호, USN, RHSA, ALSA 등) 내역을 POSIX 확장 정규식(ERE) 기반으로 고속 검색·감사하는 통합 CLI 도구입니다.

---

## ✨ 주요 특징

- **크로스 플랫폼 패키지 매니저 자동 감지**:
  - Debian 계열: `dpkg-query`, `apt-get changelog`, `/usr/share/doc/<pkg>*/changelog*`
  - Red Hat 계열: `rpm -q`, `rpm -q --changelog`, `dnf updateinfo`
  - SUSE 계열: `rpm -q`, `zypper patch-info`
  - Arch Linux: `pacman -Q`, `pacman -Qc`
  - Alpine Linux: `apk info -v`, `apk audit`
  - macOS: `brew list --versions`, `brew log`
- **가변 인자 및 동적 자동완성**:
  - `--package` 뒤에 공백으로 여러 패키지를 연속 지정하거나 옵션을 반복 입력 가능.
  - Bash 자동완성(`patch-info.completion`)을 통해 시스템에 설치된 실제 패키지 목록을 실시간 추천.
- **온라인 & 로컬 체인지로그 하이브리드 탐색**:
  - 기본적으로 원격 저장소의 최신 체인지로그를 조회하여 시스템 미반영 최신 패치까지 파악.
  - 폐쇄망 및 오프라인 환경을 위한 `--offline` 플래그 완비.
- **강력한 정규식(ERE) 기반 보안 식별자 검색**:
  - CVE 식별자, Ubuntu USN, Red Hat RHSA, Rocky RLSA, 복합 검색(`|`), 연도별 와일드카드, 임의 보안 키워드 검색 지원.
- **디버깅 모드 (`--verbose`)**:
  - OS 감지 결과, 탐색 경로, 온라인 쿼리 상태를 명확히 추적 가능.

---

## ⚙️ 파라미터 명세

모든 옵션은 **Long Option 전용**으로 동작합니다.

| 옵션명 | 인자 형식 | 필수 여부 | 기본값 | 설명 |
| :--- | :--- | :---: | :---: | :--- |
| `--package` | `<이름...>` | **필수** | - | 조회할 패키지명. 공백으로 여러 패키지를 연속 지정하거나 옵션 반복 가능 |
| `--search` | `<패턴>` | 선택 | - | 체인지로그에서 검색할 보안 식별자 또는 POSIX 확장 정규식(ERE) 패턴 |
| `--show-changelog` | 없음 | 선택 | `false` | 필터링 없이 패키지의 전체 체인지로그 텍스트 출력 |
| `--offline` | 없음 | 선택 | `false` | 원격 조회를 차단하고 로컬 파일시스템/캐시만 조회 (폐쇄망 지원) |
| `--verbose` | 없음 | 선택 | `false` | OS 감지, 파일 탐색, 온라인 쿼리 등 상세 디버그 로그 출력 |
| `--help` | 없음 | 선택 | - | 도움말 메시지 출력 및 종료 |

### 📌 `--search <패턴>` 문법 규격 안내
- **표준 문법**: 대소문자를 구분하지 않는 **POSIX 확장 정규식 (ERE)**.
- **단일 보안 식별자**:
  - `CVE-YYYY-NNNN+` (예: `CVE-2021-23017`, `CVE-2026-123007`)
  - Ubuntu 보안 공지: `USN-NNNN-N` (예: `USN-9159-1`, `USN-4966-1`)
  - Red Hat / Rocky 보안 공지: `RHSA-YYYY:NNNN`, `RLSA-YYYY:NNNN`
- **복합 취약점 검색**: 파이프(`|`) 기호로 연결 (예: `"USN-9159-1|CVE-2026-123007|CVE-2026-123633"`)
- **와일드카드/연도 검색**: 정규식 활용 (예: `"CVE-2026-[0-9]+"`)
- **일반 키워드 검색**: 임의의 보안 텍스트 (예: `"buffer overflow"`, `"privilege escalation"`)

---

## 🚀 사용 예시

### 1) 단일 패키지 버전 및 특정 CVE 보안 패치 여부 확인
```bash
patch-info --package nginx --search "CVE-2026-123007"
```

### 2) 여러 패키지를 공백으로 나열하고 복수 CVE/USN 동시 검색
```bash
patch-info --package nginx nginx-core nginx-common --search "USN-9159-1|CVE-2026-123007|CVE-2026-123633"
```

### 3) 패키지 옵션 반복 지정 및 상세 디버그 로그 활성화
```bash
patch-info --package openssl --package bash --search "CVE-2023-[0-9]+" --verbose
```

### 4) 오프라인 모드로 로컬 체인지로그에서만 패치 내역 검색 (폐쇄망)
```bash
patch-info --package sudo --search "privilege escalation" --offline
```

### 5) 패키지의 전체 체인지로그 열람
```bash
patch-info --package nginx --show-changelog
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 연관된 Bash 자동완성 스크립트(`.completion`)와 매뉴얼(`man`) 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 및 ~/.local/share/man 등록) 
../../utils/scriptctl/scriptctl install --script ./patch-info --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 및 /usr/local/share/man 등록) 
../../utils/scriptctl/scriptctl install --script ./patch-info --target global
```
