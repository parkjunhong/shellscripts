# 🦊 clone-gitlab-projects

원격 저장소에서 최신 [`gitlab-clone`](../gitlab-clone/gitlab-clone) 스크립트를 다운로드하여 로컬(`$HOME/bin/gitlab-clone`) 무결성을 자동으로 검증·업데이트한 뒤, 사전에 구성된 GitLab URL 및 Personal Access Token(PAT)을 주입하여 **특정 GitLab 그룹 하위의 전체 프로젝트를 일괄 복제(`git clone`)**하는 래퍼(Wrapper) CLI 도구입니다.

---

## ✨ 주요 특징

1. **`gitlab-clone` 자동 설치 및 무결성(최신 버전) 검증**
   * 실행 시 GitHub 원격 저장소의 최신 `gitlab-clone` 스크립트와 로컬에 설치된 `gitlab-clone`을 `cmp -s`로 비교합니다.
   * 로컬에 설치되어 있지 않거나 버전이 다르면 자동으로 `$HOME/bin/gitlab-clone`에 최신 버전을 설치·갱신한 뒤 실행합니다.
2. **사전 설정된 환경 변수(`GITLAB_URL` / `GITLAB_PAT`) 기반 간편 실행**
   * 매번 `--url <GitLab URL>`과 `--token <AccessToken>`을 수동으로 입력하지 않고, 환경 변수(`GITLAB_URL`, `GITLAB_PAT`)에 저장된 접속 정보를 활용하여 그룹 경로(`--group`)만으로 신속하게 일괄 복제할 수 있습니다.
   * 필수 환경 변수가 비어있을 경우 명확한 오류 진단 및 설정 가이드를 제공합니다.
3. **자동 디렉토리 생성 및 Bash Completion 지원**
   * 복제 대상 최상위 디렉토리(`--dir`)가 존재하지 않을 경우 중간 경로까지 자동 생성(`mkdir -p`)하며, `--dir` 입력 시 디렉토리 전용 탭(TAB) 자동완성을 제공합니다.

---

## 🔐 필수 환경 변수

스크립트 실행 전 다음 환경 변수가 반드시 설정되어 있어야 합니다:

| 환경 변수명 | 필수 여부 | 설명 | 예시 |
| :--- | :---: | :--- | :--- |
| `GITLAB_URL` | **필수** | 대상 GitLab 서비스 주소 | `https://gitlab.your-company.com` |
| `GITLAB_PAT` | **필수** | GitLab API 접근용 Personal Access Token | `glpat-xxxxxxxxxxxxxxxxxxxx` |

> [!TIP]
> **환경 변수 설정 방법:**
> ```bash
> # 1) 현재 쉘 세션에서 임시 설정 (권장)
> export GITLAB_URL="https://gitlab.your-company.com"
> export GITLAB_PAT="your-personal-access-token"
> 
> # 2) 쉘 환경 설정 파일에 영구 등록 (~/.bashrc)
> echo 'export GITLAB_URL="https://gitlab.your-company.com"' >> ~/.bashrc
> echo 'export GITLAB_PAT="your-personal-access-token"' >> ~/.bashrc
> source ~/.bashrc
> 
> # 3) 실행 시 인라인 지정
> GITLAB_URL="https://gitlab.your-company.com" GITLAB_PAT="your-token" ./clone-gitlab-projects --group my-security
> ```

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--group <group-path>` | **필수** | 복제할 GitLab 대상 그룹 경로 (예: `my-security`, `devops/backend`) |
| `--name <custom-name>` | 선택 | 클론 디렉토리의 최상위 그룹 폴더명을 대체할 사용자 정의 이름 |
| `--dir <target-dir>` | 선택 | 프로젝트를 복제할 대상 최상위 디렉토리 경로 (기본값: 현재 작업 디렉토리) |
| `--help` | 선택 | 도움말을 출력하고 종료합니다. |

---

## 🚀 사용 예시

```bash
# 1) 환경 변수 설정 후 대상 그룹 일괄 복제
export GITLAB_URL="https://gitlab.your-company.com"
export GITLAB_PAT="glpat-xxxxxxxxxxxxxxxxxxxx"

# 현재 디렉토리 하위에 'my-security' 그룹의 모든 프로젝트 및 하위 그룹 복제
./clone-gitlab-projects --group my-security

# 2) /home/dev/workspace 하위에 상위 폴더명을 'security-src'로 변경하여 복제
./clone-gitlab-projects --group my-security --name security-src --dir /home/dev/workspace
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./clone-gitlab-projects --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./clone-gitlab-projects --target global
```

