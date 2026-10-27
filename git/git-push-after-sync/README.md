# 🔄 git-push-after-sync

원본 디렉토리(`--source`)의 변경된 파일들을 Git 저장소인 대상 디렉토리(`--target`)로 안전하게 동기화(복사)한 뒤, **자동으로 `git add` &rarr; `git commit` &rarr; `git push`를 수행하고 실패 시 동기화 이전 상태로 자동 롤백**하는 도구입니다.

---

## ✨ 주요 특징

1. **변경 감지 기반 스마트 파일 동기화**
   * `diff -qr`로 두 디렉토리를 비교하여 변경 사항이 없으면 불필요한 복사를 건너뜁니다.
   * 임시 파일(`*.tmp`, `*.swp`, `*~`) 및 현재 다른 프로세스가 열어서 사용 중인 파일(`lsof`)은 건너뛰어 불완전한 파일이 커밋되는 것을 방지합니다.
2. **자동 Commit & Push 및 원자적 장애 롤백 (`rollback_git_state`)**
   * 동기화 전 대상 Git 저장소의 최신 커밋 해시(`HEAD`)를 기록해 두며, 커밋이나 원격 푸시(`git push`) 도중 네트워크 장애나 충돌이 발생하면 `git reset --hard` 및 `git clean -fd`를 통해 동기화 이전 상태로 깔끔하게 복구합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 단축 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :---: | :--- |
| `--source <dir>` | `-s` | **필수** | 변경 사항을 감지하고 복사해 올 원본 디렉토리 경로 |
| `--target <dir>` | `-t` | **필수** | 파일이 복사될 대상 Git 저장소 디렉토리 경로 |
| `--message <msg>` | `-m` | 선택 | 커밋 메시지 지정 (생략 시 타임스탬프 기반 자동 메시지 생성) |
| `--help` | `-h` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 원본 설정 폴더의 변경분을 Git 저장소 폴더로 동기화 후 커밋 & 푸시
./git-push-after-sync \
  --source /etc/myapp/conf \
  --target ~/git/myapp-config-backup \
  --message "chore: 운영 설정 변경분 동기화"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-push-after-sync --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-push-after-sync --target global
```

