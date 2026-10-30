# 🐳 Docker & Container Management Shell Scripts

리눅스 환경에서 Docker CE 엔진 자동 설치(`install-docker`), 컨테이너 맞춤형 컬럼 및 필터 조회(`dkcontls`), 서브넷 충돌 사전 검증 기반 브릿지 네트워크 제어(`dknetcli`), GitLab 공식 이미지 일괄 다운로드 및 오프라인 아카이빙(`pull-gitlab-images`), 그리고 Docker Compose 프로젝트 초기 스캐폴딩(`setup-docker-compose`) 및 Systemd OS 서비스 등록 자동화(`setup-compose-service`)를 지원하는 표준 CLI 컨테이너 관리 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`docker/<tool>/<tool>`), 최신 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **dkcontls** | [`dkcontls/`](dkcontls/dkcontls) | `docker container ls` 래퍼, 콤마 구분 다중 출력 컬럼(`--format`) 선택 및 15종 필터(`--filter`) 동적 자동완성 | ✅ 지원 | [상세보기](dkcontls/README.md) |
| **dknetcli** | [`dknetcli/`](dknetcli/dknetcli) | 커널 브릿지 바인딩 및 서브넷 대역 중첩(Overlap) 5단계 사전 검증 기반 Docker 브릿지 네트워크 생성·삭제·조회 | ✅ 지원 | [상세보기](dknetcli/README.md) |
| **install-docker** | [`install-docker/`](install-docker/install-docker) | 리눅스 배포판(`apt`, `dnf`, `yum`) 자동 감지, 외부 PPA 장애 격리 및 `docker` 그룹 권한 구성 일괄 설치 | ✅ 지원 | [상세보기](install-docker/README.md) |
| **install-docker-dev-config** | [`install-docker-dev-config/`](install-docker-dev-config/install-docker-dev-config) | Spring/Maven 프로젝트의 Docker 및 Docker Compose 표준 배포 구성 리소스(`maven-deploy-config`) 다운로드 | ✅ 지원 | [상세보기](install-docker-dev-config/README.md) |
| **pull-gitlab-images** | [`pull-gitlab-images/`](pull-gitlab-images/pull-gitlab-images) | 다중 GitLab 버전 공식 이미지(`gitlab-ee`/`ce`) 일괄 다운로드(`pull`) 및 오프라인 배포용 `.tar` 아카이브 저장(`save`) | ✅ 지원 | [상세보기](pull-gitlab-images/README.md) |
| **setup-compose-service** | [`setup-compose-service/`](setup-compose-service/setup-compose-service) | Docker Compose 프로젝트의 Systemd 유닛(`.service`), 전용 제어 스크립트(`<service>-ctl.sh`) 및 자동완성 일괄 생성 | ✅ 지원 | [상세보기](setup-compose-service/README.md) |
| **setup-docker-compose** | [`setup-docker-compose/`](setup-docker-compose/setup-docker-compose) | 로그 로테이션 및 필수 환경변수 검증이 적용된 표준 `.env` 및 `docker-compose.yml` 디렉토리 스캐폴딩 | ✅ 지원 | [상세보기](setup-docker-compose/README.md) |

---

## 📂 디렉토리 구조

```text
docker/
├── README.md                                   # Docker 도구 종합 안내 (본 문서)
├── dkcontls/
│   ├── dkcontls                                # 컨테이너 다중 컬럼 선택 및 필터 조회 CLI 도구
│   ├── dkcontls.completion                     # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
├── dknetcli/
│   ├── dknetcli                                # 브릿지 네트워크 라이프사이클 및 서브넷 충돌 검증 도구
│   ├── dknetcli.completion                     # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
├── install-docker/
│   ├── install-docker                          # 다중 배포판 지원 Docker CE 및 플러그인 설치 도구
│   ├── install-docker.completion               # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
├── install-docker-dev-config/
│   ├── install-docker-dev-config               # Maven/Docker 표준 배포 환경 리소스 다운로드 도구
│   ├── install-docker-dev-config.completion    # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
├── pull-gitlab-images/
│   ├── pull-gitlab-images                      # GitLab 이미지 일괄 Pull 및 오프라인 tar 저장 도구
│   ├── pull-gitlab-images.completion           # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
├── setup-compose-service/
│   ├── setup-compose-service                   # Docker Compose 기반 Systemd 서비스 및 제어 스크립트 생성기
│   ├── setup-compose-service.completion        # Bash 자동완성 스크립트
│   └── README.md                               # 개별 도구 상세 설명서
└── setup-docker-compose/
    ├── setup-docker-compose                    # 표준 Docker Compose 프로젝트(.env, yml) 스캐폴딩 도구
    ├── setup-docker-compose.completion         # Bash 자동완성 스크립트
    └── README.md                               # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 예시 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./dkcontls/dkcontls --target local
../utils/scriptctl/scriptctl install --script ./dknetcli/dknetcli --target local
../utils/scriptctl/scriptctl install --script ./setup-compose-service/setup-compose-service --target local

# 시스템 전역 설치 예시 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./dkcontls/dkcontls --target global
../utils/scriptctl/scriptctl install --script ./dknetcli/dknetcli --target global
```
