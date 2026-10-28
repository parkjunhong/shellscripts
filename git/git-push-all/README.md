# 📤 git-push-all

지정한 디렉토리 하위에 위치한 **다수의 Git 프로젝트를 순회하며 일괄 커밋/푸시(`git add . && git commit && git push`) 및 브랜치 병합(`git-merge`)**을 수행하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **다중 프로젝트 일괄 Commit & Push (`-m`)**
   * `-m <message>` 지정 시 대상 하위 프로젝트들을 순회하며 `git add .` &rarr; `git commit -m` &rarr; `git push`를 일괄 수행합니다.
2. **다중 프로젝트 일괄 브랜치 병합 연동 (`-s`, `-t`)**
   * `-t <target>` (및 `-s <source>`) 지정 시 `git-merge` 도구를 호출하여 각 프로젝트의 브랜치 병합과 푸시를 연속으로 처리합니다.
3. **프로젝트 접두사 필터링 (`-p`)**
   * 특정 접두사로 시작하는 하위 프로젝트만 선택하여 실행할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--dir <directory>` | 선택 | Git 프로젝트들이 위치한 상위 디렉토리 경로 (기본값: 현재 디렉토리 `$PWD`) |
| `--message <message>` | 선택 | 일괄 커밋 및 푸시에 사용할 커밋 메시지 |
| `--projects <project ...>` | 선택 | 처리할 대상 프로젝트 이름(접두사) 목록 |
| `--source <source-branch>` | 선택 | 병합할 소스 브랜치 이름 (`--target`과 함께 사용) |
| `--target <target-branch>` | 선택 | 병합할 타겟 브랜치 이름 |
| `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 경로 하위 모든 프로젝트의 변경사항을 일괄 커밋 및 푸시
./git-push-all --message "chore: 공통 의존성 버전 업데이트"

# 2) 특정 접두사('service-') 프로젝트들을 커밋/푸시한 뒤 'main' 브랜치로 병합
./git-push-all --dir ~/workspace --projects service- --message "release: v1.2.0" --source develop --target main
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-push-all --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-push-all --target global
```

