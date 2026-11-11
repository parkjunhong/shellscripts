# 🔀 git-mrq

원격 저장소 플랫폼(**GitHub**, **GitLab**, **기타 Git 서버**)을 자동으로 감지하여 최적의 CLI 도구(`gh`, `glab`, `git push -o`)로 **Merge Request(MR)** 또는 **Pull Request(PR)**를 생성하고 푸시하는 크로스 플랫폼 Git 자동화 CLI 도구입니다.

---

## ✨ 주요 특징

1. **원격 저장소 플랫폼 자동 감지 및 최적 CLI 분기**
   * **GitHub 저장소 (`*github.com*`)**: `github cli (gh)`를 사용하여 Pull Request 자동 생성
   * **GitLab 저장소 (`*gitlab*`)**: `gitlab cli (glab)`를 사용하여 Merge Request 자동 생성
   * **기타 Git 서버**: 순수 Git CLI의 Push Options (`git push -o merge_request.*`) 방식 사용
2. **누락된 공식 CLI 도구 자동 설치 및 인증(Token) 사전 점검**
   * 시스템에 `gh` 또는 `glab` 도구가 설치되어 있지 않은 경우, OS 패키지 관리자를 감지하여 자동 설치를 수행합니다 (Multi-OS 지원).
   * **사전 계정 인증 검사 및 사내 GitLab(Self-hosted) 대응**: 실제 원격 푸시를 진행하기 전 `gh auth status` 및 `glab auth status -h <host>`를 사전 검사하여 인증 누락으로 인한 실패를 방지합니다.
   * **GitLab 도메인 기반 고정 환경변수(`PAT_<DOMAIN>`) 자동 인증 지원**:
     * GitLab 호스트 미인증 시, 도메인 기반 고정 환경변수(예: `gitlab.ymtech.co.kr` &rarr; `PAT_GITLAB_YMTECH_CO_KR`, `gitlab.com` &rarr; `PAT_GITLAB_COM`)를 자동으로 탐색하여 `glab` 인증을 즉시 시도합니다.
     * 환경변수가 없거나 인증 실패 시, 대화형으로 1) `glab auth login` 수동 인증 진행, 또는 2) 별도 토큰 없이 즉시 MR을 생성하는 Git Push Options(`git push -o merge_request.*`) 방식으로 즉시 전환할 수 있습니다.
   * **환경변수 토큰 완벽 지원**: `GH_TOKEN` (GitHub), `GITLAB_TOKEN` 또는 도메인별 `PAT_<DOMAIN>` 환경변수가 설정되어 있으면 별도 브라우저 로그인 없이 즉시 인증됩니다.
3. **GitLab 소스 브랜치 보존 및 기본 삭제 체크 자동 방지**
   * GitLab 서버의 프로젝트 설정("Enable 'Delete source branch' option by default")이 켜져 있더라도, 사용자가 `--remove-source-branch` 옵션을 명시적으로 지정하지 않은 경우 생성 직후 REST API를 통해 **'Delete source branch' 체크를 자동으로 해제**하여 소스 브랜치가 의도치 않게 삭제되는 문제를 원천 차단합니다.
4. **단계별 대화형 (Step-by-Step) 입력 가이드**
   * 인자 없이 `git-mrq`만 실행할 경우 대화형 프롬프트로 진입하여 소스/타겟 브랜치, MR/PR 제목, 소스 브랜치 삭제 여부, 사전 검증 여부를 단계별로 안내받아 수행할 수 있습니다.
5. **시뮬레이션 모드 (`--dry-run`) 및 연속 실행 지원**
   * 실제 원격 푸시 및 생성을 수행하기 전에 플랫폼별 실행 계획을 미리 확인할 수 있으며, 대화형 모드에서는 검증 통과 후 재입력 없이 즉시 실제 생성으로 이어서 진행할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--source <branch>` | 선택 | 현재 브랜치 | Merge/Pull Request를 요청할 원본 소스 브랜치 |
| `--target <branch>` | 선택 | `develop` | 병합 대상 타겟 브랜치 |
| `--title <text>` | 선택 | 최근 커밋 메시지 | Merge/Pull Request 제목 |
| `--desc, --description <text>` | 선택 | - | 본문 설명 |
| `--remote <remote-name>` | 선택 | `origin` | 원격 저장소 이름 |
| `--remove-source-branch` | 선택 | `false` | 머지 완료 시 소스 브랜치 자동 삭제 (GitLab) |
| `--draft` | 선택 | `false` | Draft (WIP) 상태의 MR/PR 생성 |
| `--squash` | 선택 | `false` | 머지 시 커밋들을 단일 커밋으로 스쿼시 병합 (GitLab) |
| `--assignee <username>` | 선택 | - | 담당자(Assignee) 사용자명 지정 |
| `--milestone <name>` | 선택 | - | 마일스톤 이름 지정 |
| `--label <name>` | 선택 | - | 라벨 지정 (콤마 구분 또는 여러 번 지정 가능) |
| `--dry-run` | 선택 | `false` | 실제 푸시 없이 전송될 실행 명령만 시뮬레이션 |
| `--help` | 선택 | - | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 대화형(Step-by-Step) 모드로 실행 (인자 없이 실행)
./git-mrq

# 2) GitHub 저장소에서 PR 생성 (gh cli 자동 연동)
./git-mrq --source feature/user-auth --target main --title "feat: 사용자 인증 모듈 추가"

# 3) GitLab 저장소에서 MR 생성 (glab cli 자동 연동)
./git-mrq --source feature/payment --target develop --remove-source-branch --squash

# 4) Draft 상태의 PR/MR 생성 및 담당자/라벨 지정
./git-mrq --target develop --draft --assignee parkjunhong --label "backend,auth"

# 5) 사전 시뮬레이션 진단 (--dry-run)
./git-mrq --target main --dry-run
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-mrq --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-mrq --target global
```
