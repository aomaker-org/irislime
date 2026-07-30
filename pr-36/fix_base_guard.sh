#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[+] Stripping BASE_MK_INCLUDED guard from infra/make/base.mk..."

# Remove BASE_MK_INCLUDED header and footer lines from base.mk
sed -i '/BASE_MK_INCLUDED/d' infra/make/base.mk

git add infra/make/base.mk
echo "[+] base.mk target declarations restored."
