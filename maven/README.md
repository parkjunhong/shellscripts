# Maven Shell Scripts & Automation Tools

Apache Maven 기반 프로젝트의 빌드, 일괄 배포, 아티팩트 저장소 마이그레이션 및 시스템 다중 Maven 버전 스위칭을 지원하는 표준 CLI 자동화 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`maven/<tool>/<tool>`)와 Bash 자동완성(`.completion`) 및 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **build-mvn-package** | [`build-mvn-package/`](build-mvn-package/build-mvn-package) | 사용자 정의 프로파일 기반 클린 빌드, 소스 최신화, 테스트 제어 및 자동 배포 연동 | ✅ 지원 | [상세보기](build-mvn-package/README.md) |
| **build-deploy-all** | [`build-deploy-all/`](build-deploy-all/build-deploy-all) | 하위 모든 Maven 프로젝트(`pom.xml`)를 감지하여 순차 일괄 빌드 및 배포 | ✅ 지원 | [상세보기](build-deploy-all/README.md) |
| **mvn-deploy** | [`mvn-deploy/`](mvn-deploy/mvn-deploy) | 표준 `mvn clean deploy` 기반 스냅샷 갱신, 테스트 생략, 설정/프로파일 및 Dry-run 지원 | ✅ 지원 | [상세보기](mvn-deploy/README.md) |
| **update-mvn-config** | [`update-mvn-config/`](update-mvn-config/update-mvn-config) | `/opt`에 설치된 다중 Maven 버전 대화형 선택 및 환경변수(`M2_HOME`, `PATH`) 즉시 갱신 | ✅ 지원 | [상세보기](update-mvn-config/README.md) |
| **upload-mvn-dependencies** | [`upload-mvn-dependencies/`](upload-mvn-dependencies/upload-mvn-dependencies) | 로컬 Maven 캐시의 아티팩트들을 원격 사설 저장소(Releases/Snapshots)로 일괄 업로드 | ✅ 지원 | [상세보기](upload-mvn-dependencies/README.md) |

---

## 📂 디렉토리 구조

```text
maven/
├── README.md                           # Maven 도구 종합 안내 (본 문서)
├── build-deploy-all/
│   ├── build-deploy-all               # 다중 프로젝트 일괄 빌드 오케스트레이션 도구
│   ├── build-deploy-all.completion    # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── build-mvn-package/
│   ├── build-mvn-package              # 단일 프로젝트 프로파일 빌드 및 배포 연동 도구
│   ├── build-mvn-package.completion   # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── mvn-deploy/
│   ├── mvn-deploy                     # Maven 원격 배포 헬퍼 CLI 도구
│   ├── mvn-deploy.completion          # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── update-mvn-config/
│   ├── update-mvn-config              # 시스템 Maven 버전 대화형 스위칭 도구
│   ├── update-mvn-config.completion   # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
└── upload-mvn-dependencies/
    ├── upload-mvn-dependencies        # 로컬 아티팩트 원격 저장소 일괄 업로드 도구
    ├── upload-mvn-dependencies.completion # Bash 자동완성 스크립트
    └── README.md                      # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 예 1: build-mvn-package 설치 (개인 환경: ~/bin)
../utils/scriptctl/scriptctl install --script ./build-mvn-package/build-mvn-package --target local

# 예 2: build-deploy-all 설치
../utils/scriptctl/scriptctl install --script ./build-deploy-all/build-deploy-all --target local

# 예 3: mvn-deploy 설치
../utils/scriptctl/scriptctl install --script ./mvn-deploy/mvn-deploy --target local

# 예 4: update-mvn-config 설치
../utils/scriptctl/scriptctl install --script ./update-mvn-config/update-mvn-config --target local

# 예 5: upload-mvn-dependencies 설치
../utils/scriptctl/scriptctl install --script ./upload-mvn-dependencies/upload-mvn-dependencies --target local
```
