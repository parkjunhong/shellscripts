# 📊 git-status-all

지정한 디렉토리 하위에 위치한 **다수의 Git 프로젝트 디렉토리를 순회하며 `git status`를 일괄 조회**하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **다중 프로젝트 상태 요약 조회**
   * 기본적으로 `git status --short --branch` 옵션을 사용하여 각 프로젝트의 현재 브랜치와 변경 파일 요약만 간결하게 출력합니다.
   * `-v` 옵션을 추가하면 표준 상세 `git status` 결과를 출력합니다.
2. **특정 프로젝트 접두사 필터링 (`-p`)**
   * `-p <project ...>` 옵션을 지정하여 원하는 프로젝트들만 선별 조회할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `-d <directory>` | 선택 | Git 프로젝트들이 위치한 상위 디렉토리 경로 (기본값: 현재 디렉토리 `$PWD`) |
| `-p <project ...>` | 선택 | 조회할 대상 프로젝트 이름(접두사) 목록 |
| `-v` | 선택 | 축약(`--short --branch`) 대신 상세 `git status` 메시지 출력 |
| `-h`, `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 디렉토리 하위 모든 Git 프로젝트의 브랜치 및 변경 상태 요약 조회
./git-status-all

# 2) ~/workspace 하위 'api-' 접두사 프로젝트들의 상세 상태 조회
./git-status-all -d ~/workspace -p api- -v
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-status-all --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-status-all --target global
```

