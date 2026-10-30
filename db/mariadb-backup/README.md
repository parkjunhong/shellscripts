# mariadb-backup

`mariadb-backup`은 `mysqldump`를 사용하여 MariaDB의 전체 데이터베이스(이벤트, 루틴, 트리거 포함)를 안전하게 백업하고, `gzip` 압축 및 보관 기간에 따른 오래된 백업 자동 정리를 수행하는 CLI 도구입니다.

---

## ✨ 주요 특징

- **전체 데이터베이스 일괄 백업**: `--all-databases`, `--events`, `--routines`, `--triggers`를 포함하여 완벽한 DB 덤프를 생성합니다.
- **gzip 자동 압축**: 덤프 생성과 동시에 `.sql.gz` 형식으로 압축하여 디스크 공간을 절약합니다.
- **보관 주기 자동 관리**: 지정된 보관 일수(`--retention`, 기본값: 7일)를 초과한 오래된 백업 파일을 자동으로 탐색하여 정리합니다.
- **디렉토리 자동 생성**: 백업 디렉토리가 존재하지 않을 경우 자동으로 생성합니다.

---

## ⚙️ 파라미터 명세

> [!NOTE]
> 본 도구는 **Long Option** 전용으로 동작하며, Short Option은 지원하지 않습니다.

| 파라미터 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `--user <사용자명>` | **필수** | - | MariaDB 접속 사용자 이름 |
| `--dir <디렉토리>` | **필수** | - | 백업 파일을 저장할 디렉토리 경로 |
| `--password <비밀번호>` | 선택 | 없음 | MariaDB 사용자 비밀번호 |
| `--host <호스트명>` | 선택 | `localhost` | MariaDB 서버 주소 |
| `--file-pattern <패턴>` | 선택 | `mariadb_backup_*.sql.gz` | 정리 대상 백업 파일 패턴 |
| `--retention <일수>` | 선택 | `7` | 백업 파일 보관 기간(일) |
| `--help` | 선택 | - | 도움말 및 옵션 안내 출력 |

---

## 🚀 사용 예시

### 1. 기본 백업 실행
```bash
mariadb-backup --user root --password "mypassword" --dir /data/backup/mariadb
```

### 2. 원격 호스트 및 보관 기간(14일) 지정
```bash
mariadb-backup --host 192.168.1.50 --user dbadmin --password "secret" --dir /backup/db --retention 14
```

---

## 💻 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 실행 경로(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../../utils/scriptctl/scriptctl install --script ./mariadb-backup --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../../utils/scriptctl/scriptctl install --script ./mariadb-backup --target global
```
