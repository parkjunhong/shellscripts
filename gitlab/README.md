# 🦊 GitLab 스크립트 및 모듈 (`shellscripts/gitlab`)

GitLab 프로젝트 일괄 복제 CLI 도구 및 GitLab API 연동 참조 모듈을 관리하는 디렉토리입니다.

---

## 🚀 독립 실행형 CLI 도구 (Canonical Directories)

| 도구명 | 경로 | 설명 |
| :--- | :--- | :--- |
| **[`gitlab-clone`](./gitlab-clone/README.md)** | [`gitlab/gitlab-clone/`](./gitlab-clone/) | GitLab REST API(v4)를 통해 대상 그룹 및 하위 서브그룹을 재귀 탐색하여 전체 프로젝트를 일괄 복제하는 핵심 CLI 도구 |
| **[`clone-gitlab-projects`](./clone-gitlab-projects/README.md)** | [`gitlab/clone-gitlab-projects/`](./clone-gitlab-projects/) | 원격 `gitlab-clone` 스크립트의 무결성 검증·자동 업데이트를 수행하고 사전 정의된 URL/PAT를 주입하여 실행하는 래퍼 도구 |

---

## 🧩 호출/참조형 모듈 스크립트 (`*.sh`)

다른 상위 스크립트에서 `source` 하거나 원격 로드하여 사용하는 모듈 스크립트입니다. 참조 경로 호환성을 위해 디렉토리 루트에 `.sh` 확장자를 유지한 채 배치됩니다.

### 1. [`git-branch-module-gitlab-api.sh`](./git-branch-module-gitlab-api.sh)

* **용도**: [`git/git-branch-cmd/git-branch-cmd`](../git/git-branch-cmd/git-branch-cmd) 등 브랜치 제어 스크립트에서 GitLab 저장소의 브랜치 보호(Protected Branch) 및 기본 브랜치(Default Branch) 설정을 제어할 때 호출하는 API 모듈입니다.
* **요구 사항**: 시스템에 GitLab 공식 CLI 도구인 `glab`이 설치 및 인증되어 있어야 합니다 (`jq` 없이 POSIX/표준 텍스트 처리만으로 동작).
* **제공 함수 명세**:

| 함수명 | 파라미터 | 설명 |
| :--- | :--- | :--- |
| `api_gitlab_protect_branch` | `$1`: 브랜치명 | 지정한 브랜치를 보호 브랜치로 설정 (`push_access_level=0`, `merge_access_level=40`, `allow_force_push=false`, 이미 보호된 `409` 응답 시 멱등성 보장) |
| `api_gitlab_unprotect_branch` | `$1`: 브랜치명 | 지정한 브랜치의 보호 설정을 해제 (`/` 포함 브랜치명 URL 인코딩 자동 처리, 미존재 `404` 응답 시 멱등성 보장) |
| `api_gitlab_show_protected` | 없음 | 현재 저장소에 설정된 보호된 브랜치 이름 목록을 개행으로 구분하여 반환 |
| `api_gitlab_set_default` | `$1`: 브랜치명 | 저장소의 기본 브랜치(`default_branch`)를 지정한 브랜치로 변경 |
| `api_gitlab_show_default` | 없음 | 현재 저장소의 기본 브랜치(`default_branch`) 이름을 반환 |
