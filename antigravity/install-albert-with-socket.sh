#!/usr/bin/env bash

set -euo pipefail

REPO_BASE="https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_26.04"
KEYRING="/etc/apt/keyrings/albert.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/albert.list"

LOCAL_BIN="${HOME}/.local/bin"
TOGGLE_SCRIPT="${LOCAL_BIN}/albert-toggle"

echo "========================================"
echo " Albert Installer for Ubuntu 26.04"
echo " OBS Repository + IPC Socket Toggle"
echo "========================================"
echo

echo "[1/7] Installing required packages..."
sudo apt update
sudo apt install -y curl ca-certificates gnupg socat

echo
echo "[2/7] Installing repository signing key..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL "${REPO_BASE}/Release.key" \
    | sudo gpg --dearmor --yes -o "${KEYRING}"

echo
echo "[3/7] Adding Albert OBS repository..."
echo "deb [signed-by=${KEYRING}] ${REPO_BASE}/ /" \
    | sudo tee "${SOURCE_LIST}" >/dev/null

echo
echo "[4/7] Updating package information..."
sudo apt update

echo
echo "[5/7] Installing Albert..."
sudo apt install -y albert

echo
echo "[6/7] Creating Albert IPC socket toggle command..."
mkdir -p "${LOCAL_BIN}"

cat > "${TOGGLE_SCRIPT}" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

SOCKET="${XDG_CACHE_HOME:-${HOME}/.cache}/albert/ipc_socket"

# Albert가 실행 중이고 IPC socket이 존재하면 직접 toggle 명령을 전달한다.
if [[ -S "${SOCKET}" ]]; then
    printf '["toggle"]' | socat - "UNIX-CONNECT:${SOCKET}"
    exit 0
fi

# Albert가 아직 실행되지 않았거나 socket이 준비되지 않은 경우 fallback.
exec /usr/bin/albert toggle
EOF

chmod +x "${TOGGLE_SCRIPT}"

echo
echo "[7/7] Verifying installation..."

echo
echo "Albert version:"
albert --version || true

echo
echo "socat:"
socat -V 2>/dev/null | head -n 1 || true

echo
echo "Toggle command:"
echo "  ${TOGGLE_SCRIPT}"

echo
echo "========================================"
echo " Albert installation completed."
echo "========================================"
echo
echo "Run Albert once:"
echo
echo "  /usr/bin/albert"
echo
echo "After the Albert tray icon appears, configure the GNOME shortcut."
echo
echo "------------------------------------------------------------"
echo " GNOME Custom Shortcut (Wayland)"
echo "------------------------------------------------------------"
echo
echo " Settings"
echo "   -> Keyboard"
echo "   -> View and Customize Shortcuts"
echo "   -> Custom Shortcuts"
echo "   -> Add Shortcut"
echo
echo " Name:"
echo "   Albert"
echo
echo " Command:"
echo "   ${TOGGLE_SCRIPT}"
echo
echo " Shortcut:"
echo "   Alt + Space"
echo
echo "------------------------------------------------------------"
echo
echo "If Alt + Space is already assigned to the GNOME window menu,"
echo "check it with:"
echo
echo "  gsettings get org.gnome.desktop.wm.keybindings activate-window-menu"
echo
echo "If the result contains '<Alt>space', release it with:"
echo
echo "  gsettings set org.gnome.desktop.wm.keybindings activate-window-menu \"[]\""
echo
echo "Test the IPC toggle command manually with:"
echo
echo "  ${TOGGLE_SCRIPT}"
echo
