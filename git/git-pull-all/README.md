# ⬇️ git-pull-all

지정한 디렉토리 하위에 위치한 **다수의 Git 프로젝트 디렉토리를 순회하며 `git pull`을 일괄 실행**하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **다중 Git 저장소 일괄 최신화 (`git pull`)**
   * 상위 디렉토리 아래의 모든 하위 폴더를 순회하며 `.git/config` 존재 여부를 확인하고, 유효한 Git 저장소인 경우 `git pull`을 수행합니다.
2. **특정 프로젝트 접두사 필터링 (`-p`)**
   * `-p <project ...>` 옵션을 통해 지정한 접두사로 시작하는 프로젝트만 선별하여 업데이트할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--dir <directory>` | `-d` | 선택 | Git 프로젝트들이 위치한 상위 디렉토리 경로 (기본값: 현재 디렉토리 `$PWD`) |
| `-p <project ...>` | `-p` | 선택 | 업데이트할 대상 프로젝트 이름(접두사) 목록 |
| `--level <depth>` | `-l` | 선택 | 프로젝트 탐색 깊이 지정 (기본값: `0`) |
| `--help` | `-h` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 디렉토리 하위 모든 Git 프로젝트 일괄 git pull
./git-pull-all

# 2) ~/workspace 하위에서 'yes-'로 시작하는 프로젝트들만 일괄 git pull
./git-pull-all -d ~/workspace -p yes-
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-pull-all --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-pull-all --target global
```

