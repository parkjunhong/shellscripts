# deploy-profile

프로젝트의 `./deploy/<profile>` 경로를 기반으로 유효성을 검증하고, 해당 배포 프로파일 디렉토리 내에 위치한 `deploy.sh` 스크립트를 안전하게 호출하여 프로파일 기반 배포를 수행하는 표준 배포 실행 도구입니다.

---

## ✨ 주요 특징

- **프로파일 유효성 자동 검증**: 입력된 프로파일에 해당하는 `./deploy/<profile>` 디렉토리 및 `./deploy/<profile>/deploy.sh` 실행 권한을 사전에 철저히 검증합니다.
- **배포 인자 투명 전달**: 프로파일 이름 뒤에 추가로 입력되는 모든 파라미터(`${@:2}`)를 타겟 `deploy.sh` 스크립트로 왜곡 없이 그대로 전달합니다.
- **안전한 디렉토리 복귀**: `pushd`/`popd` 매커니즘을 적용하여 배포 작업 완료 또는 실패 시에도 원래 터미널 작업 디렉토리로 안전하게 복귀합니다.
- **스마트 Bash 자동완성**: 현재 프로젝트의 `./deploy` 디렉토리 하위에 실제로 존재하는 프로파일 목록을 탐색하여 `<TAB>` 입력 시 동적으로 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `<프로파일_이름>` | **필수** | `./deploy` 디렉토리 하위에 위치한 배포 대상 프로파일 디렉토리명 (예: `local`, `dev`, `prod`) |
| `[추가_인자...]` | 선택 | 타겟 `deploy.sh` 스크립트에 전달할 추가 옵션 및 파라미터 |
| `-h, --help` | 선택 | 도구 사용법 및 도움말을 출력합니다. |

---

## 🚀 사용 예시

### 1. 기본 프로파일 배포 실행
```bash
deploy-profile dev
```

### 2. 타겟 deploy.sh로 추가 인자 전달 배포
```bash
deploy-profile prod --docker --build-only
```

---

## 💻 Bash 자동완성 설정

```bash
# 개인 계정 적용 (~/.bashrc)
source /path/to/shellscripts/build/deploy-profile/deploy-profile.completion

# 시스템 전역 적용
sudo cp /path/to/shellscripts/build/deploy-profile/deploy-profile.completion /etc/bash_completion.d/
```
