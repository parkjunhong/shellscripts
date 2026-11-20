# 🛡️ patch-info

다양한 Linux 배포판(Ubuntu, Debian, RHEL, Rocky Linux, AlmaLinux, CentOS, Fedora, openSUSE, SLES, Arch Linux, Alpine Linux) 및 macOS 환경에서 **패키지 설치 상태를 독립적으로 검사**하거나, OS 벤더의 **보안 권고사항 번호(USN, RHSA, DSA 등)를 입력받아 연관된 CVE 목록을 자동으로 추출하고 체인지로그 내 보안 패치 적용 여부를 블록 단위로 정밀 감사**하는 통합 시스템 CLI 도구입니다.

---

## ✨ 주요 특징

- **OS 권고사항 번호(OSS Number) 기반 연관 CVE 자동 추출**:
  - 수많은 CVE 번호를 일일이 찾아서 입력할 필요 없이, OS 보안 공지 번호(`USN-9159-1`, `RHSA-2021:4356` 등)만 입력하면 도구가 공식 보안 CLI 엔진을 연계하여 **연관 CVE 목록을 자동으로 파싱·추출**합니다.
- **패키지 검사와 보안 감사의 완전한 독립성**:
  - `--package`: 패키지 설치 여부, 빌드 버전, 아키텍처를 표 형태로 깔끔하게 점검 (단독 사용 가능).
  - `--oss-number`: OS 권고 번호 기반 CVE 자동 추출 및 시스템 보안 패치 상태 감사 (단독 사용 가능).
  - 두 옵션을 함께 사용하여 종합 감사 보고서 모드로도 활용 가능.
- **완전한 체인지로그 블록 단위 정밀 파서**:
  - 단순 행 단위 grep으로 인한 문맥 잘림(이전 항목 꼬리 줄 유출) 현상을 원천 차단하고, 매칭된 보안 패치 블록(`* SECURITY UPDATE: ...`) 전체를 온전하게 추출하여 출력.
- **시스템 무변경(Read-Only) 절대 안전 보장**:
  - Ubuntu 환경에서 `pro fix` 실행 시 `--dry-run` 플래그를 하드코딩 격리하여 패키지 임의 설치를 원천 방지하며, RHEL/Rocky(`dnf updateinfo info`), openSUSE(`zypper patch-info`) 등 타 배포판 역시 순수 조회 전용 명령어를 실행합니다.
- **Bash Completion 동적 자동완성**:
  - `--package` 뒤에는 현재 시스템에 설치된 패키지 목록을 실시간 제안하고, `--oss-number` 뒤에는 표준 권고 접두사(`USN-`, `RHSA-`, `CVE-` 등)를 추천.

---

## ⚙️ 파라미터 명세

모든 옵션은 **Long Option 전용**으로 동작합니다.

| 옵션명 | 인자 형식 | 필수 여부 | 기본값 | 설명 |
| :--- | :--- | :---: | :---: | :--- |
| `--package` | `<이름...>` | 선택 | - | 설치 여부 및 버전을 검사할 패키지명 (단독 실행 가능, 공백으로 여러 개 지정 가능) |
| `--oss-number` | `<번호...>` | 선택 | - | 감사할 OS 보안 권고사항 번호(USN, RHSA, DSA 등) 또는 CVE 번호 (단독 실행 가능) |
| `--show-changelog` | 없음 | 선택 | `false` | 필터링 없이 패키지의 전체 체인지로그 텍스트 출력 (`--package` 필요) |
| `--offline` | 없음 | 선택 | `false` | 온라인 보안 API 조회를 차단하고 로컬 파일시스템/캐시만 사용 (폐쇄망 지원) |
| `--verbose` | 없음 | 선택 | `false` | OS 감지, 실행 명령어, 파싱 통계 등 상세 디버그 로그 출력 |
| `--help` | 없음 | 선택 | - | 도움말 메시지 출력 및 종료 |

---

## 🚀 사용 예시

### 1) 패키지 설치 여부 및 버전만 독립적으로 검사
```bash
patch-info --package nginx nginx-core nginx-common
```

### 2) OS 보안 권고 번호만 지정하여 연관 CVE 자동 추출 및 패치 감사
```bash
patch-info --oss-number USN-9159-1
```

### 3) 패키지 설치 검사 및 보안 권고사항 종합 감사 (복합 실행)
```bash
patch-info --package nginx nginx-core nginx-common --oss-number USN-9159-1
```

### 4) 복수 권고 번호 및 CVE 번호 직접 지정 감사
```bash
patch-info --oss-number USN-9159-1 RHSA-2021:4356 CVE-2026-123633 --verbose
```

### 5) 오프라인 모드로 로컬 캐시/파일에서만 검사 (폐쇄망)
```bash
patch-info --package sudo --oss-number USN-4966-1 --offline
```

### 6) 특정 패키지의 전체 체인지로그 열람
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
