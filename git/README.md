# 🐙 Git (Git Automation & Multi-Repository Management Scripts)

Git 저장소 초기화, 브랜치 제어(GitHub/GitLab API 연동), 커밋 및 태그 라이프사이클 관리, 그리고 **다수의 Git 프로젝트를 한 번에 일괄 제어(Status, Log, Pull, Push, Sync)하는 배치 자동화**를 지원하는 Git 유틸리티 CLI 도구 모음입니다.

---

## 📂 도구 목록 및 디렉토리 구조

모든 도구는 표준 **Canonical Directory** 구조로 배치되어 있으며, 각 디렉토리 내에 독립 실행 스크립트, Bash 자동 완성(`.completion`), 상세 `README.md`를 포함합니다.

```
shellscripts/git/
├── README.md                      # [현재 문서] Git 도구 모음 통합 색인 및 안내
├── git-branch-cmd/                # 다중 저장소 브랜치 제어 및 GitHub/GitLab API 연동
├── git-commit/                    # 커밋+푸시, 취소, 언스테이징, 롤백 통합 관리
├── git-config/                    # Git 로컬 사용자 이름 및 이메일 설정
├── git-getpr/                     # Sparse-Checkout 기반 특정 파일/폴더 부분 다운로드
├── git-init/                      # 로컬 저장소 초기화, 원격 연결 및 초기 푸시
├── git-log-abbr/                  # 커밋 히스토리 축약 해시 한 줄 요약 출력
├── git-log-all/                   # 다중 저장소 커밋 로그 일괄 조회
├── git-merge/                     # 브랜치 pull -> merge -> push -> 복귀 안전 자동화
├── git-modify/                    # 다중 저장소 원격 URL 및 사용자 정보 일괄 변경
├── git-pull-all/                  # 다중 저장소 git pull 일괄 최신화
├── git-push-after-sync/           # 파일 동기화 후 커밋/푸시 및 실패 시 자동 롤백
├── git-push-all/                  # 다중 저장소 일괄 커밋/푸시 및 브랜치 머지
├── git-status-all/                # 다중 저장소 작업 트리 상태 일괄 모니터링
└── git-tags/                      # 표준 명명 규칙 기반 태그 일괄 생성 및 푸시
```

---

## 🛠️ 기능별 도구 색인

### 1. 🌿 브랜치 및 저장소 라이프사이클 (Branch & Repository)
| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`git-init`** | 기존 폴더를 Git 초기화하고 원격 브랜치 연결 후 신규 또는 히스토리 병합 푸시 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-init/README.md) |
| **`git-branch-cmd`** | 다중 저장소 브랜치 복제·삭제·검색 및 GitHub(`gh`)/GitLab(`glab`) 보호 브랜치 설정 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-branch-cmd/README.md) |
| **`git-merge`** | 타겟 브랜치로 최신화(Pull) &rarr; 병합(Merge) &rarr; 반영(Push) &rarr; 복귀(Checkout) 자동화 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-merge/README.md) |
| **`git-getpr`** | 전체 복제 없이 Sparse-Checkout을 활용하여 특정 파일/디렉토리만 고속 다운로드 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-getpr/README.md) |

### 2. 📦 커밋, 태그 및 설정 관리 (Commit, Tag & Config)
| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`git-commit`** | 커밋+푸시(`push`), 커밋 취소(`cancel`), 언스테이징(`unstaged`), 롤백(`rollback`) 통합 관리 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-commit/README.md) |
| **`git-tags`** | 표준 명명 규칙(`<prefix>-<type>-<YYYYMMDD>`) 기반 Annotated Tag 일괄 생성 및 푸시 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-tags/README.md) |
| **`git-config`** | 현재 저장소의 로컬 사용자 이름(`user.name`)과 이메일(`user.email`) 설정 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-config/README.md) |
| **`git-modify`** | 다중 저장소 원격 URL(`remote.origin.url`) 및 사용자 정보(`userinfo`) 일괄 변경 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-modify/README.md) |

### 3. 🔄 다중 저장소 일괄 배치 작업 (Multi-Repo Batch Operations)
| 도구 이름 (Canonical Name) | 주요 역할 및 설명 | 바로가기 |
| :--- | :--- | :---: |
| **`git-status-all`** | 지정한 디렉토리 하위의 모든 Git 프로젝트 변경 상태(`git status`) 일괄 점검 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-status-all/README.md) |
| **`git-log-all`** | 지정한 디렉토리 하위의 모든 Git 프로젝트 커밋 히스토리(`git log`) 일괄 출력 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-log-all/README.md) |
| **`git-pull-all`** | 지정한 디렉토리 하위의 모든 Git 프로젝트 최신 변경사항(`git pull`) 일괄 동기화 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-pull-all/README.md) |
| **`git-push-all`** | 다중 Git 프로젝트를 순회하며 일괄 `add + commit + push` 및 브랜치 병합 수행 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-push-all/README.md) |
| **`git-push-after-sync`** | 원본 파일을 Git 저장소로 동기화 후 자동 커밋/푸시, 실패 시 원자적 자동 롤백 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-push-after-sync/README.md) |
| **`git-log-abbr`** | 현재 저장소의 커밋 로그를 축약 해시 기반 한 줄 요약(`--oneline`)으로 간결하게 출력 | [README](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/git/git-log-abbr/README.md) |

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 개인 실행 경로(`~/bin` 또는 `~/.local/bin`) 또는 전역 경로(`/usr/local/bin`)에 설치하여 바로 사용할 수 있습니다.

### `scriptctl` 도구를 사용한 간편 설치
저장소의 `utils/scriptctl` 유틸리티를 사용하면 스크립트와 Bash 자동 완성을 시스템에 한 번에 설치할 수 있습니다:

```bash
# 예 1: git-commit 설치 (개인 환경: ~/bin)
../../utils/scriptctl/scriptctl install --script ./git-commit/git-commit --target local

# 예 2: git-branch-cmd 설치
../../utils/scriptctl/scriptctl install --script ./git-branch-cmd/git-branch-cmd --target local

# 예 3: git-status-all 설치
../../utils/scriptctl/scriptctl install --script ./git-status-all/git-status-all --target local
```
