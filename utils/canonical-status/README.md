# canonical-status

지정된 디렉토리(기본값: 현재 디렉토리)를 기준으로 하위 1단계(`depth=1`) 및 2단계(`depth=2`) 디렉토리 내 `README.md` 파일의 존재 여부를 검사하여, 저장소 내 카테고리별 Canonical 정규화 작업의 진행 상태(`✅ 작업 완료`, `🚧 작업 중`, `❌ 작업 필요`)를 트리 구조로 한눈에 시각화하는 CLI 모니터링 도구입니다.

---

## ✨ 주요 특징

- **2단계 깊이(`depth=1`, `depth=2`) 기반 자동 판별**:
  - **✅ 작업 완료**: 1단계 하위 디렉토리(`subdir_l1`)에 `README.md` 파일이 존재하는 경우
  - **🚧 작업 중**: 1단계 하위 디렉토리(`subdir_l1`)에는 `README.md`가 없으나, 그 하위(`subdir_l2`) 중 하나 이상에 `README.md`가 존재하는 경우
  - **❌ 작업 필요**: 1단계(`subdir_l1`)와 2단계(`subdir_l2`) 모두 `README.md`가 존재하지 않는 경우
- **깔끔한 트리 시각화 및 동적 열 정렬**: 디렉토리 이름의 최대 길이를 자동으로 계산하여 트리 분기 기호(`├──`, `└──`)와 상태 표시 콜론(`:`)을 일렬로 정교하게 정렬합니다.
- **유연한 다중 디렉토리 및 와일드카드 패턴 제외(`--exclude-dir`, `--exclude-dir-pattern`)**:
  - 숨김 디렉토리(`.*`)와 스니펫 보관 디렉토리(`__.snippets`)를 기본 제외합니다.
  - `--exclude-dir`: 정확한 디렉토리 이름으로 다중 제외 (공백 구분 연속 지정, 콤마 구분, 옵션 반복 지정 지원)
  - `--exclude-dir-pattern`: 와일드카드(`abc*`, `*abc`, `*abc*`) 방식으로 다중 제외 (공백 구분 연속 지정, 콤마 구분, 옵션 반복 지정 지원)
- **지능형 다중 인자 Bash 자동완성**: `--exclude-dir` 및 `--exclude-dir-pattern` 입력 시 이미 선택된 디렉토리나 이미 와일드카드 패턴에 매칭된 디렉토리는 후보에서 자동으로 제외하고 남은 하위 디렉토리만 연속해서 추천합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--target-dir <디렉토리>` | 선택 | `.` (현재 디렉토리) | Canonical 작업 상태를 검사할 기준 디렉토리 경로 |
| `--exclude-dir <디렉토리명...>` | 선택 | `__.snippets`, `.*` | 탐색에서 추가로 제외할 하위 디렉토리 이름 (공백 구분 다중 인자, 콤마 구분, 옵션 반복 지정 모두 지원) |
| `--exclude-dir-pattern <패턴...>` | 선택 | - | 와일드카드(`abc*`, `*abc`, `*abc*`) 패턴으로 제외할 하위 디렉토리 지정 (공백 구분 다중 인자, 콤마 구분, 옵션 반복 지정 모두 지원) |
| `--help` | 선택 | - | 도움말 및 사용법 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 현재 디렉토리 기준 Canonical 작업 현황 조회
```bash
canonical-status
```

### 2. 특정 저장소 디렉토리를 지정하여 조회
```bash
canonical-status --target-dir ~/dev/bashshell-projects/github/shellscripts
```

**출력 예시:**
```text
[directory] ~/dev/bashshell-projects/github/shellscripts
├── ai-agent    : ✅ 작업 완료
├── antigravity : 🚧 작업 중
└── zip         : ❌ 작업 필요
```

### 3. 여러 하위 디렉토리를 이름으로 제외하고 조회 (`--exclude-dir`)
```bash
# 공백으로 여러 디렉토리 연속 지정 (Tab 자동완성 연속 지원)
canonical-status --target-dir ~/dev/bashshell-projects/github/shellscripts --exclude-dir __.develop __.installation __.man

# 콤마(,) 구분 또는 옵션 반복 지정
canonical-status --target-dir ~/dev/bashshell-projects/github/shellscripts --exclude-dir __.develop,__.installation --exclude-dir __.man
```

### 4. 와일드카드 패턴으로 여러 디렉토리를 제외하고 조회 (`--exclude-dir-pattern`)
```bash
# '__'로 시작하는(abc*) 디렉토리, 'git'이 포함된(*abc*) 디렉토리, 'sh'로 끝나는(*abc) 디렉토리 다중 제외
canonical-status --target-dir ~/dev/bashshell-projects/github/shellscripts --exclude-dir-pattern '__*' '*git*' '*sh'

# 콤마(,) 구분 다중 패턴 및 --exclude-dir 혼합 사용
canonical-status --target-dir ~/dev/bashshell-projects/github/shellscripts --exclude-dir-pattern '__*,*git*' --exclude-dir zip
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../scriptctl/scriptctl install --script ./canonical-status --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../scriptctl/scriptctl install --script ./canonical-status --target global
```
