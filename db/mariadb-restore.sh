#!/usr/bin/env bash

set -e

# 설정
DB_USER=""
DB_PASSWORD=""
DB_HOST="localhost"
BACKUP_DIR=""
BACKUP_FILE_PATTERN="mariadb_backup_*.sql.gz"

##
# 도움말 출력
##
help() {
  echo "Usage: $(basename $0) [OPTIONS]"
  echo ""
  echo "MariaDB 복원 스크립트"
  echo ""
  echo "Options:"
  echo "  -u, --user <username>      MariaDB 사용자 이름"
  echo "  -p, --password <password>  MariaDB 사용자 비밀번호 (비권장, 환경 변수 사용 권장)"
  echo "  -h, --host <hostname>      MariaDB 서버 주소 (기본값: localhost)"
  echo "  -d, --dir <directory>      백업 파일이 저장된 디렉토리"
  echo "  -f, --file-pattern <pattern> 복구할 백업 파일 이름 패턴 (기본값: mariadb_backup_*.sql.gz)"
  echo "  -h, --help                 도움말 출력"
  echo ""
  exit 1
}

##
# 백업 파일 선택
##
select_backup_file() {
  BACKUP_FILES=($(find "${BACKUP_DIR}" -name "${BACKUP_FILE_PATTERN}" | sort))

  if [[ ${#BACKUP_FILES[@]} -eq 0 ]]; then
    echo "백업 파일을 찾을 수 없습니다."
    exit 1
  fi

  echo "사용 가능한 백업 파일 목록:"
  for i in "${!BACKUP_FILES[@]}"; do
    printf "[%d] %s\n" "$((i+1))" "$(basename "${BACKUP_FILES[i]}")"
  done

  read -p "복원할 백업 파일 번호를 입력하세요: " CHOICE
  SELECTED_FILE="${BACKUP_FILES[$((CHOICE-1))]}"

  echo "선택한 백업 파일: $(basename "$SELECTED_FILE")"
}

##
# 복원 실행
##
restore_mariadb() {
  select_backup_file

  echo "MariaDB 백업 후 데이터베이스 복원 시작..."
  mysqldump -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWORD}" --all-databases > "${BACKUP_DIR}/pre_restore_backup.sql"

  echo "MariaDB 데이터 복원 중..."
  gunzip < "${SELECTED_FILE}" | mysql -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWORD}"

  echo "MariaDB 복원 완료: $(basename "${SELECTED_FILE}")"
}

# 파라미터 처리
parse_options "$@"

# 복원 실행
restore_mariadb

exit 0

