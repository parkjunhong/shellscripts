# install-docker-dev-config

Spring/Maven 프로젝트의 Docker 및 Docker Compose 배포 환경 구성을 위한 표준 리소스(`docker`, `docker-compose`, `workdir/install`, `workdir/deploy.sh`)를 원격 저장소(`maven-deploy-config`)에서 다운로드하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **의존성 자동 검증 및 설치 (`git-getpr`)**: 실행 전 `git-getpr` 도구의 로컬 설치 여부와 원격 최신 버전과의 무결성(`cmp -s`)을 자동으로 검증하고, 미설치 또는 변경 감지 시 자동으로 최신 버전을 설치/업데이트합니다.
- **선택적/일괄 리소스 다운로드**: 대화형 메뉴 또는 `--resources` 옵션을 통해 필요한 배포 자원만 선택하거나 전체(`all`)를 일괄 다운로드할 수 있습니다.
- **Long Option 전용 인터페이스**: `--resources`, `--help` 옵션을 지원하며 연관된 Bash 자동완성(`.completion`)을 제공합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 | 허용 값 예시 |
| :--- | :---: | :--- | :--- |
| `--resources <LIST>` | 선택 | 다운로드할 자원 식별자 또는 번호 목록 (콤마 구분, 생략 시 대화형 선택) | `all`, `docker`, `docker-compose`, `os_version`, `deploy.sh`, `1,2` |
| `--help` | 선택 | 도움말 및 사용법을 출력하고 종료합니다. | - |

---

## 🚀 사용 예시

```bash
# 1. 대화형 모드로 실행 (번호 선택 프롬프트 출력)
install-docker-dev-config

# 2. 모든 배포 환경 리소스 일괄 다운로드
install-docker-dev-config --resources all

# 3. 특정 리소스만 선택하여 다운로드 (콤마 구분)
install-docker-dev-config --resources docker,docker-compose
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./install-docker-dev-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./install-docker-dev-config --target global
```
