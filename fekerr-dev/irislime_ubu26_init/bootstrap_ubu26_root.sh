#!/bin/bash
# ==============================================================================
#          STAGE 1 & 2 BOOTSTRAP: SYSTEM IDENTITY & IMMEDIATE AGY ONBOARDING
# ==============================================================================
# Run this script as 'root' inside a freshly deployed, bare Ubuntu 26.04 LXC.
# This prepares the environment for UID/GID 1003 and sets up the agy client.
# ==============================================================================

set -euo pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This bootstrap script must be run as root." >&2
    exit 1
fi

TARGET_USER="fekerr"
TARGET_UID_GID=1003

echo "[+] Step 1: Creating isolated user and group (ID: ${TARGET_UID_GID})..."
if ! getent group "${TARGET_USER}" >/dev/null; then
    groupadd -g "${TARGET_UID_GID}" "${TARGET_USER}"
fi

if ! getent passwd "${TARGET_USER}" >/dev/null; then
    useradd -u "${TARGET_UID_GID}" -g "${TARGET_UID_GID}" -m -s /bin/bash "${TARGET_USER}"
    echo "[+] User '${TARGET_USER}' successfully created with ID ${TARGET_UID_GID}."
else
    echo "[!] User '${TARGET_USER}' already exists."
fi

# Set passwordless sudo privileges for fekerr
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${TARGET_USER}" > /dev/null
chmod 0440 "/etc/sudoers.d/${TARGET_USER}"

echo "[+] Step 2: Preparing secure SSH folder..."
USER_HOME="/home/${TARGET_USER}"
SSH_DIR="${USER_HOME}/.ssh"
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
touch "${SSH_DIR}/authorized_keys"
chmod 600 "${SSH_DIR}/authorized_keys"
chown -R "${TARGET_USER}:${TARGET_USER}" "${SSH_DIR}"

echo "[+] Step 3: Installing essential packages & mapping Neovim..."
apt-get update
apt-get install -y git neovim curl wget gnupg2

# Bind Neovim as system-wide default "vim"
update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
update-alternatives --set vim /usr/bin/nvim

echo "[+] Step 4: Installing Antigravity CLI (agy) immediately..."
su - "${TARGET_USER}" -c "curl -fsSL [https://antigravity.google/cli/install.sh](https://antigravity.google/cli/install.sh) | bash"

echo "[+] Step 5: Configuring system shell paths for '${TARGET_USER}'..."
BASHRC="${USER_HOME}/.bashrc"
if ! grep -q 'export PATH="/home/fekerr/.local/bin:$PATH"' "${BASHRC}"; then
    echo 'export PATH="/home/fekerr/.local/bin:$PATH"' >> "${BASHRC}"
fi

echo "[+] Step 6: Initializing budget-guarded, high-verbosity settings.json..."
CONFIG_DIR="${USER_HOME}/.gemini/antigravity-cli"
mkdir -p "${CONFIG_DIR}"
cat <<'JSON' > "${CONFIG_DIR}/settings.json"
{
  "default_model": "gemini-3.5-flash",
  "verbosity": "high",
  "enableTerminalSandbox": true,
  "artifactReviewPolicy": "asks-for-review",
  "max_parallel_agents": 2,
  "enableTelemetry": true
}
JSON
chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.gemini"

echo "[+] Step 7: Deploying headless browser link-opener bridge (wslview)..."
BRIDGE_PATH="/usr/local/bin/wslview"
cat <<'BRIDGE' > "${BRIDGE_PATH}"
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: wslview <URL>" >&2
    exit 1
fi
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "Start-Process '$1'"
BRIDGE
chmod +x "${BRIDGE_PATH}"

echo "================================================================================"
echo "    BOOTSTRAP COMPLETE. PLEASE EXECUTE THE FOLLOWING AS THE 'fekerr' USER:      "
echo "================================================================================"
echo "    1. su - fekerr"
echo "    2. git config --global user.name 'fekerr'"
echo "    3. git config --global user.email 'fekerr@gmail.com'"
echo "    4. agy login"
echo "    5. Once logged in, run: "
echo "       agy --recipe ~/src/fekerr-dev/irislime_ubu26_init/provision_new_ubu26.agy"
echo "================================================================================"
