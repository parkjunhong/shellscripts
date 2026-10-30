# AI-Agent Customization Shell Scripts

AI 에이전트(Antigravity, Claude Code, Cursor 등)에서 활용하는 스킬(`skill`) 및 규칙(`rule`) 디렉토리를 카테고리별로 생성·삭제하고, 외부 스킬/규칙을 심볼릭 링크로 참조 및 조회하는 표준 CLI 관리 도구 모음입니다.

모든 도구는 독립 실행형 Canonical 디렉토리 구조(`ai-agent/<tool>/<tool>`), 리눅스 표준 Bash 자동완성(`.completion`), 그리고 상세한 개별 `README.md`를 갖추고 있습니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | Canonical 경로 | 주요 기능 및 특징 | Bash 자동완성 | 개별 문서 |
| :--- | :--- | :--- | :---: | :---: |
| **acs-cli** | [`acs-cli/`](acs-cli/acs-cli) | AI-Agent 스킬(`SKILL.md`) 및 규칙(`${NAME}.md`) 생성(`create`), 삭제(`remove`), 심볼릭 링크 참조 추가(`add`), 목록 조회(`list`) | ✅ 지원 | [상세보기](acs-cli/README.md) |

---

## 📂 디렉토리 구조

```text
ai-agent/
├── README.md                           # AI-Agent 도구 종합 안내 (본 문서)
└── acs-cli/
    ├── acs-cli                         # AI-Agent Customization System CLI 도구
    ├── acs-cli.completion              # Bash 자동완성 스크립트
    ├── PURPOSE.md                      # acs-cli 도입 목적 및 독립 공간 관리 권고문
    └── README.md                       # 개별 도구 상세 설명서
```

---

## 🛠️ 공통 설치 안내

각 도구는 독립 실행형 CLI 도구로, 저장소의 `utils/scriptctl` 유틸리티를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로(`/usr/local/bin`)에 간편하게 설치할 수 있습니다. 스크립트 설치 시 연관된 Bash 자동완성 규칙이 시스템 표준 경로(`/usr/share/bash-completion/completions/`)에 자동으로 등록됩니다.

### `scriptctl` 도구를 사용한 설치

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./acs-cli/acs-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
# ※ 주의: scriptctl 자체의 권한 상승 차단을 위해 명령어 앞에 sudo를 붙이지 않습니다.
../utils/scriptctl/scriptctl install --script ./acs-cli/acs-cli --target global
```
