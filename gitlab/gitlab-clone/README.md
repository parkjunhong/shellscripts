# 🦊 gitlab-clone

GitLab REST API(v4)를 활용하여 **특정 GitLab 그룹 및 모든 하위 서브그룹(Subgroup)을 재귀적으로 탐색**하고, 그룹 계층 구조 그대로 로컬 디렉토리를 생성하여 **전체 프로젝트를 일괄 복제(`git clone`)**하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **그룹 및 서브그룹(Subgroup) 재귀 탐색 및 계층 구조 복원**
   * GitLab API(`/api/v4/groups/:id/projects`, `/api/v4/groups/:id/subgroups`)를 페이징(`per_page=100`)하며 모든 하위 그룹과 프로젝트를 누락 없이 순회합니다.
   * 원격 GitLab 그룹 계층 구조와 동일한 로컬 디렉토리 트리를 자동으로 생성하고 각 프로젝트를 `git clone` 합니다.
2. **사전 검증 및 중복 클론 방지 (Idempotency)**
   * 필수 의존성 도구(`curl`, `jq`, `git`) 설치 여부와 대상 GitLab 그룹의 실제 존재 및 접근 권한(HTTP 200 응답)을 사전에 검증합니다.
   * 로컬에 이미 동일한 프로젝트 디렉토리가 존재하는 경우 덮어쓰거나 오류를 발생시키지 않고 안전하게 건너뜁니다(`[Skip]`).
3. **유연한 폴더명 대체(`--name`) 및 특정 서브그룹 제외(`--exclude`)**
   * `--name` 옵션으로 최상위 루트 그룹 디렉토리 이름을 원하는 이름으로 변경할 수 있습니다.
   * `--exclude` 옵션에 제외할 서브그룹 이름을 콤마(`,`)로 나열하면 해당 서브그룹과 그 하위 프로젝트 전체를 탐색에서 제외합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--url <gitlab-url>` | `-u` | **필수** | GitLab 서비스 URL (예: `https://gitlab.example.com`) |
| `--group <group-path>` | `-g` | **필수** | 복제할 GitLab 대상 그룹 경로 (예: `my-group` 또는 `parent/child`) |
| `--token <pat>` | `-t` | **필수** | GitLab API 조회 및 저장소 복제용 Personal Access Token (`read_api`, `read_repository` 권한) |
| `--name <custom-name>` | `-n` | 선택 | 클론 디렉토리의 최상위 그룹 폴더명을 대체할 이름 |
| `--exclude <sub1,sub2>` | `-x` | 선택 | 복제에서 제외할 서브그룹(Subgroup) 이름 목록 (콤마(`,`)로 구분) |
| `--dir <target-dir>` | `-d` | 선택 | 프로젝트를 복제할 대상 최상위 디렉토리 (기본값: 현재 경로, 지정 시 해당 경로가 존재해야 함) |
| `--help` | `-h` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) 기본 사용: 특정 그룹 및 하위 서브그룹의 모든 프로젝트를 현재 경로에 복제
./gitlab-clone \
  --url https://gitlab.example.com \
  --group platform-team \
  --token glpat-xxxxxxxxxxxxxxxxxxxx

# 2) 최상위 폴더명을 'platform-src'로 지정하고, 'archive,legacy' 서브그룹은 제외하여 복제
./gitlab-clone \
  --url https://gitlab.example.com \
  --group platform-team \
  --token glpat-xxxxxxxxxxxxxxxxxxxx \
  --name platform-src \
  --exclude archive,legacy \
  --dir ~/workspace
```
