# 📜 git-log-abbr

현재 Git 저장소의 커밋 히스토리를 **축약 해시 및 한 줄 요약 형식(`git log --abbrev-commit --pretty=oneline`)**으로 간결하게 출력하는 유틸리티입니다.

---

## ✨ 주요 특징

1. **간결한 한 줄 커밋 로그 출력**
   * 긴 옵션을 매번 입력할 필요 없이 `git-log-abbr` 실행만으로 커밋 해시(축약)와 커밋 제목을 한 줄씩 깔끔하게 확인할 수 있습니다.

---

## ⚙️ 파라미터 명세

별도의 옵션 없이 현재 Git 저장소 경로에서 바로 실행합니다.

---

## 🚀 사용 예시

```bash
# 현재 Git 저장소의 한 줄 요약 로그 조회
./git-log-abbr
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-log-abbr --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-log-abbr --target global
```

