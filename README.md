# shellscripts

다양한 리눅스/유닉스 환경에서 시스템 엔지니어링, 개발, 빌드, 배포, 네트워크 및 Git 형상 관리를 자동화하기 위해 개발된 셸 스크립트 모음 저장소입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조와 Bash 자동완성(`.completion`) 파일을 지원합니다.

---

## 🛠️ 제공 도구 카테고리

| 카테고리 | 설명 | 주요 제공 도구 |
| :--- | :--- | :--- |
| [**`utils/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/utils/README.md) | 범용 유틸리티 및 스크립트 패키지 관리 도구 | `scriptctl`, `grep-files`, `replace-files` 등 |
| [**`git/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/README.md) | Git 형상 관리 및 다중 저장소 일괄 제어 도구 | `git-commit`, `git-status-all`, `git-branch-cmd` 등 |
| [**`net/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/net/README.md) | 네트워크 인터페이스, 방화벽 및 SSH 연결 제어 도구 | `sshctl`, `ps-port`, `fwc-cli`, `scp-dir` 등 |
| [**`security/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/security/README.md) | SSL/TLS 인증서 관리 및 해시 암호화 유틸리티 | `ssl-inst`, `ssl-del`, `authelia-crypto-hash` |
| [**`build/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/build/README.md) | 프로젝트 빌드 부산물(`deploy`, `target`) 일괄 정리 및 배포 실행 도구 | `clean-project`, `remove-deploy`, `deploy-profile` |
| [**`maven/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/maven/README.md) | Apache Maven 빌드 오케스트레이션, 버전 스위칭 및 사설 저장소 배포 | `build-mvn-package`, `build-deploy-all`, `mvn-deploy`, `update-mvn-config`, `upload-mvn-dependencies` |
| [**`io/`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/io/README.md) | 파일 병합, 라인 추출, CSV 유효성 검증 및 I/O 처리 도구 | `validate-csv`, `csv-column-required`, `concat-files`, `cplines` |

---

## 🚀 도구 및 Bash 자동완성 설치 (`scriptctl`)

본 저장소의 모든 스크립트와 Bash 자동완성(`.completion`)은 저장소 내장 설치 관리자인 [**`scriptctl`**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/utils/scriptctl/README.md)을 통해 설치하는 것을 기본 원칙으로 합니다.

`scriptctl`은 실행 스크립트를 지정된 경로에 설치함과 동시에, 최신 리눅스 표준 자동완성 디렉토리인 `/usr/share/bash-completion/completions/<스크립트명>`(또는 사용자 환경)에 자동완성 규칙을 자동으로 등록합니다.

```bash
# scriptctl 실행 권한 부여
chmod +x utils/scriptctl/scriptctl

# 1. 개인 환경 설치 (~/bin 및 사용자 자동완성 등록)
./utils/scriptctl/scriptctl install <카테고리>/<도구명>

# 2. 시스템 전역 설치 (/usr/local/bin 및 /usr/share/bash-completion/completions/ 등록)
sudo ./utils/scriptctl/scriptctl install <카테고리>/<도구명> --target global
```
