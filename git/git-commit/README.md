# 📦 git-commit

개별로 분리되어 있던 Git 커밋 및 리셋 스크립트(`git-commit-push`, `git-commit-push.bat`, `git-commit-cancel`, `git-commit-unstaged`, `git-commit-rollback`)를 단일 인터페이스로 통합한 **Git 커밋 & 리셋 관리 CLI 유틸리티**입니다.

---

## ✨ 주요 특징

1. **4가지 핵심 서브커맨드 통합 (`push`, `cancel`, `unstaged`, `rollback`)**
   * `push`: 대화형(제목 + 다중 줄 본문) 또는 `--message` 기반 커밋 및 원격 푸시 수행
   * `cancel`: 최근 커밋만 취소하고 스테이징 영역과 작업 디렉토리 변경 내용은 유지 (`git reset --soft`)
   * `unstaged`: 최근 커밋과 스테이징 영역을 초기화하고 작업 디렉토리 변경 내용은 유지 (`git reset --mixed`)
   * `rollback`: 최근 커밋, 스테이징 영역, 작업 디렉토리 변경 내용을 모두 초기화 (`git reset --hard`, 안전 확인 프롬프트 포함)
2. **지능형 Commit & Push 파이프라인 (`push`)**
   * 한글 파일명 깨짐 방지를 위해 `git config --local core.quotepath false`를 자동 적용합니다.
   * 스테이징된 변경 사항이 없으면(`[Skip]`) 오류로 중단하지 않고 커밋 단계를 건너뛴 뒤 바로 `git push`를 진행합니다.
   * 원격 저장소가 이미 최신 상태(`Everything up-to-date`)인 경우 `[Skip]` 안내 후 정상 종료합니다.
3. **유연한 리셋 범위 지정 (`--steps`, `--commit`) 및 동적 자동완성**
   * 기본 `HEAD~1`뿐만 아니라 `--steps <N>`(예: `HEAD~2`) 또는 `--commit <hash>`로 원하는 시점까지 리셋할 수 있습니다.
   * `--commit <TAB>` 입력 시 현재 Git 저장소의 최근 커밋 해시 목록(`git log -n 15`)을 동적으로 추천합니다.

---

## ⚙️ 서브커맨드 및 파라미터 명세

### 1. 서브커맨드

| 서브커맨드 | 대응 Git 명령 | 스테이징 영역(Index) | 작업 디렉토리(Working Tree) | 설명 |
| :--- | :--- | :---: | :---: | :--- |
| `push` | `git commit` + `git push` | 커밋 반영 | 유지 | 커밋 메시지 작성 후 커밋 및 푸시 수행 |
| `cancel` | `git reset --soft` | **유지** | **유지** | 커밋 이력만 취소 (다시 바로 커밋 가능한 상태) |
| `unstaged` | `git reset --mixed` | 초기화 | **유지** | 커밋과 스테이징을 취소하고 파일 변경 내역만 유지 |
| `rollback` | `git reset --hard` | 초기화 | **초기화 (복구 불가)** | 커밋, 스테이징, 파일 변경 내용을 모두 영구 삭제 |

### 2. 옵션 상세

| 옵션 | 대상 서브커맨드 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--message <msg>` | `push` | 선택 | 커밋 제목 메시지 직접 지정 (생략 시 제목/다중 줄 본문 대화형 입력) |
| `--add-all` | `push` | 선택 | 커밋 전 모든 변경 및 미추적 파일을 스테이징 (`git add -A`) |
| `--steps <N>` | `cancel`, `unstaged`, `rollback` | 선택 | 되돌릴 커밋 단계 수 지정 (기본값: `1` &rarr; `HEAD~1`, `--commit`과 동시 사용 불가) |
| `--commit <hash>` | `cancel`, `unstaged`, `rollback` | 선택 | 되돌릴 기준 커밋 해시 직접 지정 (`--steps`와 동시 사용 불가) |
| `--yes` | `push`, `rollback` | 선택 | 실행 전 사용자 확인 프롬프트(`y/N`) 생략 |
| `--help` | 공통 | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 모든 변경사항을 스테이징하고 대화형으로 제목/본문 입력 후 커밋 & 푸시
./git-commit push --add-all

# 2) 한 줄 커밋 메시지를 직접 지정하여 즉시 커밋 & 푸시
./git-commit push --add-all --message "feat: 사용자 인증 모듈 추가" --yes

# 3) 가장 최근 커밋(HEAD~1)만 취소하고 스테이징 상태 유지
./git-commit cancel

# 4) 최근 2개 커밋(HEAD~2)과 스테이징을 취소하되 수정한 소스 코드는 보존
./git-commit unstaged --steps 2

# 5) 특정 커밋 해시 시점으로 작업 디렉토리까지 완전 초기화 (확인 프롬프트 표시)
./git-commit rollback --commit a1b2c3d
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-commit --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-commit --target global
```

