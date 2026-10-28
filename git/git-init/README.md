# 🚀 git-init

기존 로컬 폴더를 지정한 브랜치로 Git 초기화(`git init -b`)하고 원격 저장소(`origin`)를 연결한 뒤, 원격 브랜치 존재 여부에 따라 **신규 브랜치 푸시 또는 원격 히스토리 병합(`--allow-unrelated-histories`) 후 푸시**까지 자동으로 수행하는 도구입니다.

---

## ✨ 주요 특징

1. **로컬 폴더의 원격 Git 저장소 연동 원클릭 자동화**
   * `git init -b <branch>` &rarr; `git remote add/set-url origin <repo>` &rarr; `git add .` &rarr; 초기 커밋(`최초 작성.`) 과정을 한 번에 처리합니다.
2. **원격 브랜치 유무 자동 감지 및 안전한 병합**
   * `git ls-remote --heads origin <branch>`를 통해 원격에 대상 브랜치가 없으면 즉시 `git push --set-upstream`을 수행합니다.
   * 원격에 이미 해당 브랜치가 존재하면 `git fetch` 후 `--allow-unrelated-histories` 옵션으로 자동 병합을 시도하며, 충돌 발생 시 충돌 파일 목록과 해결 절차를 친절하게 안내합니다.
3. **원격 URL 및 로컬 저장소 경로 검증**
   * HTTP(S)/SSH/Git 프로토콜 URL뿐만 아니라 로컬 베어(Bare) 저장소 경로 연결도 지원합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--repository <url\|path>` | **필수** | 연결할 원격 Git 저장소 URL 또는 로컬 경로 |
| `--branch <branch>` | 선택 | 초기화 및 연동할 브랜치 이름 (기본값: `master`) |
| `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 폴더를 'main' 브랜치로 초기화하고 원격 저장소에 푸시
./git-init --repository https://github.com/my-org/my-repo.git --branch main

# 2) 기본 브랜치(master)로 원격 저장소 연동
./git-init -r git@github.com:my-org/my-repo.git
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-init --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-init --target global
```

