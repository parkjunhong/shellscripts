# 🛠️ acs-cli

AI-Agent Customization System에서 사용하는 **스킬(`skill`)**과 **규칙(`rule`)** 디렉토리를 카테고리별로 **생성(`create`)**, **삭제(`remove`)**, **외부 항목 심볼릭 링크 참조 추가(`add`)**, **현황 조회(`list`)**하는 통합 관리 CLI 도구입니다.

---

## ✨ 주요 특징

1. **카테고리 기반 AI-Agent 커스터마이징 표준 경로 관리**
   * 환경변수 `AI_AGENT_CUSTOMIZATION_HOME` (또는 `--home <경로>` 옵션) 하위에 카테고리별 `.agents` 탐색 구조를 자동으로 구성하고 관리합니다.
   * **Skill 경로 규격**: `${AI_AGENT_CUSTOMIZATION_HOME}/skills/${CATEGORY}/.agents/skills/${NAME}/SKILL.md`
   * **Rule 경로 규격**: `${AI_AGENT_CUSTOMIZATION_HOME}/rules/${CATEGORY}/.agents/rules/${NAME}.md`
2. **초기 마크다운 템플릿(Boilerplate) 자동 생성 (`create`)**
   * `create skill` 실행 시 AI 에이전트 탐색 엔진이 즉시 인식할 수 있는 YAML Frontmatter(`name`, `description`)가 포함된 `SKILL.md` 기본 템플릿을 생성합니다.
   * `create rule` 실행 시 규칙 정의용 마크다운 헤더가 포함된 `${NAME}.md` 파일을 생성합니다. (이름에 `.md`/`.MD` 확장자를 포함해 입력하더라도 자동으로 정규화합니다.)
3. **외부 스킬 및 규칙 심볼릭 링크 참조 (`add`)**
   * 이미 다른 경로에 존재하는 스킬 디렉토리(`--directory`)나 규칙 파일(`--file`)을 복제하지 않고 지정된 카테고리 하위에 **절대 경로 심볼릭 링크(Symbolic Link)**로 연결합니다.
   * 지정한 카테고리 디렉토리가 아직 존재하지 않더라도 자동으로 생성(`mkdir -p`)한 뒤 심볼릭 링크를 연결합니다.
4. **원본 보존형 안전 삭제 (`remove`)**
   * 삭제 대상이 `add`로 등록된 **심볼릭 링크**인 경우 원본 디렉토리/파일은 안전하게 보존하고 링크만 제거하며, `create`로 생성된 **실제 디렉토리/파일**인 경우 실제 데이터를 삭제합니다.
   * 삭제 전 대상 경로와 항목 유형(원본 vs 심볼릭 링크)을 안내하는 확인 프롬프트(`y/N`)를 제공하며, `--force` 옵션으로 즉시 삭제할 수도 있습니다.
5. **직관적인 상태 배지 및 참조 경로 조회 (`list`)**
   * 각 카테고리별 스킬/규칙 목록을 스캔하여 일반 항목(`[LOCAL]`), 심볼릭 링크 참조(`[LINK] -> 원본경로`), 깨진 심볼릭 링크(`[BROKEN-LINK]`) 상태를 한눈에 구분하여 출력합니다.
   * `--category` 및 `--name` 옵션을 선택적(Optional) 필터로 지원하여 전체 조회부터 특정 카테고리/이름 검색까지 유연하게 수행할 수 있습니다.
6. **문맥 인식 동적 Bash 자동완성 (`acs-cli.completion`)**
   * `AI_AGENT_CUSTOMIZATION_HOME`(또는 `--home` 인자) 하위를 실시간으로 탐색하여 `remove`, `list` 등 실행 시 존재하는 `--category`와 `--name` 목록을 탭(Tab)으로 자동 완성합니다.

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
| `--category <카테고리>` | **필수** | - | 삭제할 항목이 속한 카테고리 이름 |
| `--name <이름>` | **필수** | - | 삭제할 스킬 또는 규칙의 이름 |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 삭제 확인 프롬프트(`y/N`) 생략 및 즉시 삭제 |
| `--help` | 선택 | - | `remove` 서브커맨드 도움말 출력 |

### 3. `acs-cli add <skill|rule>`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | **필수** | - | 참조(심볼릭 링크)로 추가할 대상 종류 지정 |
| `--category <카테고리>` | **필수** | - | 심볼릭 링크를 추가할 대상 카테고리 이름 (미존재 시 자동 생성) |
| `--directory <경로>` | **조건부 필수** | - | `[skill 전용]` 참조할 외부 스킬 디렉토리 경로 |
| `--file <경로>` | **조건부 필수** | - | `[rule 전용]` 참조할 외부 규칙 마크다운 파일 경로 |
| `--name <별칭>` | 선택 | 원본 파일/폴더명 | 카테고리 내에 생성될 링크 이름을 원본과 다르게 지정할 때 사용 |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--force` | 선택 | `false` | 동일 이름의 항목이 이미 존재할 때 기존 항목을 교체 |
| `--help` | 선택 | - | `add` 서브커맨드 도움말 출력 |

### 4. `acs-cli list [skill|rule]`
| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `skill` \| `rule` | 선택 | 전체(`skill`+`rule`) | 조회할 커스터마이징 대상 종류 지정 (생략 시 모두 출력) |
| `--category <카테고리>` | 선택 | 전체 카테고리 | 특정 카테고리만 필터링하여 조회 |
| `--name <이름>` | 선택 | 전체 항목 | 특정 이름(또는 부분 문자열)과 일치하는 항목만 필터링하여 조회 |
| `--home <경로>` | 선택 | `$AI_AGENT_CUSTOMIZATION_HOME` | 커스터마이징 루트 디렉토리 경로 직접 지정 |
| `--help` | 선택 | - | `list` 서브커맨드 도움말 출력 |

---

## 🚀 사용 예시

### 1. 환경변수 설정 및 신규 스킬/규칙 생성 (`create`)
```bash
export AI_AGENT_CUSTOMIZATION_HOME="$HOME/dev/ai-agents"

# 'bash' 카테고리에 'bash-scripts' 스킬 생성
acs-cli create skill --category bash --name bash-scripts

# 'java' 카테고리에 'javadoc-spec' 규칙 생성
acs-cli create rule --category java --name javadoc-spec
```

### 2. 외부에 존재하는 스킬/규칙을 심볼릭 링크로 참조 추가 (`add`)
```bash
# 외부 스킬 디렉토리를 'devops' 카테고리에 심볼릭 링크로 추가
acs-cli add skill --category devops --directory /opt/shared-agents/skills/docker-deploy

# 외부 규칙 파일을 'java' 카테고리에 심볼릭 링크로 추가
acs-cli add rule --category java --file /opt/shared-agents/rules/nullmarked-policy.md
```

### 3. 등록된 스킬/규칙 및 참조 현황 조회 (`list`)
```bash
# 전체 스킬 및 규칙 현황 조회
acs-cli list

# 'bash' 카테고리의 스킬 목록만 조회
acs-cli list skill --category bash

# 이름에 'javadoc'이 포함된 규칙 조회
acs-cli list rule --name javadoc
```

### 4. 스킬 및 규칙 삭제 (`remove`)
```bash
# 확인 프롬프트(y/N)를 거쳐 스킬 삭제
acs-cli remove skill --category bash --name bash-scripts

# 확인 없이 규칙 즉시 삭제 (--force)
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
