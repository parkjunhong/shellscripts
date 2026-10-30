# init-wrangler-d1

`init-wrangler-d1`은 Cloudflare D1 데이터베이스를 대상으로 SQL 스키마 파일을 로컬(`local`) 및 원격(`remote`) 환경에 안전하게 초기화/배포하거나, 원격 D1의 스키마와 데이터를 로컬 마이그레이션 백업 파일로 덤프 추출하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **로컬/원격/전체 일괄 배포 지원**:
  - `local`: 로컬 D1 에뮬레이션 DB에 스키마 파일 적용
  - `remote`: Cloudflare 원격 운영 D1 DB에 스키마 파일 배포
  - `all`: 로컬 및 원격 D1에 순차적으로 스키마 일괄 적용
- **원격 D1 데이터 백업/마이그레이션**:
  - `migration`: 원격 D1의 테이블 스키마와 데이터를 `.sql` 파일로 로컬 실행 디렉터리에 타임스탬프와 함께 자동 백업
- **대화형(Interactive) & 비대화형 실행**: 대상 환경(`--d1-location`)을 생략하면 대화형 메뉴를 통해 안전하게 선택할 수 있습니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--run-dir <디렉토리>` | **필수** | - | Wrangler 명령이 실행될 프로젝트 루트 디렉터리 |
| `--d1-schema <이름>` | **필수** | - | 대상 Cloudflare D1 데이터베이스 이름 (예: `my_db`) |
| `--d1-file <파일경로>` | 조건부 필수 | - | 적용할 SQL 스키마 파일 경로 (`migration` 모드 제외 필수) |
| `--d1-location <타입>` | 선택 | 대화형 선택 | 대상 환경 (`local`, `remote`, `all`, `migration`) |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 로컬 D1에 스키마 파일 적용
```bash
init-wrangler-d1 --run-dir ~/dev/my-project --d1-schema my_db --d1-file ./schema.sql --d1-location local
```

### 2. 원격 D1의 스키마 및 데이터 백업(Migration)
```bash
init-wrangler-d1 --run-dir ~/dev/my-project --d1-schema my_db --d1-location migration
```

### 3. 대화형 선택 실행
```bash
init-wrangler-d1 --run-dir ~/dev/my-project --d1-schema my_db --d1-file ./schema.sql
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./init-wrangler-d1 --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./init-wrangler-d1 --target global
```
