#!/usr/bin/env bash
# ==============================================================================
# Filename:     tools/bazel_gated_build.sh
# Purpose:      Resource-constrained Bazel orchestration with dynamic profile routing.
# Type:         Executable Script
# Attribution:  fekerr & Gemini (20260703_0920)
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}/deps/litert-lm"

# Read profile argument (defaulting to release if empty)
PROFILE="${1:-release}"

if [ "${PROFILE}" == "debug" ]; then
    BAZEL_MODE="dbg"
    EXPORT_DIR="${REPO_ROOT}/build/litert_debug"
    echo "[+] Profile Target Locked: HEAVY-SYMBOL DEBUG"
else
    BAZEL_MODE="opt"
    EXPORT_DIR="${REPO_ROOT}/build/litert_release"
    echo "[+] Profile Target Locked: OPTIMIZED RELEASE"
fi

# Hard-assign LLVM toolchain isolation to satisfy Clang-specific external configurations
export CC="/usr/bin/clang"
export CXX="/usr/bin/clang++"

echo "[+] Initializing Resource-Gated Bazel Build Flow..."
echo "[+] Target Compiler Forced to LLVM: ${CC}"
echo "[+] Constraint Allocation: 1 Job | 4GB Workers | 1.5GB JVM Daemon Base"

# Execute compilation via the strictly throttled and environment-aware Bazel interface
# Modernized to utilize --local_resources to silence syntax deprecation warnings
bazel --output_base="/home/fekerr/.cache/bazel_irislime" \
      --host_jvm_args="-Xmx1536m" \
      --host_jvm_args="-XX:+UseParallelGC" \
      build //runtime/components/... \
      --symlink_prefix=none \
      --jobs=1 \
      --local_resources=memory=4000 \
      --local_resources=cpu=2 \
      --compilation_mode="${BAZEL_MODE}" \
      --action_env=PATH \
      --action_env=CC \
      --action_env=CXX \
      --repo_env=PATH \
      --repo_env=CC \
      --repo_env=CXX

echo "[✅] Bazel Compilation Sweep Completed Successfully."

# Clean and stage the configuration-accurate export target directory
mkdir -p "${EXPORT_DIR}"
BIN_DIR="$(bazel --output_base="/home/fekerr/.cache/bazel_irislime" info bazel-bin --compilation_mode="${BAZEL_MODE}")"

echo "[+] Conducting forensic asset collection sweep inside: ${BIN_DIR}/runtime/components/"

# Discover and pull every valid compiled binary object while preserving component structure
# This replaces the broken monolithic file contract with a flexible multi-module map
find "${BIN_DIR}/runtime/components/" -type f \( -name "*.so" -o -name "*.a" \) | while read -r asset; do
    REL_PATH="${asset#${BIN_DIR}/runtime/components/}"
    TARGET_DEST="${EXPORT_DIR}/${REL_PATH}"
    
    mkdir -p "$(dirname "${TARGET_DEST}")"
    cp -f "${asset}" "${TARGET_DEST}"
done

echo "[+] Multi-module asset export matrix fully staged inside: ${EXPORT_DIR}/"
echo "FOOTER: Execution of tools/bazel_gated_build.sh completed successfully."
