# Build & Deployment Shell Scripts

프로젝트 빌드 산출물(`deploy/`, `target/`) 일괄 정리 및 프로파일 기반 배포(`deploy.sh`) 연계 실행을 지원하는 표준 CLI 자동화 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`build/<tool>/<tool>`), 전용 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **clean-project** | [`clean-project/`](clean-project/clean-project) | `.git`/`.project` 탐색 후 빌드 결과물(`deploy/`, `target/`) 일괄 삭제 및 실시간 진행률 표시 | ✅ 지원 | [상세보기](clean-project/README.md) |
| **remove-deploy** | [`remove-deploy/`](remove-deploy/remove-deploy) | 프로젝트 내 배포 디렉토리(`deploy/`)만 선별적으로 정리하여 디스크 공간 확보 | ✅ 지원 | [상세보기](remove-deploy/README.md) |
| **deploy-profile** | [`deploy-profile/`](deploy-profile/deploy-profile) | `./deploy/<profile>` 경로 검증 후 `deploy.sh` 안전 실행 및 추가 인자 전달 | ✅ 지원 | [상세보기](deploy-profile/README.md) |

---

## 📂 디렉토리 구조

```text
build/
├── README.md                           # Build 도구 종합 안내 (본 문서)
├── clean-project/
│   ├── clean-project                  # 빌드 산출물(deploy, target) 일괄 정리 도구
│   ├── clean-project.completion       # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
├── deploy-profile/
│   ├── deploy-profile                 # 프로파일 기반 배포 스크립트 실행 도구
│   ├── deploy-profile.completion      # Bash 자동완성 스크립트
│   └── README.md                      # 개별 도구 상세 설명서
└── remove-deploy/
    ├── remove-deploy                  # 배포 디렉토리(deploy) 선별 정리 도구
    ├── remove-deploy.completion       # Bash 자동완성 스크립트
    └── README.md                      # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 예 1: clean-project 설치 (개인 환경: ~/bin)
../../utils/scriptctl/scriptctl install --script ./clean-project/clean-project --target local

# 예 2: remove-deploy 설치
../../utils/scriptctl/scriptctl install --script ./remove-deploy/remove-deploy --target local

# 예 3: deploy-profile 설치
../../utils/scriptctl/scriptctl install --script ./deploy-profile/deploy-profile --target local
```
