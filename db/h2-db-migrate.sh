#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : h2-db-migrate
# @license  : Apache License 2.0
# @since    : 2026-04-29
# @desc     : support RHEL 8/9, Oracle Linux 8/9, Ubuntu 22.04/24.04, RockyOS 8/9
# @installation : 
#   1. insert 'source <path>/h2-db-migrate.sh' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/h2-db-migrate.sh' into /etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")

##
# 도움말을 출력하고 프로그램을 종료하거나 에러 스택을 표시합니다.
#
# @param $1 {string} 에러 원인
# @param $2 {number} 에러 발생 라인
##
help(){
  if [ ! -z "$1" ]; then
    local indent=10
    local formatl=" - %-"$indent"s: %s\n"
    local formatr=" - %"$indent"s: %s\n"
    echo
    echo "================================================================================"
    printf "$formatl" "filename" "$FILENAME"
    printf "$formatl" "line" "$2"
    printf "$formatl" "callstack"
    local idx=1
    for func in ${FUNCNAME[@]:1}; do  
      printf "$formatr" "["$idx"]" $func
      ((idx++))
    done
    printf "$formatl" "cause" "$1"
    echo "================================================================================"
  fi  
  echo  
  echo "사용법: $FILENAME [옵션]"
  echo "이 스크립트는 파라미터 없이 실행 시 대화형 모드(인터랙티브)로 진행됩니다."
  echo "옵션:"
  echo "  -h,   --help                  도움말 출력"
}

##
# 디렉토리가 존재하지 않는 경우 자동으로 중간 경로까지 생성합니다.
#
# @param $1 {string} 대상 경로
##
ensure_directory_exists() {
  local target_dir
  target_dir=$(dirname "$1")
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
  fi
}

##
# JAR 파일 경로를 탐색하여 반환합니다.
#
# @param $1 {string} 버전
# @param $2 {string} 라이브러리 경로
##
resolve_jar() {
  local version="$1"
  local lib_path="$2"
  local standard_path="$lib_path/repository/com/h2database/h2/$version/h2-$version.jar"
  local flat_path="$lib_path/h2-$version.jar"

  if [ -f "$standard_path" ]; then
    echo "$standard_path"
  elif [ -f "$flat_path" ]; then
    echo "$flat_path"
  else
    echo ""
  fi
}

##
# H2 데이터베이스 데이터 추출 및 원본 백업을 수행합니다.
#
# @param $1 {string} DB 파일 경로
# @param $2 {string} 백업 SQL 경로
# @param $3 {string} ASIS JAR 경로
# @param $4 {string} 사용자명
# @param $5 {string} 비밀번호
# @param $6 {string} ASIS 버전
##
execute_backup() {
  local db_file="$1"
  local backup_sql_file="$2"
  local asis_jar="$3"
  local db_user="$4"
  local db_pass="$5"
  local asis_version="$6"
  
  local db_base_path="${db_file%.mv.db}"
  local jdbc_url="jdbc:h2:$db_base_path"
  local backup_db_file="${db_file}-${asis_version}-backup"

  echo "▶ [MODE: BACKUP] 데이터 추출 및 원본 $MODE_NAME 시작..."
  java -cp "$asis_jar" org.h2.tools.Script -url "$jdbc_url" -user "$db_user" -password "$db_pass" -script "$backup_sql_file"

  if [ $? -ne 0 ]; then
    help "데이터 추출에 실패했습니다." "$LINENO"
    exit 1
  fi
  
  # --- [메타데이터 저장] 백업 SQL 파일 하단에 정보 기록 ---
  echo "" >> "$backup_sql_file"
  echo "-- @h2-migrate-user: $db_user" >> "$backup_sql_file"
  echo "-- @h2-migrate-pass: $db_pass" >> "$backup_sql_file"
  echo "-- @h2-migrate-version: $asis_version" >> "$backup_sql_file"
  echo "-- @h2-migrate-file: $(basename "$db_file")" >> "$backup_sql_file"
  # -------------------------------------------------------

  mv "$db_file" "$backup_db_file"
  [ -f "${db_base_path}.trace.db" ] && mv "${db_base_path}.trace.db" "${db_base_path}.trace.db-${asis_version}-backup"
  echo "✅ 데이터 추출 및 원본 $MODE_NAME 완료"
}

##
# 신규 포맷의 데이터베이스를 생성하고 데이터를 복원합니다.
#
# @param $1 {string} 생성할 DB 파일 경로
# @param $2 {string} 백업 SQL 경로
# @param $3 {string} TOBE JAR 경로
# @param $4 {string} 사용자명
# @param $5 {string} 비밀번호
# @param $6 {string} ASIS 버전
##
execute_restore() {
  local db_file="$1"
  local backup_sql_file="$2"
  local tobe_jar="$3"
  local db_user="$4"
  local db_pass="$5"
  local asis_version="$6"
  
  local db_base_path="${db_file%.mv.db}"
  local jdbc_url="jdbc:h2:$db_base_path"
  local backup_db_file="${db_file}-${asis_version}-backup"

  echo "▶ [MODE: RESTORE] 신규 데이터베이스 생성 및 $MODE_NAME 시작..."
  java -cp "$tobe_jar" org.h2.tools.RunScript -url "$jdbc_url" -user "$db_user" -password "$db_pass" -script "$backup_sql_file"

  if [ $? -ne 0 ]; then
    echo "❌ [ERROR] 데이터 $MODE_NAME 실패. 기존 백업 파일로 롤백합니다."
    if [ -f "$backup_db_file" ]; then
      mv "$backup_db_file" "$db_file"
      [ -f "${db_base_path}.trace.db-${asis_version}-backup" ] && mv "${db_base_path}.trace.db-${asis_version}-backup" "${db_base_path}.trace.db"
    fi
    exit 1
  fi
  echo "✅ 데이터 $MODE_NAME 완료"
}

# ==============================================================================
# 메인 실행 흐름
# ==============================================================================

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  help
  exit 0
fi

echo "================================================================"
echo " H2 Database 마이그레이션 도구 (Interactive Mode)"
echo "================================================================"
echo ""

DEFAULT_M2_HOME="${M2_REPO_HOME:-$HOME/.m2}"

# 1. 실행 모드
while true; do
  read -p "1. 실행모드 (b: 백업, r: 복원, m: 이관): " APP_MODE
  if [[ "$APP_MODE" =~ ^(b|r|m)$ ]]; then
    break
  fi
  echo "   ❌ 올바른 값을 입력해주세요 (b, r, m 중 하나)."
done

# 2~3단계: 백업(b) 또는 이관(m) 시에만 수행
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  # 2. H2 DB 이전 버전
  DEFAULT_H2_ASIS="2.1.214"
  read -p "2. H2 DB 이전 버전 [$DEFAULT_H2_ASIS]: " APP_H2_ASIS
  APP_H2_ASIS="${APP_H2_ASIS:-$DEFAULT_H2_ASIS}"

  # 3. 이전 버전을 처리할 jar 파일 경로
  ASIS_JAR_PATH=""
  while true; do
    read -e -p "3. Maven/Lib 경로 [$DEFAULT_M2_HOME]: " APP_ASIS_LIB_DIR
    APP_ASIS_LIB_DIR="${APP_ASIS_LIB_DIR:-$DEFAULT_M2_HOME}"
    
    ASIS_JAR_PATH=$(resolve_jar "$APP_H2_ASIS" "$APP_ASIS_LIB_DIR")
    if [ -n "$ASIS_JAR_PATH" ]; then
      break
    else
      echo "   ❌ [$APP_ASIS_LIB_DIR] 경로에서 h2-$APP_H2_ASIS.jar를 찾을 수 없습니다."
    fi
  done
else
  APP_H2_ASIS="해당 없음(N/A)"
  ASIS_JAR_PATH="해당 없음(N/A)"
fi

# 4~5단계: 복원(r) 또는 이관(m) 시에만 수행
if [[ "$APP_MODE" == "r" || "$APP_MODE" == "m" ]]; then
  # 4. H2 DB 신규 버전
  DEFAULT_H2_TOBE="2.4.240"
  read -p "4. H2 DB 신규 버전 [$DEFAULT_H2_TOBE]: " APP_H2_TOBE
  APP_H2_TOBE="${APP_H2_TOBE:-$DEFAULT_H2_TOBE}"

  # 5. 신규 버전을 처리할 jar 파일 경로
  TOBE_JAR_PATH=""
  while true; do
    read -e -p "5. Maven/Lib 경로 [$DEFAULT_M2_HOME]: " APP_TOBE_LIB_DIR
    APP_TOBE_LIB_DIR="${APP_TOBE_LIB_DIR:-$DEFAULT_M2_HOME}"
    
    TOBE_JAR_PATH=$(resolve_jar "$APP_H2_TOBE" "$APP_TOBE_LIB_DIR")
    if [ -n "$TOBE_JAR_PATH" ]; then
      break
    else
      echo "   ❌ [$APP_TOBE_LIB_DIR] 경로에서 h2-$APP_H2_TOBE.jar를 찾을 수 없습니다."
    fi
  done
else
  APP_H2_TOBE="해당 없음(N/A)"
  TOBE_JAR_PATH="해당 없음(N/A)"
fi

# 6. 데이터 파일 경로
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  DATA_PROMPT_MSG="\"\${schema}.mv.db\" 이름을 갖는 파일의 전체 또는 상대 경로"
else
  DATA_PROMPT_MSG="\"*-backup.sql\" 이름을 갖는 파일의 전체 또는 상대 경로"
fi

while true; do
  read -e -p "6. 데이터 파일 ($DATA_PROMPT_MSG) : " APP_DATA_FILE
  if [ -z "$APP_DATA_FILE" ]; then
    echo "   ❌ 파일 경로를 입력해주세요."
    continue
  fi

  if [[ ! "$APP_DATA_FILE" =~ ^/ && ! "$APP_DATA_FILE" =~ ^\./ && ! "$APP_DATA_FILE" =~ ^~ ]]; then
    APP_DATA_FILE="./$APP_DATA_FILE"
  fi

  if [ ! -f "$APP_DATA_FILE" ]; then
    echo "   ❌ 파일이 존재하지 않습니다: $APP_DATA_FILE"
  else
    break
  fi
done

# --- [메타데이터 추출] 복원(r) 모드일 경우 백업 파일에서 정보 로드 ---
EXTRACTED_USER=""
EXTRACTED_PASS=""
EXTRACTED_ASIS_VER=""
EXTRACTED_ASIS_FILE=""

if [[ "$APP_MODE" == "r" ]]; then
  EXTRACTED_USER=$(grep "^-- @h2-migrate-user: " "$APP_DATA_FILE" | head -n 1 | sed 's/^-- @h2-migrate-user: //')
  EXTRACTED_PASS=$(grep "^-- @h2-migrate-pass: " "$APP_DATA_FILE" | head -n 1 | sed 's/^-- @h2-migrate-pass: //')
  EXTRACTED_ASIS_VER=$(grep "^-- @h2-migrate-version: " "$APP_DATA_FILE" | head -n 1 | sed 's/^-- @h2-migrate-version: //')
  EXTRACTED_ASIS_FILE=$(grep "^-- @h2-migrate-file: " "$APP_DATA_FILE" | head -n 1 | sed 's/^-- @h2-migrate-file: //')
  
  # 복원 모드에서 실패 시 롤백을 위해 추출된 버전을 할당
  if [ -n "$EXTRACTED_ASIS_VER" ]; then
    APP_H2_ASIS="$EXTRACTED_ASIS_VER"
  fi
fi

# 7. DB 사용자 이름
if [ -n "$EXTRACTED_USER" ]; then
  read -p "7. DB 사용자 이름 [$EXTRACTED_USER]: " APP_DB_USER
  APP_DB_USER="${APP_DB_USER:-$EXTRACTED_USER}"
else
  read -p "7. DB 사용자 이름: " APP_DB_USER
fi

# 8. DB 사용자 Credential
if [ -n "$EXTRACTED_PASS" ]; then
  read -p "8. DB 사용자 Credential [$EXTRACTED_PASS]: " APP_DB_PASS
  APP_DB_PASS="${APP_DB_PASS:-$EXTRACTED_PASS}"
else
  read -p "8. DB 사용자 Credential: " APP_DB_PASS
fi

# 모드 명칭 설정
MODE_NAME=""
MODE_ACTION=""
if [ "$APP_MODE" == "b" ]; then
  MODE_NAME="백업"
  MODE_ACTION="백업을"
elif [ "$APP_MODE" == "r" ]; then
  MODE_NAME="복원"
  MODE_ACTION="복원을"
elif [ "$APP_MODE" == "m" ]; then
  MODE_NAME="이관"
  MODE_ACTION="이관을"
fi

# 9. 입력 정보 요약 출력
echo ""
echo "================================================================"
echo " [입력 정보 확인]"
echo "================================================================"
echo " 1. 실행모드            : $MODE_NAME"
echo " 2. H2 DB 이전 버전     : $APP_H2_ASIS"
echo " 3. 이전 버전 JAR 경로  : $ASIS_JAR_PATH"
echo " 4. H2 DB 신규 버전     : $APP_H2_TOBE"
echo " 5. 신규 버전 JAR 경로  : $TOBE_JAR_PATH"
echo " 6. 데이터 파일         : $APP_DATA_FILE"
echo " 7. DB 사용자 이름      : $APP_DB_USER"
echo " 8. DB 사용자 Credential: $APP_DB_PASS"
echo "================================================================"
echo ""

# 10. 최종 실행 여부 확인
while true; do
  read -p "위와 같은 정보를 이용하여 $MODE_ACTION 진행하겠습니까? (Y/N): " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    break
  elif [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "작업을 취소하고 종료합니다."
    exit 0
  else
    echo "❌ Y 또는 N을 입력해주세요."
  fi
done

echo ""
echo "================================================================"
echo " 데이터 처리를 시작합니다."
echo "================================================================"

# 경로 파싱 및 파일 설정
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  SCHEMA_PATH="${APP_DATA_FILE%.mv.db}"
  APP_DB_FILE="$APP_DATA_FILE"
  APP_BACKUP_SQL_FILE="${SCHEMA_PATH}-${APP_H2_ASIS}-backup.sql"
else
  # 복원(r) 모드: 메타데이터에서 원본 파일명을 찾거나 SQL 파일명에서 유추
  if [ -n "$EXTRACTED_ASIS_FILE" ]; then
    DIR_NAME=$(dirname "$APP_DATA_FILE")
    APP_DB_FILE="${DIR_NAME}/${EXTRACTED_ASIS_FILE}"
  else
    # 메타데이터 없을 경우 이전 방식 유지 (fallback)
    SCHEMA_PATH="${APP_DATA_FILE%-${APP_H2_ASIS}-backup.sql}"
    APP_DB_FILE="${SCHEMA_PATH}.mv.db"
  fi
  APP_BACKUP_SQL_FILE="$APP_DATA_FILE"
fi

# 중간 디렉토리 보장
ensure_directory_exists "$APP_BACKUP_SQL_FILE"

# 실행
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  execute_backup "$APP_DB_FILE" "$APP_BACKUP_SQL_FILE" "$ASIS_JAR_PATH" "$APP_DB_USER" "$APP_DB_PASS" "$APP_H2_ASIS"
fi

if [[ "$APP_MODE" == "r" || "$APP_MODE" == "m" ]]; then
  execute_restore "$APP_DB_FILE" "$APP_BACKUP_SQL_FILE" "$TOBE_JAR_PATH" "$APP_DB_USER" "$APP_DB_PASS" "$APP_H2_ASIS"
fi

# 이관(m) 모드 클린업
if [[ "$APP_MODE" == "m" ]]; then
  echo "▶ [MODE: CLEANUP] 이관 완료에 따른 중간 생성물 삭제..."
  [ -f "$APP_BACKUP_SQL_FILE" ] && rm -f "$APP_BACKUP_SQL_FILE" && echo "✅ 중간 백업 파일 삭제 완료."
fi

echo "🎉 모든 작업($APP_MODE)이 성공적으로 완료되었습니다!"
exit 0
