# 🐙 GitHub 스크립트 및 모듈 (`shellscripts/github`)

GitHub REST API 연동을 위한 참조 모듈 스크립트를 관리하는 디렉토리입니다.

---

## 🧩 호출/참조형 모듈 스크립트 (`*.sh`)

다른 상위 스크립트에서 `source` 하거나 원격 로드하여 사용하는 모듈 스크립트입니다. 참조 경로 호환성을 위해 디렉토리 루트에 `.sh` 확장자를 유지한 채 배치됩니다.

### 1. [`git-branch-module-github-api.sh`](./git-branch-module-github-api.sh)

* **용도**: [`git/git-branch-cmd.sh`](../git/git-branch-cmd.sh) 등 브랜치 제어 스크립트에서 GitHub 저장소의 브랜치 보호(Branch Protection) 및 기본 브랜치(Default Branch) 설정을 제어할 때 호출하는 API 모듈입니다.
* **요구 사항**: 시스템에 GitHub 공식 CLI 도구인 `gh`가 설치 및 인증되어 있어야 합니다 (`X-GitHub-Api-Version: 2022-11-28` 기준).
* **주요 특징**:
  * **리포지토리 식별자 캐싱 (`_CACHED_GITHUB_REPO`)**: `gh repo view --json nameWithOwner` 호출 결과를 메모리에 캐싱하여 반복적인 API 호출 오버헤드를 줄입니다.
  * **사용자 친화적 오류 메시지 변환 (`_parse_github_error`)**: Fine-grained PAT 권한 부족(`403`), GitHub 무료 계정의 비공개 저장소 브랜치 보호 제한(`Upgrade to GitHub Pro`) 등의 API 응답을 직관적인 한국어 안내 메시지로 변환합니다.
  * **안전한 로딩 가드**: `source`로 로드될 때는 함수만 등록하고 제어권을 즉시 반환하며, 단독 실행 시에는 `-h`/`--help` 도움말만 안내하고 종료합니다.

#### 제공 함수 명세

| 함수명 | 파라미터 | 설명 |
| :--- | :--- | :--- |
| `api_github_protect_branch` | `$1`: 브랜치명 | 지정한 브랜치를 보호 브랜치로 설정 (`enforce_admins=true`, `allow_force_pushes=false`, `allow_deletions=false`) |
| `api_github_unprotect_branch` | `$1`: 브랜치명 | 지정한 브랜치의 보호 설정을 해제 (`Not Found` 응답 시 멱등성 보장) |
| `api_github_show_protected` | 없음 | 현재 저장소에 설정된 보호된 브랜치 이름 목록을 개행으로 구분하여 반환 |
| `api_github_set_default` | `$1`: 브랜치명 | 저장소의 기본 브랜치(`default_branch`)를 지정한 브랜치로 변경 |
| `api_github_show_default` | 없음 | 현재 저장소의 기본 브랜치(`default_branch`) 이름을 반환 |
| `_get_github_repo` | 없음 | 현재 Git 디렉토리의 `<owner>/<repo>` 식별자를 조회 및 캐싱하여 반환 (내부 헬퍼) |
| `_parse_github_error` | `$1`: API 원본 응답 | GitHub API 에러 JSON/메시지를 파싱하여 한 줄의 한국어/요약 에러 문자열로 반환 (내부 헬퍼) |
