# 🏷️ git-tags

지정한 디렉토리 하위의 다중 Git 프로젝트들을 순회하며, 대상 브랜치(`-b/--branch`)가 존재하는 저장소에 **표준화된 규칙(`<prefix>-<type>-<YYYYMMDD>[-<suffix>]`)의 Annotated Tag를 일괄 생성하고 원격 저장소(`origin`)로 푸시**하는 CLI 도구입니다.

---

## ✨ 주요 특징

1. **표준화된 태그 네이밍 자동 조합**
   * `<접두사>-<태그유형>-<날짜(YYYYMMDD)>[-<접미사>]` 형식(예: `my-service-release-20261026-v1.0`)으로 태그 이름을 일관성 있게 생성합니다.
   * `-p/--prefix`를 생략하면 각 프로젝트의 디렉토리명을 자동으로 접두사로 사용합니다.
2. **기존 동일 태그 자동 갱신 및 원래 브랜치 복귀**
   * 동일한 이름의 태그가 이미 존재할 경우 로컬 및 원격(`origin`)에서 기존 태그를 삭제한 뒤 최신 커밋 기준으로 재생성 및 푸시합니다.
   * 작업 전 체크아웃되어 있던 브랜치와 대상 브랜치(`-b`)가 다를 경우, 태그 작업 완료 후 원래 브랜치로 자동 복귀합니다.

---

## ⚙️ 파라미터 명세

| 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `<directory>` | 선택 | Git 프로젝트들이 위치한 상위 디렉토리 경로 (기본값: `.`) |
| `--branch <branch>` | **필수** | 태그를 생성할 기준 브랜치 이름 |
| `--message <msg>` | 선택 | 태그 메시지 (미지정 시 대화형 입력 프롬프트 제공, 빈 값 입력 시 기본 타임스탬프 메시지 적용) |
| `--type <type>` | 선택 | 태그 유형 구분자 (기본값: `release`) |
| `--prefix <prefix>` | 선택 | 태그 이름 접두사 (기본값: 각 프로젝트 디렉토리 이름) |
| `--suffix <suffix>` | 선택 | 태그 이름 끝에 추가할 접미사 |
| `--help` | 선택 | 도움말 출력 |

---

## 🚀 사용 예시

```bash
# 1) 현재 경로 하위 모든 프로젝트의 'main' 브랜치에 '<프로젝트명>-release-YYYYMMDD' 태그 생성 및 푸시
./git-tags . --branch main --message "2026년 10월 정기 릴리즈"

# 2) 유형(hotfix) 및 접미사(v1.0.1)를 지정하여 일괄 태그 푸시
./git-tags ~/workspace --branch main --type hotfix --suffix v1.0.1 --message "긴급 패치 적용"
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./git-tags --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./git-tags --target global
```

