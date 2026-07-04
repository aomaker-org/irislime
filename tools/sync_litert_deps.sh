#!/usr/bin/env bash
# Header Block
# Filename:     infra/scripts/sync_litert_deps.sh
# Purpose:      Recursively initialize and sync nested LiteRT-LM submodules to restore missing runtime directories.
# Type:         Executable
# Attribution:  Gemini & fekerr (20260702_1513)
# Timestamp:    20260702_1513

set -euo pipefail

echo "[+] Initializing top-level and nested submodules for litert-lm..."

# Ensure we are in the repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# Force recursive initialization on the specific target dependency path
git submodule update --init --recursive deps/litert-lm

echo "[+] Verifying target directories..."
if [ -d "deps/litert-lm/runtime/components/constrained_decoding" ] && \
   [ -f "deps/litert-lm/runtime/components/preprocessor/CMakeLists.txt" ]; then
    echo "[✅] Structure Validated: All LiteRT components are present."
else
    echo "[❌] Structure Fault: Submodules failed to fully populate. Check upstream git connectivity."
    exit 1
fi

# Footer Block
echo "FOOTER: Execution of sync_litert_deps.sh completed successfully."
