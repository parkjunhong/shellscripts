# 🛠️ git-modify

개별로 분리되어 있던 Git 저장소 설정 일괄 변경 스크립트(`git-modify-remote-url.sh`, `git-modify-userinfo.sh`)를 단일 인터페이스로 통합한 **Git 다중 저장소 설정 일괄 변경 CLI 유틸리티**입니다.

---

## ✨ 주요 특징

1. **2가지 핵심 서브커맨드 통합 (`remote-url`, `userinfo`)**
   * `remote-url`: 지정된 디렉토리 하위의 Git 저장소들을 탐색하여 원격 저장소(Remote) URL 내 특정 문자열(`--from`)을 새로운 문자열(`--to`)로 일괄 치환합니다.
   * `userinfo`: 지정된 디렉토리 하위의 Git 저장소들을 탐색하여 로컬 `user.name`(`--name`) 및 `user.email`(`--email`) 설정을 일괄 변경합니다.
2. **기존 스크립트 대비 주요 개선 사항**
   * **안전한 저장소 탐색 (`find -name ".git" -prune -print0`)**: `.git/objects` 등 내부 폴더까지 불필요하게 순회하던 성능 저하를 제거하고, 공백이 포함된 디렉토리 경로에서도 단어 분리(Word Splitting) 오류 없이 안전하게 동작합니다.
   * **직관적인 `--from` / `--to` 옵션 및 선택적 `--prefix`**: 기존 `git-modify-remote-url.sh`에서 강제되던 `-f <prefix>` 옵션을 선택 사항(`--prefix`)으로 개선하여 전체 저장소 일괄 변경과 접두사 필터링을 모두 지원합니다.
   * **개별 또는 동시 변경 지원 (`--name`, `--email`)**: 기존 `git-modify-userinfo.sh`에서는 이름과 이메일을 모두 입력해야 했으나, 이제 `--name`만 단독 변경하거나 `--email`만 단독 변경하는 것도 가능합니다.
   * **시뮬레이션 모드 (`--dry-run`)**: 실제 Git 설정을 변경하기 전에 어떤 저장소가 어떻게 변경될지 미리 확인할 수 있습니다.

---

## ⚙️ 서브커맨드 및 파라미터 명세

### 1. 공통 옵션

| 옵션 | 복수 지정 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--dir <path>` | **가능** | **필수** | Git 저장소들을 탐색할 기준 디렉토리 경로 |
| `--prefix <prefix>` | 불가 | 선택 | 하위 저장소 디렉토리명이 해당 접두사로 시작하는 경우에만 처리 |
| `--dry-run` | 불가 | 선택 | 실제 설정 변경 없이 변경 전/후 비교 내역만 시뮬레이션 출력 |
| `--verbose` | 불가 | 선택 | 변경 대상이 아닌(스킵된) 저장소까지 상세 로그 출력 |
| `--help` | 불가 | 선택 | 도움말 출력 |

### 2. `remote-url` 전용 옵션

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--from <old-string>` | **필수** | 기존 Remote URL에서 찾을 대상 문자열 |
| `--to <new-string>` | **필수** | 새로 변경할 대체 문자열 |
| `--remote <name>` | 선택 | 대상 리모트 이름 (기본값: `origin`) |

### 3. `userinfo` 전용 옵션

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--name <user.name>` | 선택* | 새로 설정할 Git `user.name` (`--name` 또는 `--email` 중 최소 1개 필수) |
| `--email <user.email>` | 선택* | 새로 설정할 Git `user.email` (`--name` 또는 `--email` 중 최소 1개 필수) |

---

## 🚀 사용 예시

```bash
# 1) [remote-url] 하위 모든 Git 저장소의 origin URL 도메인을 변경하기 전 Dry-Run 확인
./git-modify remote-url \
  --dir ~/dev/projects \
  --from "gitlab.old-domain.com" \
  --to "gitlab.new-domain.com" \
  --dry-run

# 2) [remote-url] 'yes-' 접두사로 시작하는 저장소들의 origin URL 일괄 변경
./git-modify remote-url \
  --dir ~/dev/projects \
  --prefix "yes-" \
  --from "http://192.168.0.10" \
  --to "https://git.company.co.kr"

# 3) [userinfo] 여러 작업 디렉토리 하위 Git 저장소들의 user.name과 user.email 일괄 변경
./git-modify userinfo \
  --dir ~/dev/work-a \
  --dir ~/dev/work-b \
  --name "Junhong Park" \
  --email "parkjunhong77@gmail.com"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-modify --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-modify --target global
```

