#!/usr/bin/env bash

set -euo pipefail

REPO_BASE="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_26.04"
KEYRING="/etc/apt/keyrings/albert.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/albert.list"

echo "========================================"
echo " Albert Installer for Ubuntu 26.04"
echo "========================================"

echo "[1/5] Installing required packages..."
sudo apt update
sudo apt install -y curl ca-certificates gnupg

echo "[2/5] Installing repository signing key..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL "${REPO_BASE}/Release.key" \
    | sudo gpg --dearmor --yes -o "${KEYRING}"

echo "[3/5] Adding Albert OBS repository..."
echo "deb [signed-by=${KEYRING}] ${REPO_BASE}/ /" \
    | sudo tee "${SOURCE_LIST}" >/dev/null

echo "[4/5] Updating package information..."
sudo apt update

echo "[5/5] Installing Albert..."
sudo apt install -y albert

echo
echo "========================================"
echo " Albert installation completed."
echo "========================================"
echo
echo "Version:"
albert --version || true

echo
echo "Run:"
echo "  albert"
