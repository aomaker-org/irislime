#!/usr/bin/env bash
# ==============================================================================
# PATH:        irislime_ubu26_init/provision_user.sh
# PURPOSE:     Phase 1 Root Provisioning. Creates isolation user 1004, configures
#              dynamic sudo privileges, and prepares Git environment keys.
# TARGET:      Ubuntu 26.04 LTS Container / WSL2 Bare Instance
# LINEAGE:     fekerr-dev / System Setup
# UPDATED:     20260715_143500
# Integrity-Hash: 1f0146aac7b6b4bc5680fb6637063cf551a30121ec8c4ab512db74cb44120cad
# ==============================================================================

# Ensure script runs with root authority
if [ "$EUID" -ne 0 ]; then
    echo "[!] Error: This script must be run as root or with sudo." >&2
    exit 1
fi

LOG_FILE="/var/log/fekerr_provision_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -ia "${LOG_FILE}") 2>&1

echo "================================================================================"
echo "          INITIATING PHASE 1 PROVISIONING FOR ISO-USER 1004"
echo "================================================================================"
echo "[*] Log stream writing to: ${LOG_FILE}"

# 1. User Creation (UID 1004)
TARGET_USER="fekerr_1004"
if id "${TARGET_USER}" >/dev/null 2>&1; then
    echo "[!] Target user '${TARGET_USER}' already exists. Skipping user creation."
else
    echo "[*] Creating system user '${TARGET_USER}' with UID 1004..."
    useradd -u 1004 -m -s /bin/bash "${TARGET_USER}"
    # Assign temp default password
    echo "${TARGET_USER}:fekerr1004!" | chpasswd
fi

# 2. Dynamic Sudo Password Enforcement Mode
# Toggle variable: 1 for NOPASSWD (Passwordless), 0 for standard Password Prompts
ENFORCE_PASSWORDLESS_SUDO=1

SUDO_CONFIG_FILE="/etc/sudoers.d/99-fekerr-dev"
if [ "${ENFORCE_PASSWORDLESS_SUDO}" -eq 1 ]; then
    echo "[*] Enabling PASSWORDLESS sudo for '${TARGET_USER}'..."
    # We pipe cleanly through a temp file and validate with visudo to avoid corruption
    echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "${SUDO_CONFIG_FILE}.tmp"
else
    echo "[*] Enabling PASSWORD-REQUIRED standard sudo for '${TARGET_USER}'..."
    echo "${TARGET_USER} ALL=(ALL) ALL" > "${SUDO_CONFIG_FILE}.tmp"
fi

# Validate sudo file structure
visudo -cf "${SUDO_CONFIG_FILE}.tmp"
if [ $? -eq 0 ]; then
    mv "${SUDO_CONFIG_FILE}.tmp" "${SUDO_CONFIG_FILE}"
    chmod 0440 "${SUDO_CONFIG_FILE}"
    echo "[+] Sudo file verified and locked."
else
    echo "[!] Error: Invalid sudo configuration generated. Aborting." >&2
    rm -f "${SUDO_CONFIG_FILE}.tmp"
    exit 1
fi

# 3. Base SSH Scaffolding Setup
USER_HOME="/home/${TARGET_USER}"
SSH_DIR="${USER_HOME}/.ssh"
echo "[*] Setting up secure SSH directories in ${SSH_DIR}..."
mkdir -p "${SSH_DIR}"
chmod 0700 "${SSH_DIR}"
touch "${SSH_DIR}/authorized_keys"
chmod 0600 "${SSH_DIR}/authorized_keys"

# 4. Standard System Package Provisioning
echo "[*] Upgrading package mirrors and deploying base systems..."
apt-get update
apt-get install -y git curl python3-pip python3-venv rsync build-essential

# 5. Establish Workspace Directory Structures
mkdir -p "${USER_HOME}/src"
chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}"

echo "[+] Phase 1 user provisioning successfully completed!"
echo "    Switch to your new user space to complete onboarding: 'su - ${TARGET_USER}'"
echo "================================================================================"

# Integrity-Hash: 1f0146aac7b6b4bc5680fb6637063cf551a30121ec8c4ab512db74cb44120cad
# EOF:         irislime_ubu26_init/provision_user.sh
# ==============================================================================
