# 📚 git-log-all

지정한 디렉토리 하위에 위치한 **다수의 Git 프로젝트 디렉토리를 순회하며 `git log`를 일괄 출력**하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **다중 프로젝트 커밋 로그 일괄 조회**
   * 기본적으로 각 프로젝트의 커밋 로그를 `--abbrev-commit --pretty=oneline` 한 줄 요약 포맷으로 출력하며, `-v` 옵션 지정 시 기본 상세 `git log` 포맷으로 출력합니다.
2. **특정 프로젝트 접두사 필터링 (`-p`)**
   * `-p <project ...>` 옵션을 지정하면 해당 이름으로 시작하는 하위 프로젝트 디렉토리만 선택적으로 조회할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `-d <directory>` | 선택 | Git 프로젝트들이 위치한 상위 디렉토리 경로 (기본값: 현재 디렉토리 `$PWD`) |
| `-p <project ...>` | 선택 | 조회할 대상 프로젝트 이름(접두사) 목록 (1개 이상 지정 가능) |
| `-v` | 선택 | 축약 포맷 대신 기본 상세 `git log` 포맷으로 출력 |
| `-h`, `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 디렉토리 하위 모든 프로젝트의 한 줄 커밋 로그 출력
./git-log-all

# 2) 특정 디렉토리에서 'core-'로 시작하는 프로젝트들의 상세 로그 출력
./git-log-all -d ~/workspace -p core- -v
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-log-all --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-log-all --target global
```

