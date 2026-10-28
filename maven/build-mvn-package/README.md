# build-mvn-package

사용자 정의 빌드 프로파일을 기반으로 Maven 프로젝트를 클린 빌드(`clean package`)하고, 옵션에 따라 소스 최신화(`git pull`), 테스트 실행 여부 제어, 빌드 후 자동 배포(`deploy.sh`) 연계를 지원하는 표준 Maven 빌드 자동화 도구입니다.

---

## ✨ 주요 특징

- **동적 프로파일 기반 빌드**: `-Dbuild.profile=<profile>` 설정을 통해 로컬/개발/운영 등 환경별 빌드를 손쉽게 분기 실행합니다.
- **빌드 전 소스 최신화 연계**: `--update` 옵션 지정 시 `git pull`을 먼저 수행하여 최신 형상을 안전하게 빌드합니다.
- **테스트 선택 제어**: 기본 빌드 시에는 불필요한 테스트를 건너뛰어 빌드 속도를 높이고, 필요 시 `--test` 옵션을 통해 단위 테스트를 실행합니다.
- **자동 배포 스크립트 연계**: 빌드 성공 후 `./deploy/<profile>/deploy.sh`를 자동 실행하며 배포 옵션(Docker 이미지 빌드, 컨테이너 기동 등)을 유연하게 전달합니다.
- **스마트 Bash 자동완성**: `config/` 및 `config.profiles/` 디렉토리를 자동 탐색하여 정의된 프로파일 이름을 탭(`<TAB>`) 한 번으로 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--profile <name>` | **필수** | - | 빌드 프로파일 이름을 지정합니다. (`-Dbuild.profile=<name>`) |
| `--test` | 선택 | `false` (Skip) | 단위 테스트(JUnit)를 실행합니다. (미지정 시 테스트 건너뜀) |
| `--update` | 선택 | 비활성 | 빌드 전 `git pull`을 수행하여 소스 코드를 최신화합니다. |
| `--debug` | 선택 | 비활성 | Maven 디버그 모드(`-X`)를 활성화합니다. |
| `--offline` | 선택 | 비활성 | 네트워크 접근 없이 로컬 저장소 캐시로만 빌드합니다 (`mvn -o`). |
| `--deploy[="<opts>"]` | 선택 | 비활성 | 빌드 완료 후 `./deploy/<profile>/deploy.sh`를 실행합니다. |
| `--help` | 선택 | - | 사용법 및 옵션 도움말을 출력합니다. |

### 🐳 Docker 배포 옵션 (`--deploy` 인자 연계)
- `--docker`: Docker 컨테이너 기반으로 배포합니다.
- `--build-only`: 컨테이너를 기동하지 않고 Docker 이미지만 빌드합니다.
- `--offline-image`: 오프라인 환경용 사전 빌드된 Docker 이미지(`tar`)를 로드합니다.

---

## 🚀 사용 예시

### 1. 기본 프로파일 빌드
```bash
build-mvn-package --profile prod
```

### 2. 소스 최신화(`git pull`) 후 단위 테스트 실행 빌드
```bash
build-mvn-package --profile dev --update --test
```

### 3. 빌드 완료 후 Docker 컨테이너 배포까지 일괄 수행
```bash
build-mvn-package --profile prod --deploy="--docker"
```

### 4. 오프라인 모드 및 Maven 디버그 모드 빌드
```bash
build-mvn-package --profile staging --offline --debug
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./build-mvn-package --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./build-mvn-package --target global
```
