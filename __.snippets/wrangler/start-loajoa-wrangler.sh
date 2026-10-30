#!/usr/bin/env bash

# ==============================================================================
# @author: parkjunhong77@gmail.com
# @title: start-loajoa-wrangler.sh
# @license: Apache License 2.0
# @since: 2026-01-05
# @desc: Wrapper script for start-wrangler.sh with predefined Loajoa settings
# @installation: chmod +x start-loajoa-wrangler.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
TARGET_SCRIPT_NAME="start-wrangler.sh"

RUN_DIR="/home/parkjunhong/dev/playground/loajoa/src/by-functions"
PUBLIC_DIR="./public"

# [HTTPS 인증서 경로 설정]
# 예: mkcert로 생성한 파일 경로 (절대 경로 또는 RUN_DIR 기준 상대 경로)
SSL_KEY="/etc/nginx/cert/R3-wildcard.ymtech.co.kr.key"
SSL_CERT="/etc/nginx/cert/R3-wildcard.ymtech.co.kr.crt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Find Target Script
# ------------------------------------------------------------------------------
FINAL_CMD=""

# 1. Check in current directory
if [[ -f "./$TARGET_SCRIPT_NAME" ]]; then
    FINAL_CMD="./$TARGET_SCRIPT_NAME"
    [[ ! -x "$FINAL_CMD" ]] && chmod +x "$FINAL_CMD"

# 2. Check in system PATH
elif command -v "$TARGET_SCRIPT_NAME" >/dev/null 2>&1; then
    FINAL_CMD=$(command -v "$TARGET_SCRIPT_NAME")

else
    echo -e "${RED}Error: Cannot find '$TARGET_SCRIPT_NAME'.${NC}"
    exit 1
fi

echo -e "${GREEN}Found script: $FINAL_CMD${NC}"

# ------------------------------------------------------------------------------
# Execute
# ------------------------------------------------------------------------------
echo "Starting Loajoa Wrangler..."
echo "  Run Dir: $RUN_DIR"
echo "  Public : $PUBLIC_DIR"

echo "Starting Loajoa Wrangler (HTTPS)..."

"$FINAL_CMD" \
    --run-dir "$RUN_DIR" \
    --public-dir "$PUBLIC_DIR" \
    --ssl-key "$SSL_KEY" \
    --ssl-cert "$SSL_CERT"

exit 0
