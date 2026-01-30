#!/bin/bash

# ==============================================================================
# Script Name: init-wrangler-d1.sh
# Description: Initialize Cloudflare D1 Database or Migrate Data
# Author: parkjunhong77@gmail.com
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Variables & Constants
# ------------------------------------------------------------------------------
RUN_DIR=""
D1_LOCATION=""
D1_SCHEMA=""
D1_FILE=""

# 텍스트 컬러
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# 2. Helper Functions
# ------------------------------------------------------------------------------

help() {
    echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Required Parameters:${NC}"
    echo -e "  -d, --run-dir <dir>      Directory where the command executes"
    echo -e "      --d1-schema <name>   D1 Database name (e.g., loajoa_db)"
    echo -e "      --d1-file <file>     SQL Schema file path (Required unless location is 'migration')"
    echo ""
    echo -e "${YELLOW}Optional Parameters:${NC}"
    echo -e "  -l, --d1-location <type> Target D1 location. Values: [local | remote | all | migration] (Default: Interactive)"
    echo -e "                           * migration: Backup remote schema & data to local run-dir"
    echo -e "  -h, --help               Show this help message"
    echo ""
}

error_exit() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

run_wrangler() {
    local LOC=$1
    echo -e "${GREEN}Executing D1 schema on [${LOC}]...${NC}"
    
    if [ "$LOC" == "local" ]; then
        npx wrangler d1 execute "$D1_SCHEMA" --local --file="$D1_FILE"
    else
        npx wrangler d1 execute "$D1_SCHEMA" --remote --file="$D1_FILE"
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to execute on [${LOC}]${NC}"
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# 3. Parse Arguments
# ------------------------------------------------------------------------------

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--run-dir) RUN_DIR="$2"; shift ;;
        -l|--d1-location) D1_LOCATION="$2"; shift ;;
        --d1-schema) D1_SCHEMA="$2"; shift ;;
        --d1-file) D1_FILE="$2"; shift ;;
        -h|--help) help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; help; exit 1 ;;
    esac
    shift
done

# ------------------------------------------------------------------------------
# 4. Validation
# ------------------------------------------------------------------------------

# [필수] Run Directory
if [ -z "$RUN_DIR" ]; then
    error_exit "Run directory (-d) is required."
fi

# 절대 경로 변환 (Run Directory)
if [[ "$RUN_DIR" != /* ]]; then
    ABS_RUN_DIR="$(pwd)/$RUN_DIR"
else
    ABS_RUN_DIR="$RUN_DIR"
fi

if [ ! -d "$ABS_RUN_DIR" ]; then
    error_exit "Run directory does not exist: $ABS_RUN_DIR"
fi

# [필수] D1 Schema Name
if [ -z "$D1_SCHEMA" ]; then
    error_exit "D1 Schema Name (--d1-schema) is required."
fi

# [선택] D1 Location (Interactive)
# 파일 검증 전에 Location을 먼저 확정해야 함 (migration 모드 여부 확인 위해)
if [ -z "$D1_LOCATION" ]; then
    echo -e "${YELLOW}Target location not specified.${NC}"
    read -p "Select D1 location (local/remote/all/migration) [default: local]: " USER_INPUT
    D1_LOCATION=${USER_INPUT:-local}
fi

# Location 값 검증 (local, remote, all, migration)
if [[ ! "$D1_LOCATION" =~ ^(local|remote|all|migration)$ ]]; then
    error_exit "Invalid location '$D1_LOCATION'. Allowed values: [local | remote | all | migration]"
fi

# [조건부 필수] D1 Schema File
# 'migration' 모드가 아닐 때만 Schema 파일이 필수
if [ "$D1_LOCATION" != "migration" ]; then
    if [ -z "$D1_FILE" ]; then
        error_exit "D1 Schema File (--d1-file) is required for '${D1_LOCATION}' mode."
    fi

    # 파일 경로 처리
    if [[ "$D1_FILE" != /* ]]; then
        ABS_D1_FILE="${ABS_RUN_DIR}/${D1_FILE}"
    else
        ABS_D1_FILE="$D1_FILE"
    fi

    if [ ! -f "$ABS_D1_FILE" ]; then
        error_exit "D1 Schema File not found at: $ABS_D1_FILE\nExpected inside: ${ABS_RUN_DIR}"
    fi
else
    # Migration 모드일 경우 파일 입력이 없으므로 정보 표시용 텍스트 설정
    ABS_D1_FILE="(Not Required for Migration)"
fi

# ------------------------------------------------------------------------------
# 5. Execution
# ------------------------------------------------------------------------------

echo -e "--------------------------------------------------"
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Run Directory : $ABS_RUN_DIR"
echo -e "  Database      : $D1_SCHEMA"
echo -e "  Schema File   : $ABS_D1_FILE"
echo -e "  Target        : $D1_LOCATION"
echo -e "--------------------------------------------------"

pushd "$ABS_RUN_DIR" > /dev/null || error_exit "Failed to change directory"

FINAL_EXIT_CODE=0

if [ "$D1_LOCATION" == "migration" ]; then
    # --------------------------------------------------
    # Migration Mode (Remote -> Local Backup)
    # --------------------------------------------------
    TIMESTAMP=$(date +%Y%m%d%H%M)
    BACKUP_FILENAME="${D1_SCHEMA}-backup-${TIMESTAMP}.sql"
    
    echo -e "${GREEN}Starting migration (Export Remote to Local)...${NC}"
    echo -e "Output File: ${BACKUP_FILENAME}"
    
    # npx wrangler d1 export 실행
    npx wrangler d1 export "$D1_SCHEMA" --remote --output="./${BACKUP_FILENAME}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Migration successful! File saved to: ${ABS_RUN_DIR}/${BACKUP_FILENAME}${NC}"
        FINAL_EXIT_CODE=0
    else
        echo -e "${RED}Migration failed.${NC}"
        FINAL_EXIT_CODE=1
    fi

elif [ "$D1_LOCATION" == "all" ]; then
    # local 실행
    run_wrangler "local"
    if [ $? -eq 0 ]; then
        # local 성공 시 remote 실행
        run_wrangler "remote"
        FINAL_EXIT_CODE=$?
    else
        FINAL_EXIT_CODE=1
    fi

else
    # local 또는 remote 단일 실행
    run_wrangler "$D1_LOCATION"
    FINAL_EXIT_CODE=$?
fi

popd > /dev/null

if [ $FINAL_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Operation completed successfully.${NC}"
else
    echo -e "${RED}Operation failed.${NC}"
fi

exit $FINAL_EXIT_CODE

