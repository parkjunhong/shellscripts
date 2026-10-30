# migration-d1-init-scheme

`migration-d1-init-scheme`는 Cloudflare D1 또는 SQLite 데이터베이스 마이그레이션 시, 기존 SQL 스키마 덤프 파일 내의 모든 `CREATE TABLE` 구문을 탐색하여 직전에 `DROP TABLE IF EXISTS` 구문을 자동으로 주입해 주는 스키마 전처리 CLI 도구입니다.

---

## ✨ 주요 특징

- **DROP TABLE 구문 자동 주입**: 원본 SQL 파일의 각 `CREATE TABLE [IF NOT EXISTS] <table_name>` 구문을 파싱하여 테이블명에 맞는 `DROP TABLE IF EXISTS <table_name>;` 구문을 사전에 자동으로 삽입합니다.
- **안전한 덮어쓰기 방지**: 출력 파일(`--init-sql`)이 이미 존재하는 경우 사용자의 명시적 확인(`Y/n`)을 거치며, `--force-overwrite` 플래그로 비대화형 강제 덮어쓰기도 지원합니다.
- **대소문자 비구분 정규식 파싱**: `create table`, `CREATE TABLE` 등 대소문자에 무관하게 정확한 테이블명을 추출합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `--src-sql <파일경로>` | **필수** | 원본 입력 SQL 스키마 파일 경로 |
| `--init-sql <파일경로>` | **필수** | DROP 구문이 주입되어 새로 생성될 출력 SQL 파일 경로 |
| `--force-overwrite` | 선택 | 출력 파일이 이미 존재하더라도 확인 없이 강제 덮어쓰기 |
| `--help` | 선택 | 사용법 및 도움말 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 스키마 전처리
```bash
migration-d1-init-scheme --src-sql schema_dump.sql --init-sql schema_init.sql
```

### 2. 출력 파일 강제 덮어쓰기
```bash
migration-d1-init-scheme --src-sql schema_dump.sql --init-sql schema_init.sql --force-overwrite
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./migration-d1-init-scheme --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./migration-d1-init-scheme --target global
```
