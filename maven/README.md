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

## 🚀 빠른 시작 및 설치 안내

### 1. 개별 도구 설치 및 PATH 등록
사용할 스크립트를 `~/bin` 또는 `/usr/local/bin`에 복사하거나 심볼릭 링크를 생성합니다.
```bash
# 예시: build-mvn-package 등록
ln -s /path/to/shellscripts/maven/build-mvn-package/build-mvn-package ~/bin/build-mvn-package
chmod +x ~/bin/build-mvn-package
```

또는 `scriptctl` 도구를 통해 간편하게 설치할 수 있습니다:
```bash
scriptctl install maven/build-mvn-package
scriptctl install maven/build-deploy-all
scriptctl install maven/mvn-deploy
scriptctl install maven/update-mvn-config
scriptctl install maven/upload-mvn-dependencies
```

### 2. Bash 자동완성 일괄 활성화
모든 Maven 도구의 자동완성을 사용하려면 `~/.bashrc` 파일에 아래 내용을 추가하세요:
```bash
# Maven 도구 자동완성 로드
for completion in /path/to/shellscripts/maven/*/*.completion; do
  [ -f "$completion" ] && source "$completion"
done
```
