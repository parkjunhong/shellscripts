# 📥 git-getpr

원격 Git 저장소 전체를 복제하지 않고 **Git Sparse-Checkout(`--filter=blob:none --no-checkout`)**을 활용하여, 원하는 **특정 디렉토리 또는 단일 파일만 빠르게 다운로드**하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **초경량 부분 다운로드 (Blobless Clone + Sparse-Checkout)**
   * 대용량 저장소에서 전체 히스토리나 불필요한 파일을 받지 않고, 지정한 리소스(`directory` 또는 `file`)만 선택적으로 체크아웃하여 지정 경로로 추출합니다.
2. **SHA-256 해시 비교 및 지능형 덮어쓰기/백업 프롬프트**
   * 대상 경로에 이미 동일한 파일/디렉토리가 존재하는 경우 SHA-256 해시를 비교하여 내용이 동일하면 건너뛰고, 다를 경우 **현재만 덮어쓰기(`y`), 전체 덮어쓰기(`f`), 현재만 백업 후 진행(`b`), 전체 백업 후 진행(`u`), 건너뛰기(`n`/`x`)** 대화형 선택지를 제공합니다.
3. **환경변수(`GIT_GETPR_GIT_URL`) 연동 및 순차적 Wizard 자동완성**
   * `GIT_GETPR_GIT_URL` 환경변수에 자주 사용하는 Git 서버 URL들을 콤마(`,`)로 등록해 두면 `-g` 생략 시 대화형 선택 메뉴를 제공하며, 탭(TAB) 입력 시에도 URL 및 원격 브랜치 목록(`git ls-remote`)을 동적으로 자동 완성합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--git-url <url>` | 선택* | Git 서비스 기본 URL (`https://...`, 미입력 시 `GIT_GETPR_GIT_URL` 환경변수 사용) |
| `--project <path>` | **필수** | Git 서비스 내 프로젝트 경로 (예: `parkjunhong/shellscripts`) |
| `--resource-type <type>` | **필수** | 다운로드할 리소스 유형 (`directory`/`d`: 디렉토리, `file`/`f`: 단일 파일) |
| `--resource <path>` | **필수** | 저장소 내 다운로드할 대상의 상대 경로 |
| `--branch <branch>` | 선택 | 대상 브랜치 이름 (기본값: `main`, 실패 시 `master` 자동 재시도) |
| `--output-path <path>` | 선택 | 로컬에 저장할 경로 (기본값: 현재 디렉토리 하위에 리소스의 마지막 이름) |
| `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 원격 저장소의 특정 디렉토리(net/sshctl)만 현재 경로로 다운로드
./git-getpr \
  --git-url https://github.com \
  --project parkjunhong/shellscripts \
  --resource-type directory \
  --resource net/sshctl

# 2) 특정 브랜치의 단일 파일만 지정 경로로 다운로드
./git-getpr \
  -g https://github.com \
  -p parkjunhong/shellscripts \
  -b main \
  -t file \
  -r env/setup-env.sh \
  -o ./setup-env.sh
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-getpr --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-getpr --target global
```

