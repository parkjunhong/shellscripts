#!/bin/bash

# ==============================================================================
# Script Name: init-wrangler-d1.sh
# Description: Initialize Cloudflare D1 Database with strict validation
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
    echo -e "      --d1-file <file>     SQL Schema file path"
    echo ""
    echo -e "${YELLOW}Optional Parameters:${NC}"
    echo -e "  -l, --d1-location <type> Target D1 location. Values: [local | remote | all] (Default: Interactive)"
    echo -e "  -h, --help               Show this help message"
    exit 0
}

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# 절대 경로 변환 함수
get_abs_path() {
    local path="$1"
    if [ -e "$path" ]; then
        # 파일이 존재하는 디렉토리로 이동하여 PWD 확인
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    else
        echo "$path"
    fi
}

# 실제 npx 명령어를 실행하는 내부 함수
run_wrangler() {
    local target=$1
    echo -e "🚀 Executing Wrangler D1 command for [${BLUE}$target${NC}]..."
    npx wrangler d1 execute "$D1_SCHEMA" --"$target" --file="$ABS_D1_FILE"
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✅ Success: D1 initialization completed on $target.${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed: Wrangler command failed on $target.${NC}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. Argument Parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--run-dir)       RUN_DIR="$2"; shift 2 ;;
        -l|--d1-location)   D1_LOCATION="$2"; shift 2 ;;
        --d1-schema)        D1_SCHEMA="$2"; shift 2 ;;
        --d1-file)          D1_FILE="$2"; shift 2 ;;
        -h|--help)          help ;;
        *)                  error_exit "Unknown parameter: $1" ;;
    esac
done

# ------------------------------------------------------------------------------
# 4. Validation & Interactive Logic
# ------------------------------------------------------------------------------

# [필수 1] Run Directory
if [ -z "$RUN_DIR" ] || [ ! -d "$RUN_DIR" ]; then
    error_exit "Valid --run-dir (-d) is required."
fi
# 실행 디렉토리를 먼저 절대 경로로 변환 (파일 검증 시 사용)
ABS_RUN_DIR=$(cd "$RUN_DIR" && pwd)

# [필수 2] D1 Schema
if [ -z "$D1_SCHEMA" ]; then
    error_exit "--d1-schema parameter is required."
fi

# [필수 3] D1 File (개선된 검증 로직)
if [ -z "$D1_FILE" ]; then
    error_exit "--d1-file parameter is required."
fi

# 파일 경로 확인 로직
# Case A: 입력된 경로가 (현재 위치 기준) 존재할 때
if [ -f "$D1_FILE" ]; then
    ABS_D1_FILE=$(get_abs_path "$D1_FILE")

# Case B: 입력된 경로가 --run-dir 기준으로 존재할 때
elif [ -f "${ABS_RUN_DIR}/${D1_FILE}" ]; then
    # 경로를 결합하여 절대 경로 추출
    ABS_D1_FILE=$(get_abs_path "${ABS_RUN_DIR}/${D1_FILE}")

# Case C: 파일 찾기 실패
else
    echo -e "${RED}Error: Cannot find schema file '${D1_FILE}'${NC}"
    echo -e "  Checked locations:"
    echo -e "  1. Current Dir : $(pwd)/${D1_FILE}"
    echo -e "  2. Run Dir     : ${ABS_RUN_DIR}/${D1_FILE}"
    exit 1
fi

# [선택] D1 Location (Interactive)
if [ -z "$D1_LOCATION" ]; then
    echo -e "${YELLOW}Target location not specified.${NC}"
    read -p "Select D1 location (local/remote/all) [default: local]: " USER_INPUT
    D1_LOCATION=${USER_INPUT:-local}
fi

# Location 값 검증 (local, remote, all)
if [[ ! "$D1_LOCATION" =~ ^(local|remote|all)$ ]]; then
    error_exit "Invalid location '$D1_LOCATION'. Allowed values: [local | remote | all]"
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

if [ "$D1_LOCATION" == "all" ]; then
    # local 실행
    run_wrangler "local"
    if [ $? -eq 0 ]; then
        # local 성공 시 remote 실행
        run_wrangler "remote"
        FINAL_EXIT_CODE=$?
    else
        FINAL_EXIT_CODE=1
        echo -e "${RED}⚠️  Remote execution skipped due to local failure.${NC}"
    fi
else
    # 단일 대상 실행
    run_wrangler "$D1_LOCATION"
    FINAL_EXIT_CODE=$?
fi

popd > /dev/null
exit $FINAL_EXIT_CODE

