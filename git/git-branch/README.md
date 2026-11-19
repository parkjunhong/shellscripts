# 🌿 git-branch

Git 저장소에서 로컬 및 원격(`origin`) 브랜치를 안전하고 간편하게 **일괄 삭제(`delete`)**하거나 신규 브랜치를 단일 **추가(`add`)**하는 브랜치 라이프사이클 관리 CLI 도구입니다.

개발 및 머지 완료 후 누적된 일회성 작업 브랜치(예: `develop-yyyyMMdd-{랜덤8자}`, `feature/*`)를 로컬과 원격에서 한 번의 명령으로 깔끔하게 정리할 수 있으며, 신규 브랜치 분기 시 원격 푸시 및 트래킹 설정까지 자동화합니다.

---

## ✨ 주요 특징

1. **로컬 및 원격 브랜치 동시 일괄 삭제 (`delete`)**
   * 브랜치명을 직접 지정(`--branch`)하거나 와일드카드 글롭 패턴(`--pattern`)을 지정하여 로컬과 원격의 브랜치를 한 번에 일괄 정리합니다.
   * `--scope` 옵션을 통해 로컬만(`local`), 원격만(`remote`), 또는 둘 다(`both`, 기본값) 삭제하도록 범위를 유연하게 지정할 수 있습니다.
2. **다중 안전 가드레일 (Safety Guardrails)**
   * **보호 브랜치 차단**: `main`, `master`, `develop`, `release`, `staging`, `production` 등 핵심 보호 브랜치는 `--force` 지정 여부와 무관하게 삭제가 원천 차단됩니다.
   * **현재 브랜치 자동 이동**: 현재 체크아웃 중인 브랜치(`HEAD`)가 삭제 대상에 포함된 경우, 저장소의 기본 브랜치(`develop` → `main` → `master` 우선순위)로 안전하게 자동 전환(`git switch`)한 후 로컬/원격 삭제를 완수하고 기본 브랜치에 머무릅니다.
   * **머지 상태 검증**: `--merged` 옵션을 통해 기준 타겟 브랜치(`develop`/`main`)에 머지 완료된 브랜치만 선별하여 안전하게 삭제(`git branch -d`)합니다. 미머지 브랜치 삭제는 `--force`(`git branch -D`) 명시 시에만 허용됩니다.
3. **단일 브랜치 안전 추가 및 원격 자동 푸시 (`add`)**
   * 의도치 않은 다중 생성을 방지하기 위해 단일 브랜치 1개만 생성을 허용합니다.
   * 기준 브랜치(`--from`)로부터 분기 생성 후 원격 저장소로의 즉시 푸시 및 업스트림 트래킹 설정을 자동화합니다.
4. **시뮬레이션 모드 (`--dry-run`) 및 사전 검증**
   * 실제 Git 삭제/생성 명령을 수행하기 전에 대상 브랜치 목록과 실행 계획을 미리 확인할 수 있습니다.
5. **표준 Long Option 체계**
   * 혼선을 방지하고 스크립트 작성 기본 규칙을 준수하여 정규 롱 옵션만 지원합니다.

---

## ⚙️ 파라미터 및 서브커맨드 명세

### 기본 문법
```bash
git-branch <서브커맨드> [옵션...]
git-branch delete [<브랜치명,...>] [--branch <브랜치명,...>] [--pattern <패턴>] [옵션...]
git-branch add --branch <브랜치명> [--from <기준브랜치>] [옵션...]
```

### 서브커맨드
| 서브커맨드 | 설명 |
| :--- | :--- |
| **`delete`** | 로컬 및 원격 브랜치를 직접 지정하거나 패턴/머지 조건에 따라 일괄 삭제합니다. |
| **`add`** | 신규 브랜치를 단일 생성하고 원격 저장소에 자동으로 푸시합니다. |

---

### `delete` 서브커맨드 옵션
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--branch <names>` | 조건부 필수 | - | 삭제할 브랜치명 직접 지정 (서브커맨드 뒤에 직접 브랜치명을 전달하거나 `--branch`로 전달 가능하며 콤마로 다중 지정 가능) |
| `--pattern <glob>` | 조건부 필수 | - | 글롭 와일드카드 패턴 매칭 삭제 (예: `develop-2026*`, `feature/*`) |
| `--merged` | 선택 | `false` | 기준 타겟 브랜치에 머지 완료된 브랜치만 필터링하여 삭제 |
| `--target <branch>` | 선택 | `develop` | 머지 여부 판정 기준 브랜치 (기본값: `develop`, 없을 시 `main`) |
| `--scope <scope>` | 선택 | `both` | 삭제 범위 지정 (`both`: 로컬+원격 동시, `local`: 로컬만, `remote`: 원격만) |
| `--remote <name>` | 선택 | `origin` | 원격 저장소 이름 (미지정 시 기본값 `origin`) |
| `--force` | 선택 | `false` | 머지되지 않은 브랜치 강제 삭제(`-D`) 및 확인 프롬프트 생략 |
| `--dry-run` | 선택 | `false` | 실제 삭제를 수행하지 않고 삭제 대상 브랜치 목록 및 실행 계획 시뮬레이션 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

> **참고**: 위치 인자(Positional argument), `--branch` 또는 `--pattern` 중 적어도 하나를 지정해야 합니다.

---

### `add` 서브커맨드 옵션
| 옵션 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--branch <name>` | **필수** | - | 신규 생성할 브랜치명 (단일 1개만 지정 가능) |
| `--from <branch>` | 선택 | 현재 브랜치 | 분기 기준 브랜치 |
| `--push` | 선택 | `true` | 생성 후 원격 저장소에 즉시 푸시 및 트래킹 설정 |
| `--no-push` | 선택 | `false` | 원격 푸시를 생략하고 로컬 브랜치만 생성 |
| `--remote <name>` | 선택 | `origin` | 원격 저장소 이름 |
| `--dry-run` | 선택 | `false` | 실제 생성/푸시 없이 실행 계획 시뮬레이션 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

```bash
# 1) 머지 완료된 특정 작업 브랜치를 로컬과 원격에서 동시 삭제
#    (현재 체크아웃된 브랜치일 경우 develop 또는 main으로 자동 전환 후 삭제)
git-branch delete --branch develop-20261119-c7NGVhK3

# 2) 서브커맨드 뒤에 직접 브랜치명을 전달하여 간편 삭제
git-branch delete develop-20261119-c7NGVhK3

# 3) 날짜 패턴에 일치하는 브랜치 일괄 삭제 사전 시뮬레이션 (Dry-run)
git-branch delete --pattern "develop-20261119-*" --dry-run

# 4) develop 브랜치에 머지 완료된 feature/* 브랜치만 일괄 정리
git-branch delete --pattern "feature/*" --merged --target develop

# 5) 미머지 브랜치를 포함하여 확인 프롬프트 없이 강제 삭제
git-branch delete --branch hotfix/temp-fix --force

# 6) develop 브랜치로부터 신규 feature 브랜치 생성 및 원격 자동 푸시
git-branch add --branch feature/user-profile --from develop
```

---

## 💻 설치 및 자동완성 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트와 `man` 매뉴얼 페이지도 시스템 표준 경로에 자동으로 등록됩니다.

### Bash Completion 주요 기능
- `git-branch delete <TAB>` 입력 시 사용 가능한 옵션 및 **로컬과 원격(`remotes/<remote>/` 제거) 브랜치의 고유 머지 목록**을 즉시 제안합니다.
- 명령줄에 `--remote <원격명>` 지정 시 해당 원격 저장소 기준 브랜치를 파싱합니다 (기본값: `origin`).
- `--branch` 뒤에서 콤마(`,`) 다중 입력 시 연속 브랜치 자동완성을 지원합니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 및 매뉴얼 등록)
../../utils/scriptctl/scriptctl install --script ./git-branch --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/, /usr/share/man/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../../utils/scriptctl/scriptctl install --script ./git-branch --target global
```
