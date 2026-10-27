# 🌿 git-branch-cmd

다수의 Git 작업 디렉토리를 순회하며 **브랜치 복제(Clone), 삭제(Delete), 검색(Find)** 등 일반 브랜치 작업은 물론, GitHub(`gh`) 및 GitLab(`glab`) API 모듈과 연동하여 **원격 보호 브랜치(Protected Branch) 및 기본 브랜치(Default Branch) 설정**까지 일괄 수행하는 통합 브랜치 제어 CLI 도구입니다.

---

## ✨ 주요 특징

1. **다중 Git 저장소 일괄 브랜치 제어 (일반 옵션)**
   * 지정한 하나 이상의 디렉토리 하위에 존재하는 모든 Git 저장소를 탐색하여 브랜치 복제(`--clone-branch <기존>:<신규>`), 삭제(`--delete-branch`), 존재 여부 검색(`--find-branch`)을 일괄 수행합니다.
2. **GitHub & GitLab API 기반 브랜치 보호 및 기본 브랜치 제어**
   * 각 저장소의 Remote URL 도메인을 분석하여 GitHub([`git-branch-module-github-api.sh`](../../github/git-branch-module-github-api.sh)) 또는 GitLab([`git-branch-module-gitlab-api.sh`](../../gitlab/git-branch-module-gitlab-api.sh)) API 모듈을 동적으로 로드합니다 (로컬에 모듈이 없으면 원격 저장소에서 자동 다운로드).
   * 보호 브랜치 설정(`--protect-branch`), 보호 해제(`--unprotect-branch`), 보호 브랜치 목록 조회(`--show-protected-branch`), 기본 브랜치 변경(`--set-default-branch`) 및 조회(`--show-default-branch`)를 지원합니다.
3. **도메인 및 소유자(개인/조직)별 지능형 PAT(Personal Access Token) 관리**
   * `PAT_GITHUB_COM_USER_<소유자>`, `PAT_GITHUB_COM_ORG_<조직명>`, `PAT_<도메인>` 등 환경변수를 자동 탐색하며, 미설정 시 실행 중 대화형 보안 프롬프트로 토큰을 입력받아 세션 내 재사용합니다.
4. **시뮬레이션 모드(`--dry-run`) 및 작업 결과 종합 리포트**
   * `--dry-run`을 통해 실제 변경 없이 실행될 명령을 사전 검증할 수 있으며, 작업 완료 후 성공/실패/검색 결과를 한눈에 볼 수 있는 요약 보고서를 출력합니다.

---

## ⚙️ 파라미터 명세

| 구분 | 옵션 | 설명 |
| :--- | :--- | :--- |
| **일반 옵션** | `--clone-branch <기존>:<신규>` | 기준 브랜치로부터 신규 브랜치를 생성하고 원격에 푸시 |
| **일반 옵션** | `--delete-source` | `--clone-branch` 완료 후 기준(원본) 브랜치를 삭제 |
| **일반 옵션** | `--delete-branch <브랜치명>` | 지정한 브랜치를 로컬 및 원격에서 삭제 (콤마 구분 다중 지정 가능) |
| **일반 옵션** | `--find-branch <브랜치명>` | 지정한 브랜치의 로컬/원격 존재 여부 검색 (콤마 구분 다중 지정 가능) |
| **API 옵션** | `--protect-branch <브랜치>` | 원격 저장소의 특정 브랜치를 보호 설정 (다중 지정 가능) |
| **API 옵션** | `--unprotect-branch <브랜치>` | 원격 저장소의 특정 브랜치 보호 설정 해제 (다중 지정 가능) |
| **API 옵션** | `--show-protected-branch` | 원격 저장소의 현재 보호된 브랜치 목록 조회 |
| **API 옵션** | `--set-default-branch <브랜치>` | 원격 저장소의 기본 브랜치(Default Branch) 변경 |
| **API 옵션** | `--show-default-branch` | 원격 저장소의 기본 브랜치 정보 조회 |
| **공통 옵션** | `--dry-run` | 실제 명령을 실행하지 않고 수행 예정 작업만 출력 |
| **공통 옵션** | `-h`, `--help` | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 경로 하위 모든 Git 저장소에서 'develop' 브랜치를 'release/1.0'으로 일괄 복제
./git-branch-cmd --clone-branch develop:release/1.0 .

# 2) 여러 디렉토리 하위 저장소에서 특정 브랜치 존재 여부 검색
./git-branch-cmd --find-branch feature/auth ~/workspace/backend ~/workspace/frontend

# 3) 원격 저장소의 기본 브랜치를 'main'으로 변경하고 'main' 브랜치를 보호 설정
./git-branch-cmd --set-default-branch main --protect-branch main ~/workspace/projects
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-branch-cmd --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-branch-cmd --target global
```

