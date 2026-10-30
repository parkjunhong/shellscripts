# mariadb-restore

`mariadb-restore`는 MariaDB의 데이터베이스 백업 파일(`.sql.gz`)을 안전하게 복원하는 CLI 도구입니다. 복원 작업 전 현재 데이터베이스의 사전 백업을 자동으로 수행하며, 대화형 파일 선택 및 직접 파일 경로 지정 방식을 모두 지원합니다.

---

## ✨ 주요 특징

- **복원 전 사전 안전 백업**: 복원을 진행하기 전 현재 데이터베이스의 스냅샷(`pre_restore_backup_*.sql`)을 생성하여 복구 실패 시 롤백할 수 있습니다.
- **대화형 백업 파일 선택**: 백업 디렉토리 내의 가용 파일 목록을 번호로 출력하고 사용자가 손쉽게 선택할 수 있는 인터페이스를 제공합니다.
- **비대화형 직접 파일 지정 지원**: `--file` 옵션을 통해 특정 백업 파일을 바로 지정하여 복원할 수도 있습니다.
- **gzip 자동 압축 해제 파이프라인**: 압축 해제와 복원을 파이프라인(`gunzip < ... | mysql`)으로 처리하여 디스크 I/O를 최소화합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--user <사용자명>` | **필수** | - | MariaDB 접속 사용자 이름 |
| `--dir <디렉토리>` | **필수** | - | 백업 파일이 위치한 디렉토리 경로 |
| `--password <비밀번호>` | 선택 | 없음 | MariaDB 사용자 비밀번호 |
| `--host <호스트명>` | 선택 | `localhost` | MariaDB 서버 주소 |
| `--file <파일경로>` | 선택 | 없음 | 복원할 특정 백업 파일 경로 (생략 시 대화형 목록 선택) |
| `--file-pattern <패턴>` | 선택 | `mariadb_backup_*.sql.gz` | 대화형 검색 대상 백업 파일 패턴 |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 대화형 복원 실행 (목록에서 번호 선택)
```bash
mariadb-restore --user root --password "mypassword" --dir /data/backup/mariadb
```

### 2. 특정 백업 파일 직접 지정 복원
```bash
mariadb-restore --user root --password "mypassword" --dir /data/backup/mariadb --file /data/backup/mariadb/mariadb_backup_20261030_090000.sql.gz
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./mariadb-restore --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./mariadb-restore --target global
```
