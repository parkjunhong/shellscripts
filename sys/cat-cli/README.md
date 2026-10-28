# cat-cli

PATH 환경 변수에 등록된 명령어의 실제 실행 파일(바이너리 또는 쉘 스크립트) 경로를 찾아 내용을 화면(`cat`)에 즉시 출력하거나 전체 파일 경로를 조회하는 커맨드 소스 조회 도구입니다.

---

## ✨ 주요 특징

- **명령어 기반 즉시 열람**: 복잡한 절대 경로를 몰라도 명령어 이름만으로 실제 실행 파일 경로를 탐색하여 내용을 바로 출력합니다.
- **경로 확인 모드 (`--verbose`)**: 내용 출력 없이 해당 명령어의 실제 파일 절대 경로만 확인할 수 있습니다.
- **지능형 Bash 자동완성**: 시스템 PATH 상의 모든 실행 가능한 명령어(`compgen -c`) 및 전용 옵션을 자동으로 완성합니다.

---

## ⚙️ 파라미터 명세

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :---: | :--- |
| `<command>` | **필수** | - | 내용을 조회할 명령어 이름 |
| `--verbose` | 선택 | 비활성 | 파일 내용을 출력하지 않고 명령어의 절대 경로만 출력 |
| `--help` | 선택 | - | 도움말 메시지를 표시합니다. |

---

## 🚀 사용 예시

### 1. 쉘 스크립트 명령어 내용 조회
```bash
cat-cli scriptctl
```

### 2. 특정 명령어의 실제 경로만 확인
```bash
cat-cli --verbose git-commit
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록) 
../../utils/scriptctl/scriptctl install --script ./cat-cli --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록) 
../../utils/scriptctl/scriptctl install --script ./cat-cli --target global
```
