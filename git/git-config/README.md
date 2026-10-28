# 👤 git-config

현재 Git 저장소의 로컬 사용자 이름(`user.name`)과 이메일(`user.email`)을 간편하게 설정하는 CLI 유틸리티입니다.

---

## ✨ 주요 특징

1. **직관적인 단일 저장소 사용자 설정**
   * `git config user.name` 및 `git config user.email` 명령을 래핑하여, 이름과 이메일을 동시에 설정하거나 둘 중 하나만 선택적으로 변경할 수 있습니다.
2. **필수 인자 및 Git 환경 검증**
   * 옵션 값이 누락되었거나 아무 옵션도 전달되지 않은 경우 명확한 에러 메시지와 사용법을 안내합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--username <user.name>` | 선택* | 설정할 Git `user.name` (`--username` 또는 `--useremail` 중 최소 1개 필수) |
| `--useremail <user.email>` | 선택* | 설정할 Git `user.email` (`--username` 또는 `--useremail` 중 최소 1개 필수) |
| `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 저장소의 user.name과 user.email 동시 설정
./git-config --username "Junhong Park" --useremail "parkjunhong77@gmail.com"

# 2) 현재 저장소의 이메일만 변경
./git-config --useremail "parkjunhong77@gmail.com"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-config --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-config --target global
```

