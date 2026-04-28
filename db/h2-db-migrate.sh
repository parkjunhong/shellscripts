#!/usr/bin/env bash

# =======================================
# @author   : parkjunhong77@gmail.com
# @title    : h2-db-migrate
# @license  : Apache License 2.0
# @since    : 2026-04-28
# @desc     : support RHEL 8/9, Oracle Linux 8/9, Ubuntu 22.04/24.04, RockyOS 8/9
# @installation : 
#   1. insert 'source <path>/h2-db-migrate.sh' into ~/bin/.bashrc or ~/bin/.bash_profile for a personal usage.
#   2. copy the above file to /etc/bash_completion.d/ or insert 'source <path>/h2-db-migrate.sh' into /etc/bashrc for all users.
# =======================================

FILENAME=$(basename "$0")

##
# 도움말을 출력하고 프로그램을 종료하거나 에러 스택을 표시합니다.
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
##
execute_backup() {
  local db_file="$1"
  local backup_sql_file="$2"
  local asis_jar="$3"
  local db_user="$4"
  local db_pass="$5"
  
  local db_base_path="${db_file%.mv.db}"
  local jdbc_url="jdbc:h2:$db_base_path"
  local backup_db_file="${db_file}-backup"

  echo "▶ [MODE: BACKUP] 데이터 추출 및 원본 백업 시작..."
  java -cp "$asis_jar" org.h2.tools.Script -url "$jdbc_url" -user "$db_user" -password "$db_pass" -script "$backup_sql_file"

  if [ $? -ne 0 ]; then
    help "데이터 추출에 실패했습니다." "$LINENO"
    exit 1
  fi
  
  mv "$db_file" "$backup_db_file"
  [ -f "${db_base_path}.trace.db" ] && mv "${db_base_path}.trace.db" "${db_base_path}.trace.db-backup"
  echo "✅ 데이터 추출 및 원본 백업 완료"
}

##
# 신규 포맷의 데이터베이스를 생성하고 데이터를 복원합니다.
##
execute_restore() {
  local db_file="$1"
  local backup_sql_file="$2"
  local tobe_jar="$3"
  local db_user="$4"
  local db_pass="$5"
  
  local db_base_path="${db_file%.mv.db}"
  local jdbc_url="jdbc:h2:$db_base_path"
  local backup_db_file="${db_file}-backup"

  echo "▶ [MODE: RESTORE] 신규 데이터베이스 생성 및 복원 시작..."
  java -cp "$tobe_jar" org.h2.tools.RunScript -url "$jdbc_url" -user "$db_user" -password "$db_pass" -script "$backup_sql_file"

  if [ $? -ne 0 ]; then
    echo "❌ [ERROR] 데이터 복원 실패. 기존 백업 파일로 롤백합니다."
    mv "$backup_db_file" "$db_file"
    [ -f "${db_base_path}.trace.db-backup" ] && mv "${db_base_path}.trace.db-backup" "${db_base_path}.trace.db"
    exit 1
  fi
  echo "✅ 데이터 복원 완료"
}

# ==============================================================================
# 메인 실행 흐름 (대화형 정보 수집)
# ==============================================================================

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  help
  exit 0
fi

# 초기 안내 문구
echo "================================================================"
echo " H2 Database 마이그레이션 도구 (Interactive Mode)"
echo "================================================================"
echo ""

DEFAULT_M2_HOME="${M2_REPO_HOME:-$HOME/.m2}"

# 1. 실행 모드
while true; do
  read -p "1. 실행모드 (b: 백업, r: 복구, m: 이관): " APP_MODE
  if [[ "$APP_MODE" =~ ^(b|r|m)$ ]]; then
    break
  fi
  echo "   ❌ 올바른 값을 입력해주세요 (b, r, m 중 하나)."
done

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

# 6. 데이터 파일 경로
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  DATA_PROMPT_MSG="\"\${schema}.mv.db\" 이름을 갖는 파일의 전체 또는 상대 경로"
else
  DATA_PROMPT_MSG="\"\${schema}-backup.sql\" 이름을 갖는 파일의 전체 또는 상대 경로"
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

# 7. DB 사용자 이름
read -p "7. DB 사용자 이름: " APP_DB_USER

# 8. DB 사용자 Credential
read -p "8. DB 사용자 Credential: " APP_DB_PASS

# 모드 명칭 설정
MODE_NAME=""
MODE_ACTION=""
if [ "$APP_MODE" == "b" ]; then
  MODE_NAME="백업"
  MODE_ACTION="백업을"
elif [ "$APP_MODE" == "r" ]; then
  MODE_NAME="복구"
  MODE_ACTION="복구를"
elif [ "$APP_MODE" == "m" ]; then
  MODE_NAME="이관"
  MODE_ACTION="이관을"
fi

# 9. 입력 정보 요약 출력 (정렬 최적화 및 JAR 전체 경로 포함)
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
  read -p "위와 같은 정보를 $MODE_ACTION 진행하겠습니까? (Y/N): " CONFIRM
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

# 경로 파싱 및 스키마 추출
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  SCHEMA_PATH="${APP_DATA_FILE%.mv.db}"
  APP_DB_FILE="$APP_DATA_FILE"
  APP_BACKUP_SQL_FILE="${SCHEMA_PATH}-backup.sql"
else
  SCHEMA_PATH="${APP_DATA_FILE%-backup.sql}"
  APP_DB_FILE="${SCHEMA_PATH}.mv.db"
  APP_BACKUP_SQL_FILE="$APP_DATA_FILE"
fi

# 결과물 저장 중간 디렉토리 보장
ensure_directory_exists "$APP_BACKUP_SQL_FILE"
ensure_directory_exists "${APP_DB_FILE}-backup"

# 실행
if [[ "$APP_MODE" == "b" || "$APP_MODE" == "m" ]]; then
  execute_backup "$APP_DB_FILE" "$APP_BACKUP_SQL_FILE" "$ASIS_JAR_PATH" "$APP_DB_USER" "$APP_DB_PASS"
fi

if [[ "$APP_MODE" == "r" || "$APP_MODE" == "m" ]]; then
  execute_restore "$APP_DB_FILE" "$APP_BACKUP_SQL_FILE" "$TOBE_JAR_PATH" "$APP_DB_USER" "$APP_DB_PASS"
fi

# 이관(m) 모드인 경우 중간 생성물 삭제
if [[ "$APP_MODE" == "m" ]]; then
  echo "▶ [MODE: CLEANUP] 이관(migration) 완료에 따른 중간 생성물 삭제..."
  if [ -f "$APP_BACKUP_SQL_FILE" ]; then
    rm -f "$APP_BACKUP_SQL_FILE"
    echo "✅ 중간 백업 파일 삭제 완료: $APP_BACKUP_SQL_FILE"
  fi
fi

echo "🎉 모든 작업($APP_MODE)이 성공적으로 완료되었습니다!"
exit 0
