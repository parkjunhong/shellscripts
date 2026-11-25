# 📜 git-log-abbr

현재 Git 저장소의 커밋 히스토리를 **축약 해시, 한 줄 요약 및 브랜치/태그 데코레이션(`git log --abbrev-commit --pretty=oneline --decorate`)** 형식으로 간결하게 출력하는 유틸리티입니다.

---

## ✨ 주요 특징

1. **간결한 한 줄 커밋 로그 및 브랜치 현황 출력**
   * 긴 옵션을 매번 입력할 필요 없이 `git-log-abbr` 실행만으로 커밋 해시(축약), 브랜치/태그 데코레이션(`--decorate`), 커밋 제목을 한 줄씩 깔끔하게 확인할 수 있습니다.
   * `watch` 등 파이프 환경에서도 브랜치 현황이 생략되지 않고 그대로 표시됩니다.
2. **파이프/모니터링 환경 색상 유지 (`--color`)**
   * `--color` 옵션을 지정하면 `--color=always`가 적용되어 `watch --color "git-log-abbr --color"` 실행 시에도 ANSI 색상 강조를 유지할 수 있습니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 설명 | 필수 여부 |
| :--- | :--- | :---: |
| `--color` | 파이프/`watch` 등 비대화형 출력에서도 ANSI 색상 강조(`--color=always`)를 유지합니다. | 선택 |
| `--help` | 스크립트 사용법 및 옵션 상세 정보를 출력합니다. | 선택 |

---

## 🚀 사용 예시

```bash
# 현재 Git 저장소의 한 줄 요약 로그 및 브랜치 현황 조회
git-log-abbr

# watch로 실시간 모니터링 (브랜치 현황 표시)
watch git-log-abbr

# watch로 실시간 모니터링 (브랜치 현황 + ANSI 색상 강조 유지)
watch --color "git-log-abbr --color"
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
