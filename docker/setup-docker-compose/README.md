# 🏗️ setup-docker-compose

새로운 Docker Compose 서비스를 구성할 때 필요한 **표준 작업 디렉토리(`<directory>/<service>`)**, **환경변수 파일(`.env`)**, 그리고 **로그 로테이션 및 필수 환경변수 검증 템플릿이 적용된 `docker-compose.yml`** 파일을 자동으로 스캐폴딩(Scaffolding)하는 스크립트입니다.

---

## ✨ 주요 특징

1. **표준화된 `.env` 및 `docker-compose.yml` 초기 템플릿 생성**
   * `.env`: 타임존(`TZ: Asia/Seoul`), 프로젝트명(`NAME`), 이미지(`IMAGE_NAME`, `IMAGE_TAG`), 컨테이너명(`CONTAINER_NAME`), 포트(`PORTS`) 기본 변수를 생성합니다.
   * `docker-compose.yml`:
     * 입력된 서비스명을 자동으로 소문자 `snake_case`로 변환하여 서비스 키로 등록합니다.
     * `x-logging` 앵커(`local` 드라이버, `max-size: 10m`, `max-file: 5`)를 기본 적용하여 컨테이너 로그 비대화를 방지합니다.
     * `${IMAGE_NAME:?Required IMAGE_NAME}` 등 필수 환경변수 누락 시 즉시 에러를 반환하는 안전한 치환 문법을 적용합니다.
2. **스마트 권한 감지 및 덮어쓰기 방지**
   * 대상 상위 디렉토리의 쓰기 권한을 사전 점검하여 일반 사용자 권한으로 생성 가능한 경우 `sudo` 없이 수행하며, 권한이 없는 경로(`/opt` 등)일 때만 `sudo` 인증을 요청합니다.
   * 대상 경로에 이미 `.env` 또는 `docker-compose.yml`이 존재하는 경우 기존 설정 보호를 위해 작업을 즉시 중단합니다.
3. **시뮬레이션 모드 (`--dry-run`) 지원**
   * 실제 디렉토리나 파일을 생성하지 않고, 생성될 경로와 `.env` 및 `docker-compose.yml` 파일의 전체 내용을 미리 화면으로 확인할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--directory <path>` | **필수** | 서비스 디렉토리가 생성될 상위 부모 디렉토리 경로 |
| `--service <name>` | **필수** | 생성할 서비스 식별자 이름 (영문 대소문자, 숫자, `-`, `_` 허용) |
| `--dry-run` | 선택 | 실제 파일시스템 변경 없이 생성될 디렉토리 및 파일 내용만 시뮬레이션 출력 |
| `--help` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) 실제 생성 전 --dry-run으로 생성될 .env 및 docker-compose.yml 내용 미리보기
./setup-docker-compose --directory /opt/services --service AuthService --dry-run

# 2) /opt/services/user-api 디렉토리 및 초기 Compose 구성 파일 생성
./setup-docker-compose --directory /opt/services --service user-api
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./setup-docker-compose --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./setup-docker-compose --target global
```

