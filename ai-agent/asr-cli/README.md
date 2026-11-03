# 🛠️ asr-cli

AI-Agent Customization System에서 사용하는 **다중 AI 에이전트(`antigravity`/`agy`, `claude`, `codex`)** 전용 **스킬(`skill`)**과 **규칙(`rule`)** 디렉토리를 카테고리별로 **생성(`create`)**, **삭제(`remove`)**, **심볼릭 링크 참조 추가(`add`)**, **편집(`edit`)**, **트리 구조 조회(`list`)**하는 통합 관리 CLI 도구입니다.

> 💡 **도입 배경 및 사용 권고**: 왜 개발 프로젝트 내부가 아닌 독립된 공간에서 스킬과 규칙을 관리해야 하는지에 대한 상세 내용은 [**`PURPOSE.md` (도입 목적 및 사용 권고)**](file:///home/parkjunhong/dev/bashshell-projects/github/shellscripts/ai-agent/asr-cli/PURPOSE.md) 문서를 참조하세요.

---

## ✨ 주요 특징

1. **다중 AI Agent(`--agent`) 전용 경로 및 규격 분리 관리**
   * `--agent <antigravity|agy|claude|codex>` 옵션을 통해 대상 AI 에이전트를 지정합니다. (`agy`는 `antigravity`의 약어입니다.)
   * **명령어별 `--agent` 동작**:
     * `create` / `remove` / `add` / `edit`: **`--agent` 필수 지정** (커맨드라인 최우선 순위 권장: `asr-cli --agent <AGENT> ...`). 기본값(`antigravity`)은 적용되지 않으므로 반드시 명시해야 합니다.
     * `list`: `--agent` 생략 시(`asr-cli list`) **존재하는 모든 에이전트(`antigravity`, `claude`, `codex`)**의 `skill`/`rule` 정보를 통합 조회하며, `--agent <agent>` 지정 시(`asr-cli --agent <agent> list`) 해당 에이전트의 정보만 필터링하여 조회합니다.
   * 환경변수 `AI_AGENT_CUSTOMIZATION_HOME` (또는 `--home <경로>` 옵션) 하위에 에이전트별 상위 폴더(`${AI_AGENT_CUSTOMIZATION_HOME}/{antigravity|claude|codex}/{skills,rules}/...`)를 독립적으로 분리하여 관리합니다.
   * 워크스페이스에 폴더를 추가했을 때 일반 개발 프로젝트 폴더와 명확히 구분되도록 실제 카테고리 디렉토리명에 `skill-` 및 `rule-` 접두사를 자동 부여합니다. (단, CLI `--category` 입력 및 자동완성 추천 시에는 `skill-`, `rule-`가 제외된 논리 카테고리 이름을 그대로 사용합니다.)
   * **에이전트별 생성 경로 규격**:
     * **`antigravity` (`agy`)**:
       * Skill: `${AI_AGENT_CUSTOMIZATION_HOME}/antigravity/skills/skill-${CATEGORY}/.agents/skills/${NAME}/{SKILL.md,scripts/,templates/,references/}`
       * Rule : `${AI_AGENT_CUSTOMIZATION_HOME}/antigravity/rules/rule-${CATEGORY}/.agents/rules/{${NAME}.md,${NAME}/{scripts/,templates/,references/}}`
     * **`claude` (Claude Code)**:
       * Skill: `${AI_AGENT_CUSTOMIZATION_HOME}/claude/skills/skill-${CATEGORY}/.claude/skills/${NAME}/{SKILL.md,references/,scripts/,assets/}`
       * Rule : `${AI_AGENT_CUSTOMIZATION_HOME}/claude/rules/rule-${CATEGORY}/.claude/rules/{${NAME}.md,${NAME}/{references/,scripts/,assets/}}`
     * **`codex` (OpenAI Codex)**:
       * Skill: `${AI_AGENT_CUSTOMIZATION_HOME}/codex/skills/skill-${CATEGORY}/.agents/skills/${NAME}/{SKILL.md,agents/openai.yaml,references/,scripts/,assets/}`
       * Rule : `${AI_AGENT_CUSTOMIZATION_HOME}/codex/rules/rule-${CATEGORY}/${NAME}/{AGENTS.md,references/,scripts/,assets/}`
2. **에이전트별 맞춤형 초기 템플릿 및 참조 리소스 디렉토리 자동 생성 (`create`)**
   * **`antigravity` (`agy`)**:
     * `SKILL.md`: 필수 속성(`name`, `description`)과 선택 속성(`# version`, `# author`, `# tags`)이 주석으로 안내된 Frontmatter, 6단계 표준 섹션 및 하위 참조 디렉토리(`scripts/`, `templates/`, `references/`)를 생성합니다.
     * `${NAME}.md`: Antigravity Rule 파서의 엄격한 스키마(Strict Schema)를 준수하여 `trigger: always_on`만 기본 활성화하고 선택 속성인 `# globs`만 주석으로 안내된 미니멀 Frontmatter, 4단계 표준 섹션 및 전용 참조 디렉토리(`.agents/rules/${NAME}/{scripts/,templates/,references/}`)를 생성합니다.
   * **`claude` (Claude Code)**:
     * `SKILL.md`: 필수 속성(`name`, `description`)과 Claude Code 전용 호출 제어 키(`# disable-model-invocation`, `# user-invocable`, `# allowed-tools`, `# context`, `# agent`, `# argument-hint`, `# model`)가 주석으로 안내된 Frontmatter, 7단계 표준 섹션(`Purpose`, `Preconditions`, `Inputs`, `Workflow`, `Safety`, `Failure handling`, `Output contract`) 및 하위 참조 디렉토리(`references/`, `scripts/`, `assets/`)를 생성합니다.
     * `${NAME}.md`: 경로 조건부 적용을 위한 `# paths:`가 주석 처리된 Frontmatter(`trigger:` 등 타 도구 전용 속성 배제), 4단계 표준 섹션 및 전용 참조 디렉토리(`.claude/rules/${NAME}/{references/,scripts/,assets/}`)를 생성합니다.
   * **`codex` (OpenAI Codex)**:
     * `SKILL.md`: 행위·대상·사용 시점·제외 조건(`Do not use for...`)을 명시한 `name`/`description` Frontmatter, 8단계 표준 섹션(`Purpose / When to use`, `Preconditions`, `Inputs`, `Procedure`, `References / Scripts`, `Validation`, `Outputs`, `Safety / Stop conditions`), 인터페이스 메타데이터 템플릿(`agents/openai.yaml`) 및 하위 참조 디렉토리(`agents/`, `references/`, `scripts/`, `assets/`)를 생성합니다.
     * `${NAME}/AGENTS.md`: Codex 표준에 맞춰 YAML Frontmatter를 배제한 순수 Markdown 기반 `AGENTS.md` 규칙 파일과 하위 참조 디렉토리(`references/`, `scripts/`, `assets/`)를 생성합니다.
   * **에이전트 내 전역 스킬 이름 중복 검증 (`create skill`)**: 동일 에이전트 내 서로 다른 카테고리에 같은 이름의 스킬이 중복 생성되지 않도록 디렉토리명 및 `SKILL.md` 내 `name:` 속성을 전수 검사하여 이미 사용 중인 이름이면 생성을 차단하고 종료합니다.
3. **지능형 내부/외부 심볼릭 링크 참조 추가 (`add`)**
   * **내부 참조 (`--name`)**: 선택된 에이전트(`--agent`) 내 다른 카테고리에 이미 존재하는 스킬 디렉토리 또는 규칙 파일을 대상 카테고리(`--category`)에 절대 경로 심볼릭 링크로 추가합니다. (Bash 자동완성 시 `{category}/{name}` 형태로 추천받아 전체 경로로 자동 치환)
   * **외부 참조 (상호 배타적)**: `${AI_AGENT_CUSTOMIZATION_HOME}` 외부 경로에 존재하는 독립 스킬/규칙도 심볼릭 링크로 참조 추가할 수 있습니다.
     * `--skill-dir <디렉토리>` : 외부 스킬 디렉토리 참조 (`SKILL.md` 필수, 스킬 전용)
     * `--rule-file <마크다운파일>` : 외부 규칙 마크다운 파일 참조 (`.md` 필수, `antigravity`/`claude` 규칙 전용)
     * `--rule-dir <디렉토리>` : 외부 Codex 규칙 디렉토리 참조 (`AGENTS.md` 필수, `codex` 규칙 전용)
4. **단일/다중 항목 삭제, 빈 카테고리 자동 정리 및 복수 카테고리 전체 삭제 지원 (`remove`)**
   * `--category` 및 `--name`에 콤마(`,`)로 구분된 다중 입력(`<입력>,<입력>`)을 지원합니다.
   * `--category <cat1,cat2>` 다중 지정 시 `--name` 입력은 허용하지 않으며, 지정된 복수 카테고리와 하위 목록을 각 라인별로 출력한 뒤 **1회 `[y/n]` 확인**으로 일괄 삭제합니다.
   * `--category <cat> --name <name1,name2>` 지정 시 해당 스킬/규칙들을 별도 라인으로 출력하고 **1회 `[y/n]` 확인**으로 일괄 삭제하며, 삭제 후 해당 카테고리에 더 이상 스킬이나 규칙이 남아 있지 않으면 **카테고리 디렉토리까지 자동으로 함께 삭제**합니다.
   * 모든 삭제 작업은 `[y/n]` 사용자 확인(`y`만 진행, `n` 또는 `Enter`는 취소)을 거치며, `--force` 지정 시 즉시 삭제합니다.
5. **`vim` 기반 스킬/규칙 파일 즉시 편집 및 미설치 시 자동 설치 지원 (`edit`)**
   * 하나의 AI 에이전트 내에서 스킬 이름은 고유하므로, **`--category` 없이 `--file <스킬명>`**만으로 대상 스킬(`SKILL.md`)을 즉시 찾아 `vim`으로 열어 편집할 수 있습니다. 규칙 파일 역시 `--file <규칙명>`으로 직접 편집 가능합니다.
   * 심볼릭 링크 파일인 경우 실제 원본 파일의 절대 경로(Canonical Path)를 해석하여 `vim`으로 열기 때문에, 심볼릭 링크가 깨지거나 분리되는 현상을 방지합니다.
   * 기존 방식인 `--category <카테고리> --name <이름>` 조합도 지원하며, `--file`과 `--category`/`--name`은 상호 배타적으로 검증됩니다.
   * 시스템에 `vim`이 설치되어 있지 않은 경우 OS 패키지 매니저(`brew`, `apt-get`, `dnf`, `yum`, `zypper`, `pacman`, `apk`)를 자동으로 감지하여 설치를 진행한 뒤 편집기를 실행합니다.
6. **순수 Bash 기반 `tree` 선(`├──`, `└──`) 스타일 계층 조회 및 태그 시각화 (`list`)**
   * **최상단 루트 헤더 출력**: 실행 시 `🏠 AI_AGENT_CUSTOMIZATION_HOME: <경로>` 및 구분선을 1회 표시하여 기준 경로를 안내합니다.
   * **상대 경로 및 스킬/규칙 전용 이모지 태그 표시**: 절대 경로 대신 가독성이 높은 상대 경로(`./${agent}/{skills|rules}/${category}`)로 표시하며, 복잡한 문자열과 에이전트 이모지를 배제하고 대상 종류(skill: `[🚀]`, rule: `[📜]`)만 직관적이고 미니멀하게 식별할 수 있는 전용 이모지 태그를 부여합니다.
   * **하위 트리 열(Column) 5칸 고정 정렬**: 모든 이모지 태그의 터미널 시각적 너비가 5칸으로 완벽히 통일되어, 하위 트리 라인(`└── `, `├── `)이 카테고리 경로(`./...`) 시작 위치에 오차 없이 일치합니다.
   * **빈 디렉토리 자동 제외**: 하위에 파일이나 디렉토리가 전혀 없거나, 비어 있는 하위 디렉토리만 존재하는 폴더는 출력에서 자동으로 제외하여 실제 유효한 리소스만 깔끔하게 표시합니다.
   * `asr-cli list` 단독 실행 시 존재하는 모든 에이전트(`antigravity`, `claude`, `codex`)의 `skill`과 `rule` 정보를 통합 출력하며, `--agent <agent>` 지정 시 특정 에이전트의 정보만 필터링하여 출력합니다.
   * `--category <cat1,cat2>` 또는 `--category <cat> --name <name1,name2>` 형태의 콤마(`,`) 다중 조회를 지원합니다.
7. **`--agent` 최우선 순위 및 엄격한 단계별(Step-by-Step) Bash 자동완성 (`asr-cli.completion`)**
   * **최초 후보 제한**: `asr-cli <TAB>` 시 `--agent`가 필수인 다른 서브커맨드는 노출하지 않고, **`--agent`, `--help`, `list`만 엄격히 제안**합니다. (에이전트가 지정된 `asr-cli --agent <AGENT> <TAB>` 상태에서 전체 서브커맨드 제안)
   * **`add` 서브커맨드 제안 최적화**:
     * `add skill <TAB>`: `--category`, `--skill-dir`, `--help` 제안
     * `add rule <TAB>` (`antigravity`/`claude`): `--category`, `--rule-file`, `--help` 제안
     * `add rule <TAB>` (`codex`): `--category`, `--rule-dir`, `--help` 제안
   * 내부 참조(`--name`)와 외부 참조(`--skill-dir`, `--rule-file`, `--rule-dir`) 간의 상호 배타성을 완벽히 반영하여 중복 입력을 사전에 방지합니다.

---

## ⚙️ 파라미터 명세

### 공통 옵션
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--agent <antigravity\|agy\|claude\|codex>` | **명령어별 상이** | `create`/`remove`/`add`/`edit`: **필수**<br>`list`: 선택 (생략 시 전체 에이전트) | 대상 AI Agent 지정 (`agy`는 `antigravity`의 약어, 최우선 위치 권장) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--help` | 선택 | - | 전체 도움말 또는 서브커맨드별 도움말 출력 |

### 1. `asr-cli --agent <AGENT> create <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--agent <AGENT>` | **필수** | - | 생성할 대상 AI Agent (`antigravity` \| `agy` \| `claude` \| `codex`) |
| `skill` \| `rule` | **필수** | - | 생성할 커스터마이징 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 스킬 또는 규칙을 생성할 논리 카테고리 이름 |
| `--name <이름>` | **필수** | - | 생성할 스킬 또는 규칙의 이름 (`.md` 확장자 생략 가능) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 동일 카테고리 내 동일 이름의 항목이 존재할 때 확인 없이 덮어쓰기 |
| `--help` | 선택 | - | `create` 서브커맨드 도움말 출력 |

### 2. `asr-cli --agent <AGENT> remove <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--agent <AGENT>` | **필수** | - | 삭제할 대상 AI Agent (`antigravity` \| `agy` \| `claude` \| `codex`) |
| `skill` \| `rule` | **필수** | - | 삭제할 커스터마이징 대상 종류 지정 |
| `--category <CAT[,CAT2,...]>` | **필수** | - | 삭제할 대상 카테고리 이름 (콤마 구분 다중 입력 지원) |
| `--name <NAME[,NAME2,...]>` | 선택 | - | 삭제할 스킬/규칙 이름 (단일 카테고리 지정 시 콤마 구분 다중 입력 지원, 다중 카테고리 지정 시 사용 불가) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 삭제 확인 프롬프트(`[y/n]`) 생략 및 즉시 삭제 |
| `--help` | 선택 | - | `remove` 서브커맨드 도움말 출력 |

### 3. `asr-cli --agent <AGENT> add <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--agent <AGENT>` | **필수** | - | 참조를 추가할 대상 AI Agent (`antigravity` \| `agy` \| `claude` \| `codex`) |
| `skill` \| `rule` | **필수** | - | 심볼릭 링크로 추가할 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 심볼릭 링크가 생성될 대상 카테고리 이름 |
| `--name <전체경로>` | 조건부 필수 | - | 내부 스킬 디렉토리 또는 규칙 파일/폴더 경로 (`{category}/{name}` 형식 지원, 외부 옵션과 상호 배타적) |
| `--skill-dir <DIR>` | 조건부 필수 | - | 외부 스킬 디렉토리 경로 (`SKILL.md` 필수, skill 전용) |
| `--rule-file <FILE>` | 조건부 필수 | - | 외부 마크다운 규칙 파일 경로 (`.md` 필수, antigravity/claude rule 전용) |
| `--rule-dir <DIR>` | 조건부 필수 | - | 외부 Codex 규칙 디렉토리 경로 (`AGENTS.md` 필수, codex rule 전용) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 동일 이름의 항목이 이미 존재할 때 기존 항목을 교체 |
| `--help` | 선택 | - | `add` 서브커맨드 도움말 출력 |

### 4. `asr-cli --agent <AGENT> edit <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `--agent <AGENT>` | **필수** | - | 편집할 대상 AI Agent (`antigravity` \| `agy` \| `claude` \| `codex`) |
| `skill` \| `rule` | **필수** | - | 편집할 커스터마이징 대상 종류 지정 |
| `--file <스킬명\|규칙명>` | 조건부 필수 | - | 대상 스킬/규칙 이름 직접 지정 (`--category`/`--name`과 상호 배타적) |
| `--category <카테고리>` | 조건부 필수 | - | 편집할 스킬/규칙이 속한 논리 카테고리 이름 (`--name` 필수) |
| `--name <이름>` | 조건부 필수 | - | 편집할 스킬/규칙 이름 (`--category` 필수) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--help` | 선택 | - | `edit` 서브커맨드 도움말 출력 |

### 5. `asr-cli list [skill|rule]`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | 선택 | 전체(`skill`→`rule`) | 조회할 커스터마이징 대상 종류 지정 (생략 시 모두 출력) |
| `--category <CAT[,CAT2,...]>` | 선택 | 전체 카테고리 | 특정 카테고리만 필터링하여 트리 구조 출력 (콤마 구분 다중 입력 지원) |
| `--name <NAME[,NAME2,...]>` | 선택 | 전체 항목 | 특정 스킬/규칙만 필터링하여 트리 구조 출력 (단일 카테고리 지정 시 콤마 구분 다중 입력 지원, 다중 카테고리 지정 시 사용 불가) |
| `--agent <AGENT>` | 선택 | 전체 에이전트 | 특정 AI Agent만 필터링하여 조회 (생략 시 존재하는 모든 에이전트 통합 조회) |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--help` | 선택 | - | `list` 서브커맨드 도움말 출력 |

---

## 🚀 사용 예시

### 1. 에이전트별 신규 스킬 및 규칙 생성 (`create`)
```bash
export AI_AGENT_CUSTOMIZATION_HOME="$HOME/dev/ai-agents"

# 1) Antigravity (--agent antigravity 또는 --agent agy)
asr-cli --agent antigravity create skill --category bash --name bash-scripts
asr-cli --agent agy         create rule  --category java --name javadoc-spec

# 2) Claude Code (--agent claude)
asr-cli --agent claude create skill --category java --name java-code-review
asr-cli --agent claude create rule  --category java --name spring-security

# 3) OpenAI Codex (--agent codex)
asr-cli --agent codex create skill --category java --name java-code-review
asr-cli --agent codex create rule  --category java --name backend-architecture
```

### 2. 스킬 및 규칙 심볼릭 링크 참조 추가 (`add`)
```bash
# 1) 내부 스킬 참조 (<TAB> 시 'bash/bash-scripts' 추천 후 전체 경로로 자동 치환)
asr-cli --agent antigravity add skill --category devops --name "${AI_AGENT_CUSTOMIZATION_HOME}/antigravity/skills/skill-bash/.agents/skills/bash-scripts"

# 2) 외부 스킬 디렉토리 참조 (--skill-dir)
asr-cli --agent antigravity add skill --category devops --skill-dir ~/my-external-skills/docker-builder

# 3) 외부 규칙 마크다운 파일 참조 (--rule-file, antigravity / claude)
asr-cli --agent antigravity add rule --category team-rules --rule-file ~/shared-docs/git-commit-convention.md

# 4) 외부 Codex 규칙 디렉토리 참조 (--rule-dir, codex)
asr-cli --agent codex add rule --category team-rules --rule-dir ~/shared-docs/codex-architecture-rules
```

### 3. 트리(`├──`, `└──`) 구조로 스킬 및 규칙 조회 (`list`)
```bash
# 1) 존재하는 모든 에이전트(antigravity, claude, codex)의 전체 skill/rule 통합 조회
asr-cli list

# 2) 특정 에이전트(claude)의 전체 skill/rule 조회
asr-cli --agent claude list
# 또는
asr-cli list --agent claude

# 3) 특정 에이전트(codex)의 규칙 카테고리 필터링 조회
asr-cli --agent codex list rule --category java
```

### 4. 개별/복수 항목 또는 카테고리 전체 삭제 (`remove`)
```bash
# 1) 단일 카테고리 내 복수 스킬 일괄 삭제 (별도 라인 출력 후 1회 [y/n] 확인)
asr-cli --agent antigravity remove skill --category bash --name bash-scripts,shell-linter

# 2) 복수 카테고리 전체 일괄 삭제 (하위 목록 제시 후 1회 [y/n] 확인)
asr-cli --agent claude remove skill --category java,devops

# 3) 확인 프롬프트 없이 즉시 삭제 (--force)
asr-cli --agent codex remove rule --category java --name backend-architecture --force
```

### 5. 스킬 및 규칙 파일 편집 (`edit`)
```bash
# 1) 스킬명 단독 지정으로 Antigravity 스킬 파일(SKILL.md) vim 편집 (--category 생략)
asr-cli --agent antigravity edit skill --file bash-scripts

# 2) Claude Code 규칙 파일(<name>.md) 단독 vim 편집 (--category 생략)
asr-cli --agent claude edit rule --file javadoc-guide

# 3) 기존 카테고리/이름 지정 방식으로 Antigravity 스킬 파일 vim 편집
asr-cli --agent antigravity edit skill --category bash --name bash-scripts

# 4) Codex 규칙 파일(AGENTS.md) vim 편집
asr-cli --agent codex edit rule --file backend-architecture
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./asr-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./asr-cli --target global
```
