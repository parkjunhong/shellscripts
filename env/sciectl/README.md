# sciectl

**`sciectl` (Script, Command, Installer & Environment Controller)**은 리눅스 패키지 매니저(`dnf`, `apt`)와 동일한 방식으로 목적별 환경 카탈로그(`@catalog`) 및 개별 컴포넌트(커스텀 CLI 도구, 인스톨러, 사후 명령어, Sudoers 권한, SSH 공개키)를 단일 트랜잭션 파이프라인으로 일괄 설치·관리하는 통합 프로비저닝 CLI 도구입니다.

---

## ✨ 주요 특징

- **패키지 매니저형 다중 카탈로그 트랜잭션 (`install`)**: 1개 이상의 카탈로그(예: `--catalog default-server,docker,network`)를 동시에 지정하면 상위 상속(`INCLUDES`)까지 자동으로 해석·병합·중복 제거한 뒤, 실행 전 **Transaction Summary(실행 계획 요약표)**를 출력하고 단 1회 확인으로 일괄 실행합니다.
- **선언형 카탈로그 및 논리 식별자 해석**: 전체 URL을 하드코딩하지 않고 `git/git-commit`, `temurin-25-jdk`, `ymtech-internal`과 같은 논리 식별자만으로 로컬 저장소(`--local`) 또는 원격 GitHub 저장소(`--remote`)에서 자원을 자동 탐색합니다.
- **엄격한 의존성 순서 보장 (8단계 파이프라인)**:
  1. `sudoers` (`/etc/sudoers.d/user-<계정>` 병합·정렬 및 `visudo -c` 사전 검증)
  2. `remove-packages` (불필요 OS 패키지 제거)
  3. `install-packages` (미설치 OS 패키지 일괄 설치 — 필요 시에만 패키지 인덱스 업데이트 1회 수행)
  4. `default-opts` (`~/bin` PATH 등록, Git 브랜치 프롬프트, `vim` 설치 후 `vimrc` 설정)
  5. `custom-installers` (`env/installers/` 소프트웨어 설치 스크립트 보안 검증 및 실행)
  6. `custom-tools` (커스텀 CLI 도구 + `.completion` 자동 설치 및 구버전 `.sh` 정리)
  7. `custom-commands` (`env/commands/` 시스템 사후 구성 명령어 실행)
  8. `ssh-key` (`~/.ssh/authorized_keys` Base64 본문 중복 검사 후 등록)
- **대화형(TUI) 및 무인 자동화(`--yes`) 하이브리드 지원**: 인자 없이 실행하면 동적 ASCII 테이블 기반 다중 카탈로그/단계 선택 메뉴를 제공하며, `--yes` 지정 시 모든 확인 프롬프트를 자동 승인하여 무인 프로비저닝을 수행합니다.

---

## ⚙️ 파라미터 명세

### 1. 서브커맨드 (Commands)

| 명령어 | 설명 |
| :--- | :--- |
| `install` | 카탈로그 또는 개별 컴포넌트(도구/인스톨러/커맨드/SSH키) 설치 (기본 명령어, 생략 가능) |
| `list` | 제공되는 카탈로그, 인스톨러, 사후 명령어, SSH 공개키 목록 조회 |
| `info` | 특정 카탈로그(상속 포함)에 정의된 모든 구성 요소 상세 내역 조회 |

### 2. 주요 옵션 (Long Option 전용)

| 서브커맨드 | 옵션 | 필수 여부 | 설명 |
| :--- | :--- | :---: | :--- |
| **`install`** | `--catalog <ID[,ID2...]>` | 선택 | 설치할 카탈로그 ID 지정 (복수 지정 또는 콤마 구분, 생략 시 대화형 선택) |
| | `--tool <CAT/NAME[,...]>` | 선택 | 특정 커스텀 CLI 도구 단독/추가 설치 (예: `git/git-commit`) |
| | `--installer <NAME[,...]>` | 선택 | 특정 인스톨러 단독/추가 실행 (예: `temurin-25-jdk,htop`) |
| | `--command <NAME[,...]>` | 선택 | 특정 사후 구성 명령어 단독/추가 실행 (예: `firewall-cmd-set-priority`) |
| | `--ssh-key <NAME[,...]>` | 선택 | 특정 SSH 공개키 단독/추가 등록 (예: `ymtech-internal,letsencrypt`) |
| | `--only <STEPS>` | 선택 | 지정한 단계만 선택 실행 (`sudoers`, `remove-packages`, `install-packages`, `default-opts`, `custom-installers`, `custom-tools`, `custom-commands`, `ssh-key`) |
| | `--skip <STEPS>` | 선택 | 지정한 단계를 제외하고 실행 (콤마 구분) |
| | `--user <USERNAME>` | 선택 | `sudoers` 등록 대상 사용자 계정 지정 (미지정 시 프롬프트 또는 `$USER`) |
| | `--target <local\|global>` | 선택 | 커스텀 도구 설치 범위 (`local`: `~/bin`, `global`: `/usr/local/bin`, 기본값: `local`) |
| | `--local` / `--remote` | 선택 | 로컬 저장소 파일 우선 사용 또는 원격 GitHub 저장소 강제 사용 |
| | `--yes` | 선택 | 모든 확인 프롬프트(`y/n`) 및 덮어쓰기 자동 승인 |
| | `--force` | 선택 | 기존 설치된 커스텀 도구/자동완성 파일 확인 없이 강제 업데이트 |
| | `--dry-run` | 선택 | 실제 설치 없이 병합된 트랜잭션 실행 계획(Transaction Summary)만 출력 |
| | `--all` | 선택 | 선택한 카탈로그의 모든 단계 및 기본 환경 3종 설정 적용 |
| | `--add-sudoers` | 선택 | `sudoers` 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--remove-packages` | 선택 | OS 패키지 삭제 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--install-packages` | 선택 | OS 패키지 설치 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--custom-tools` | 선택 | 커스텀 도구 설치 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--custom-installers` | 선택 | 커스텀 인스톨러 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--custom-commands` | 선택 | 사후 실행 명령어 단계만 실행 (`--no-default-opts` 자동 적용) |
| | `--no-default-opts` | 선택 | 기본 환경 3종(`~/bin` PATH, Git 프롬프트, `vimrc`) 설정 생략 |
| **`list`** | `--type <TYPE>` | 선택 | 조회 대상 유형 (`all`, `catalogs`, `installers`, `commands`, `keys`, 기본값: `catalogs`) |
| **`info`** | `--catalog <ID[,ID2...]>` | 필수 | 상세 내역을 조회할 카탈로그 ID (콤마 구분 복수 지정 가능) |
| **공통** | `--help` | 선택 | 전체 또는 서브커맨드별 상세 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1. 대화형(Interactive) 모드 실행 (다중 카탈로그 번호 및 단계 선택)
sciectl

# 2. 전체 카탈로그 및 인스톨러/커맨드/키 목록 조회
sciectl list --type all

# 3. 특정 카탈로그(상속 포함) 상세 구성 요소 확인
sciectl info --catalog default-devops

# 4. 다중 카탈로그 시뮬레이션(Dry-run) 및 무인 일괄 설치
sciectl install --catalog default-server,docker,network --dry-run
sciectl install --catalog default-server,docker,network --user parkjunhong --yes

# 5. 카탈로그 내 특정 단계만 선택 실행
sciectl install --catalog default-devops --only custom-tools,custom-installers

# 6. 카탈로그 없이 개별 인스톨러나 커스텀 도구만 단독 설치 (dnf/apt 스타일)
sciectl install --installer temurin-25-jdk,htop --tool git/git-commit,net/fwc-cli
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./sciectl --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./sciectl --target global
```
