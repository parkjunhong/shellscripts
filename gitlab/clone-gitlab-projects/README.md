# 🦊 clone-gitlab-projects

원격 저장소에서 최신 [`gitlab-clone`](../gitlab-clone/gitlab-clone) 스크립트를 다운로드하여 로컬(`$HOME/bin/gitlab-clone`) 무결성을 자동으로 검증·업데이트한 뒤, 사전에 구성된 GitLab URL 및 Personal Access Token(PAT)을 주입하여 **특정 GitLab 그룹 하위의 전체 프로젝트를 일괄 복제(`git clone`)**하는 래퍼(Wrapper) CLI 도구입니다.

---

## ✨ 주요 특징

1. **`gitlab-clone` 자동 설치 및 무결성(최신 버전) 검증**
   * 실행 시 GitHub 원격 저장소의 최신 `gitlab-clone` 스크립트와 로컬에 설치된 `gitlab-clone`을 `cmp -s`로 비교합니다.
   * 로컬에 설치되어 있지 않거나 버전이 다르면 자동으로 `$HOME/bin/gitlab-clone`에 최신 버전을 설치·갱신한 뒤 실행합니다.
2. **사전 설정된 접속 정보(URL / Token) 기반 간편 실행**
   * 매번 `-u <GitLab URL>`과 `-t <AccessToken>`을 직접 입력하지 않고, 그룹 경로(`-g/--group`)만 지정하여 빠르게 그룹 전체 프로젝트를 복제할 수 있도록 설계된 템플릿형 실행 스크립트입니다.
3. **자동 디렉토리 생성 및 Bash Completion 지원**
   * 복제 대상 최상위 디렉토리(`-d/--dir`)가 존재하지 않을 경우 중간 경로까지 자동 생성(`mkdir -p`)하며, `-d/--dir` 입력 시 디렉토리 전용 탭(TAB) 자동완성을 제공합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--group <group-path>` | `-g` | **필수** | 복제할 GitLab 대상 그룹 경로 (예: `my-security`, `devops/backend`) |
| `--name <custom-name>` | `-n` | 선택 | 클론 디렉토리의 최상위 그룹 폴더명을 대체할 사용자 정의 이름 |
| `--dir <target-dir>` | `-d` | 선택 | 프로젝트를 복제할 대상 최상위 디렉토리 경로 (기본값: 현재 작업 디렉토리) |
| `--help` | `-h` | 선택 | 도움말을 출력하고 종료합니다. |

> **참고**: 스크립트 사용 전 [`clone-gitlab-projects`](./clone-gitlab-projects)의 `main()` 함수 내 `gitlab_url` 및 `gitlab_pat` 변수에 접속할 GitLab 서버 주소와 Personal Access Token을 설정해야 합니다.

---

## 🚀 사용 예시

```bash
# 1) 현재 디렉토리 하위에 'my-security' 그룹의 모든 프로젝트 및 하위 그룹 복제
./clone-gitlab-projects --group my-security

# 2) /home/dev/workspace 하위에 상위 폴더명을 'security-src'로 변경하여 복제
./clone-gitlab-projects --group my-security --name security-src --dir /home/dev/workspace
```
