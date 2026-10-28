# build-deploy-all

특정 디렉토리 하위의 모든 서브 디렉토리를 순회하며 `pom.xml`이 포함된 Maven 프로젝트들을 자동으로 감지하고, 지정된 프로파일에 맞춰 `build-mvn-package` 도구를 순차 실행하여 일괄 빌드 및 배포를 수행하는 다중 프로젝트 빌드 오케스트레이션 도구입니다.

---

## ✨ 주요 특징

- **다중 Maven 프로젝트 자동 탐색**: 지정된 디렉토리 하위의 서브 디렉토리 중 `pom.xml`이 존재하는 유효한 Maven 프로젝트만 필터링하여 순차 실행합니다.
- **`build-mvn-package` 표준 도구 연계**: 빌드 프로파일(`-p`), 자동 배포(`-d`), 소스 최신화(`-u`), 단위 테스트 실행(`-t`) 옵션을 하위 프로젝트의 `build-mvn-package`로 안전하게 전달합니다.
- **경로 정규화 지원**: 상대 경로 또는 절대 경로를 모두 유연하게 처리하며 작업 완료 후 원래 작업 디렉토리로 안전하게 복귀(`pushd`/`popd`)합니다.
- **스마트 Bash 자동완성**: 현재 디렉토리 및 하위 프로젝트들의 `config/` 디렉토리를 탐색하여 유효한 프로파일 목록을 추천하며, 대상 디렉토리 경로 완성도 함께 제공합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--profile <name>` | **필수** | - | Maven 빌드 프로파일 이름 (하위 프로젝트 공통 적용) |
| `--deploy` | 선택 | 비활성 | 빌드 완료 후 프로젝트별 배포 스크립트(`deploy.sh`)를 실행합니다. |
| `--test` | 선택 | 비활성 | 단위 테스트(JUnit)를 실행합니다. (기본은 테스트 건너뜀) |
| `--update` | 선택 | 비활성 | 빌드 전 각 프로젝트에서 `git pull`을 수행합니다. |
| `--help` | 선택 | - | 사용법 및 옵션 도움말을 출력합니다. |
| `[DIR]` | 선택 | `$PWD` | 탐색할 프로젝트 상위 디렉토리 경로 (미지정 시 현재 디렉토리) |

---

## 🚀 사용 예시

### 1. 현재 디렉토리 하위 모든 Maven 프로젝트 일괄 빌드
```bash
build-deploy-all --profile local
```

### 2. 특정 디렉토리 지정 및 git pull 최신화 후 빌드
```bash
build-deploy-all --profile dev --update /home/user/workspace/microservices
```

### 3. 소스 최신화, 단위 테스트 실행, 빌드 후 배포까지 일괄 수행
```bash
build-deploy-all --profile prod --update --test --deploy
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./build-deploy-all --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./build-deploy-all --target global
```
