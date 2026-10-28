# 🛠️ acs-cli

AI-Agent Customization System에서 사용하는 **스킬(`skill`)**과 **규칙(`rule`)** 디렉토리를 카테고리별로 **생성(`create`)**, **삭제(`remove`)**, **심볼릭 링크 참조 추가(`add`)**, **트리 구조 조회(`list`)**하는 통합 관리 CLI 도구입니다.

---

## ✨ 주요 특징

1. **카테고리 기반 AI-Agent 커스터마이징 표준 경로 관리**
   * 환경변수 `AI_AGENT_CUSTOMIZATION_HOME` (또는 `--home <경로>` 옵션) 하위에 카테고리별 `.agents` 탐색 구조를 자동으로 구성하고 관리합니다.
   * **Skill 경로 규격**: `${AI_AGENT_CUSTOMIZATION_HOME}/skills/${CATEGORY}/.agents/skills/${NAME}/SKILL.md`
   * **Rule 경로 규격**: `${AI_AGENT_CUSTOMIZATION_HOME}/rules/${CATEGORY}/.agents/rules/${NAME}.md`
2. **일원화된 옵션 체계 (`--category`, `--name`) 및 초기 템플릿 자동 생성 (`create`)**
   * `create`, `remove`, `add`, `list` 모든 명령어가 `--category`와 `--name` 옵션 체계를 일관되게 사용합니다.
   * `create` 실행 시 에이전트가 즉시 인식할 수 있는 YAML Frontmatter(`name`, `description`)가 포함된 `SKILL.md` 및 규칙(`${NAME}.md`) 기본 마크다운 템플릿을 생성합니다.
3. **지능형 심볼릭 링크 참조 추가 (`add`)**
   * 이미 다른 카테고리에 존재하는 스킬 또는 규칙을 대상 카테고리(`--category`)에 **절대 경로 심볼릭 링크**로 추가합니다.
   * `acs-cli.completion` 연동 시 `--name <TAB>`을 누르면 `{category}/{name}` 형태로 후보를 추천하고, 단일 후보가 선택되는 순간 **전체 파일/디렉토리 경로**로 자동 치환됩니다.
4. **단일 항목 삭제 및 카테고리 전체 삭제 지원 (`remove`)**
   * `--category <cat> --name <name>` 지정 시 해당 스킬 또는 규칙만 삭제합니다. (심볼릭 링크인 경우 원본을 보존하고 링크만 제거)
   * `--category <cat>`만 지정(`--name` 생략) 시 **카테고리 자체를 삭제**하며, 하위에 스킬/규칙이 존재하면 목록을 먼저 제시합니다.
   * 모든 삭제 작업은 `[y/n]` 사용자 확인(`y`만 진행, `n` 또는 `Enter`는 취소)을 거치며, `--force` 지정 시 즉시 삭제합니다.
5. **순수 Bash 기반 `tree` 선(`├──`, `└──`) 스타일 계층 조회 (`list`)**
   * 외부 `tree` 패키지 의존성 없이 스킬 디렉토리 하위 파일 구조와 규칙 파일(`*.md`) 및 심볼릭 링크 참조 대상(`-> 원본경로`)을 `├──`, `└──`, `│` 트리 스타일로 시각화합니다.
   * `acs-cli list` 단독 실행 시 모든 `skill`과 `rule` 정보를 **`skill` → `rule` 순서**로 출력합니다.
6. **단계별(Step-by-Step) Bash 자동완성 (`acs-cli.completion`)**
   * `명령어` → `skill|rule` → `--category` → `{카테고리}` → `--name` → `{이름}` → `--force`(단, `list`는 제외) 순으로 문맥에 맞는 다음 파라미터만 순차적으로 제안합니다.
   * `--home` 옵션은 환경변수 `AI_AGENT_CUSTOMIZATION_HOME`이 설정되어 있지 않은 경우에만 자동으로 제안합니다.

---

## ⚙️ 파라미터 명세

### 1. `acs-cli create <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | **필수** | - | 생성할 커스터마이징 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 스킬 또는 규칙을 생성할 카테고리 이름 |
| `--name <이름>` | **필수** | - | 생성할 스킬 또는 규칙의 이름 (`.md` 확장자 생략 가능) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 동일 이름의 항목이 이미 존재할 때 확인 없이 덮어쓰기 |
| `--help` | 선택 | - | `create` 서브커맨드 도움말 출력 |

### 2. `acs-cli remove <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | **필수** | - | 삭제할 커스터마이징 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 삭제할 대상 카테고리 이름 |
| `--name <이름>` | 선택 | - | 삭제할 스킬/규칙 이름 (생략 시 해당 카테고리 자체를 삭제) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 삭제 확인 프롬프트(`[y/n]`) 생략 및 즉시 삭제 |
| `--help` | 선택 | - | `remove` 서브커맨드 도움말 출력 |

### 3. `acs-cli add <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | **필수** | - | 심볼릭 링크로 추가할 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 심볼릭 링크가 생성될 대상 카테고리 이름 |
| `--name <전체경로>` | **필수** | - | 참조할 원본 스킬 디렉토리 또는 규칙 파일의 전체 경로 (`<TAB>` 자동완성 시 `{category}/{name}` 추천 후 전체 경로로 자동 변환) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 동일 이름의 항목이 이미 존재할 때 기존 항목을 교체 |
| `--help` | 선택 | - | `add` 서브커맨드 도움말 출력 |

### 4. `acs-cli list [skill|rule]`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | 선택 | 전체(`skill`→`rule`) | 조회할 커스터마이징 대상 종류 지정 (생략 시 모두 출력) |
| `--category <카테고리>` | 선택 | 전체 카테고리 | 특정 카테고리만 필터링하여 트리 구조 출력 |
| `--name <이름>` | 선택 | 전체 항목 | 특정 스킬/규칙만 필터링하여 트리 구조 출력 (`--category`와 함께 사용) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--help` | 선택 | - | `list` 서브커맨드 도움말 출력 |

---

## 🚀 사용 예시

### 1. 신규 스킬 및 규칙 생성 (`create`)
```bash
export AI_AGENT_CUSTOMIZATION_HOME="$HOME/dev/ai-agents"

# 'bash' 카테고리에 'bash-scripts' 스킬 생성
acs-cli create skill --category bash --name bash-scripts

# 'java' 카테고리에 'javadoc-spec' 규칙 생성
acs-cli create rule --category java --name javadoc-spec
```

### 2. 기존 스킬/규칙을 다른 카테고리에 심볼릭 링크로 참조 추가 (`add`)
```bash
# <TAB> 입력 시 'bash/bash-scripts'로 추천되며, 선택 시 전체 경로로 치환됨
acs-cli add skill --category devops --name "${AI_AGENT_CUSTOMIZATION_HOME}/skills/bash/.agents/skills/bash-scripts"

# <TAB> 입력 시 'java/javadoc-spec'으로 추천되며, 선택 시 전체 파일 경로로 치환됨
acs-cli add rule --category spring --name "${AI_AGENT_CUSTOMIZATION_HOME}/rules/java/.agents/rules/javadoc-spec.md"
```

### 3. 트리(`├──`, `└──`) 구조로 스킬 및 규칙 조회 (`list`)
```bash
# 1) 특정 카테고리의 특정 스킬 하위 트리 조회
acs-cli list skill --category bash --name bash-scripts

# 2) 특정 카테고리의 모든 스킬 하위 트리 조회
acs-cli list skill --category bash

# 3) 모든 스킬 조회
acs-cli list skill

# 4) 모든 스킬과 규칙 전체 조회 (skill -> rule 순서)
acs-cli list
```

출력 예시:
```text
/home/parkjunhong/dev/ai-agents/skills/bash
└── bash-scripts
    ├── SKILL.md
    └── scripts/
        └── lint.sh
/home/parkjunhong/dev/ai-agents/skills/devops
└── bash-scripts -> /home/parkjunhong/dev/ai-agents/skills/bash/.agents/skills/bash-scripts
    ├── SKILL.md
    └── scripts/
        └── lint.sh
/home/parkjunhong/dev/ai-agents/rules/java
└── javadoc-spec.md
```

### 4. 개별 항목 또는 카테고리 전체 삭제 (`remove`)
```bash
# 1) 특정 스킬 삭제 ([y/n] 확인)
acs-cli remove skill --category bash --name bash-scripts

# 2) 카테고리 자체 삭제 (하위 스킬 목록 제시 후 [y/n] 확인)
acs-cli remove skill --category bash

# 3) 확인 프롬프트 없이 즉시 삭제 (--force)
acs-cli remove rule --category java --name javadoc-spec --force
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./acs-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./acs-cli --target global
```
