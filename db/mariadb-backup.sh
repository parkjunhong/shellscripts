#!/usr/bin/env bash

set -e

# 설정
DB_USER=""
DB_PASSWORD=""
DB_HOST="localhost"
BACKUP_DIR=""
BACKUP_FILE_PATTERN="mariadb_backup_*.sql.gz"
RETENTION_DAYS=7

##
# 도움말 출력
##
help() {
  echo "Usage: $(basename $0) [OPTIONS]"
  echo ""
  echo "MariaDB 백업 스크립트"
  echo ""
  echo "Options:"
  echo "  -u, --user <username>      MariaDB 사용자 이름"
  echo "  -p, --password <password>  MariaDB 사용자 비밀번호 (비권장, 환경 변수 사용 권장)"
  echo "  -h, --host <hostname>      MariaDB 서버 주소 (기본값: localhost)"
  echo "  -d, --dir <directory>      백업 파일을 저장할 디렉토리"
  echo "  -f, --file-pattern <pattern> 백업 파일 이름 패턴 (기본값: mariadb_backup_*.sql.gz)"
  echo "  -r, --retention <days>     백업 파일 보관 기간 (일) (기본값: 7)"
  echo "  -h, --help                 도움말 출력"
  echo ""
  exit 1
}

##
# 파라미터 처리
##
parse_options() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -u|--user)
      DB_USER="$2"
      shift 2
      ;;
    -p|--password)
      DB_PASSWORD="$2"
      shift 2
      ;;
    -h|--host)
      DB_HOST="$2"
      shift 2
      ;;
    -d|--dir)
      BACKUP_DIR="$2"
      shift 2
      ;;
    -f|--file-pattern)
      BACKUP_FILE_PATTERN="$2"
      shift 2
      ;;
    -r|--retention)
      RETENTION_DAYS="$2"
      shift 2
      ;;
    -h|--help)
      help
      ;;
    *)
      echo "알 수 없는 옵션: $1"
      help
      ;;
    esac
  done

  # 필수 파라미터 확인
  if [[ -z "$DB_USER" || -z "$BACKUP_DIR" ]]; then
    echo "사용자 이름과 백업 디렉토리는 필수입니다."
    help
  fi

  # 백업 디렉토리 존재 확인
  mkdir -p "${BACKUP_DIR}"
}

##
# 백업 실행
##
backup_mariadb() {
  NOW=$(date +"%Y%m%d_%H%M%S")
  BACKUP_FILE="${BACKUP_DIR}/mariadb_backup_${NOW}.sql.gz"

  echo "MariaDB 백업 진행 중..."
  mysqldump -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWORD}" --all-databases --events --routines --triggers | gzip > "${BACKUP_FILE}"

  echo "MariaDB 백업 성공: ${BACKUP_FILE}"
}

##
# 오래된 백업 파일 삭제
##
cleanup_old_backups() {
  find "${BACKUP_DIR}" -name "${BACKUP_FILE_PATTERN}" -mtime +"${RETENTION_DAYS}" -delete
  echo "오래된 백업 파일 삭제 완료"
}

# 파라미터 처리
parse_options "$@"

# 백업 실행
backup_mariadb

# 오래된 백업 파일 삭제
cleanup_old_backups

exit 0


