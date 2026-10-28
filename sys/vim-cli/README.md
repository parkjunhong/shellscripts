# vim-cli

PATH 환경 변수에 등록된 명령어의 실제 실행 파일(쉘 스크립트 등) 경로를 찾아 `vim`(또는 `vi`)으로 편집을 실행하며, 파일에 대한 일반 쓰기 권한이 없는 경우 자동으로 `sudo` 권한을 요청하여 편집을 진행하는 지능형 에디터 실행 도구입니다.

---

## ✨ 주요 특징

- **명령어 기반 에디터 즉시 실행**: 스크립트나 실행 파일의 복잡한 절대 경로를 입력할 필요 없이 명령어 이름만으로 에디터를 실행합니다.
- **쓰기 권한 자동 판별 및 권한 승격 (`sudo`)**:
  - 사용자에게 파일 쓰기 권한(`-w`)이 있는 경우 일반 `vim` 실행
  - 시스템 디렉토리 등 쓰기 권한이 없는 경우 안내 메시지와 함께 `sudo vim`으로 자동 전환 실행
- **경로 확인 모드 (`--verbose`)**: 에디터를 실행하지 않고 해당 명령어의 전체 절대 경로만 출력합니다.
- **엄격한 오류 제어**: `set -Eeuo pipefail` 및 ERR 트랩을 적용하여 안정성을 확보했습니다.
- **지능형 Bash 자동완성**: 시스템 PATH 상의 모든 실행 가능한 명령어(`compgen -c`) 및 전용 옵션을 자동으로 완성합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<command>` | **필수** | - | 편집할 명령어 이름 |
| `--verbose` | 선택 | 비활성 | 에디터를 실행하지 않고 대상 명령어의 절대 경로만 출력 |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 쉘 스크립트 명령어 편집
```bash
vim-cli scriptctl
```

### 2. 쓰기 권한이 없는 시스템 명령어 편집 (자동 sudo 전환)
```bash
vim-cli cat-cli
# 안내: ℹ️ '/usr/local/bin/cat-cli' 파일에 대한 쓰기 권한이 없어 'sudo' 권한으로 에디터를 실행합니다.
```

### 3. 명령어 전체 경로만 확인
```bash
vim-cli --verbose git-commit
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./vim-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./vim-cli --target global
```
