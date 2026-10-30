# redis-search

`redis-search`는 Redis 데이터베이스를 대상으로 커서 기반의 안전한 전체 키 스캔(`scan`), 정규식 패턴 매칭 필터링, 다중값 및 단일값 데이터 조회를 지원하는 고도화된 Redis CLI 검색 도구입니다.

---

## ✨ 주요 특징

- **정규식 패턴 필터링**:
  - `__filter_in__`: 정규식 패턴과 일치하는 키만 필터링하여 데이터 조회
  - `__filter_out__`: 정규식 패턴과 일치하지 않는 키만 필터링하여 데이터 조회
- **안전한 전체 데이터 조회 (`__get_all__`)**: Redis 서버의 부하를 유발하는 `keys *` 대신 커서 기반의 `scan` 명령어를 사용하여 대용량 데이터베이스에서도 안전하게 전체 키를 순회합니다.
- **Key-Value 매핑 출력**: `--key` 옵션을 추가하면 키와 값을 탭(`\t`)으로 구분하여 직관적으로 출력합니다.
- **다양한 자료구조 지원**: `get`, `lrange`, `hgetall`, `smembers` 등 다양한 Redis 명령어와 유연하게 결합됩니다.

---

## ⚙️ 파라미터 및 커맨드 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

### 명령어 형식
```bash
redis-search <database> <command | built-in> [arguments...] [--key] [--help] [--dbinfo]
```

| 파라미터 / 옵션 | 필수 여부 | 설명 |
| :--- | :---: | :--- |
| `<database>` | **필수** | 대상 Redis 데이터베이스 번호 (0 ~ 15) |
| `<command>` | **필수** | 일반 Redis 명령어 또는 아래의 내장 커맨드 |
| `--key` | 선택 | 조회 결과 출력 시 `키<tab>값` 형식으로 키를 함께 출력 |
| `--dbinfo` | 선택 | Redis 데이터베이스 정보 확인 |
| `--help` | 선택 | 도움말 및 사용법 안내 출력 |

### 내장 커맨드 (Built-in Commands)
- `__filter_in__ <regex> <redis-cmd> [args...]`: 정규식과 일치하는 키 대상 명령어 실행
- `__filter_out__ <regex> <redis-cmd> [args...]`: 정규식과 불일치하는 키 대상 명령어 실행
- `__get_all__ <redis-cmd> [args...]`: `scan` 커서를 순회하며 모든 키에 대해 명령어 실행
- `__get_one__ <redis-cmd> [args...]`: 단일 키 대상 명령어 실행

---

## 🚀 사용 예시

### 1. 정규식 패턴 매칭 조회 (`__filter_in__`)
DB 4번에서 `session_`으로 시작하는 모든 키의 `get` 값을 조회:
```bash
redis-search 4 __filter_in__ "^session_" get --key
```

### 2. 전체 리스트 자료구조 일괄 조회 (`__get_all__`)
DB 1번의 모든 리스트 키에 대해 `lrange 0 -1`을 실행하여 전체 데이터 조회:
```bash
redis-search 1 __get_all__ lrange 0 -1 --key
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./redis-search --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./redis-search --target global
```
