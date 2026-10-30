# db

데이터베이스 백업, 복원 및 마이그레이션 유틸리티 도구를 제공하는 디렉토리입니다.

---

## 🛠️ 제공 도구 목록

| 도구명 | 설명 | 지원 기능 |
| :--- | :--- | :--- |
| [`mariadb-backup`](./mariadb-backup/README.md) | MariaDB 전체 데이터베이스 백업 도구 | 전체 DB 덤프, gzip 압축, 보관 주기 초과 백업 자동 삭제 |
| [`mariadb-restore`](./mariadb-restore/README.md) | MariaDB 데이터베이스 복원 도구 | 복원 전 사전 안전 백업, 대화형 파일 선택 및 직접 파일 복원 지원 |
| [`h2-db-migrate`](./h2-db-migrate/README.md) | H2 데이터베이스 버전 마이그레이션 도구 | 대화형 마이그레이션/추출/복원, 버전 간 호환 처리 및 자동 롤백 |

---

## 📁 디렉토리 구조

```plaintext
db/
├── README.md
├── h2-db-migrate/
│   ├── README.md
│   ├── h2-db-migrate
│   └── h2-db-migrate.completion
├── mariadb-backup/
│   ├── README.md
│   ├── mariadb-backup
│   └── mariadb-backup.completion
└── mariadb-restore/
    ├── README.md
    ├── mariadb-restore
    └── mariadb-restore.completion
```

---

## 🛠️ 공통 설치 안내

저장소의 `utils/scriptctl` 도구를 사용하여 개인 환경(`~/bin`) 또는 시스템 전역 경로에 간편하게 설치할 수 있습니다. 설치 시 Bash 자동완성 스크립트도 시스템 표준 경로에 자동으로 등록됩니다.

```bash
# 개인 환경 설치 (~/bin, 사용자 자동완성 등록)
../utils/scriptctl/scriptctl install --script ./mariadb-backup/mariadb-backup --target local
../utils/scriptctl/scriptctl install --script ./mariadb-restore/mariadb-restore --target local
../utils/scriptctl/scriptctl install --script ./h2-db-migrate/h2-db-migrate --target local

# 시스템 전역 설치 (/usr/local/bin, /usr/share/bash-completion/completions/ 등록)
../utils/scriptctl/scriptctl install --script ./mariadb-backup/mariadb-backup --target global
../utils/scriptctl/scriptctl install --script ./mariadb-restore/mariadb-restore --target global
../utils/scriptctl/scriptctl install --script ./h2-db-migrate/h2-db-migrate --target global
```
