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

## 🚀 빠른 시작 및 설치 안내

### 1. 개별 도구 설치 및 PATH 등록
사용할 스크립트를 `~/bin` 또는 `/usr/local/bin`에 복사하거나 심볼릭 링크를 생성합니다:
```bash
# 심볼릭 링크 예시
ln -s /path/to/shellscripts/build/clean-project/clean-project ~/bin/clean-project
chmod +x ~/bin/clean-project
```

또는 `scriptctl` 도구를 통해 손쉽게 설치할 수 있습니다:
```bash
scriptctl install build/clean-project
scriptctl install build/remove-deploy
scriptctl install build/deploy-profile
```

### 2. Bash 자동완성 일괄 활성화
모든 Build 도구의 자동완성을 로드하려면 `~/.bashrc` 파일에 아래 내용을 추가하세요:
```bash
# Build 도구 자동완성 로드
for completion in /path/to/shellscripts/build/*/*.completion; do
  [ -f "$completion" ] && source "$completion"
done
```
