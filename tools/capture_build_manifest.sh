#!/bin/bash
# tools/capture_build_manifest.sh
# Capture build assumptions and environment into the build tree.
# Usage: ./tools/capture_build_manifest.sh <build_dir> <target> <cmake_flags> [build_log]

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <build_dir> <target> <cmake_flags> [build_log]"
    exit 1
fi

BUILD_DIR="$1"
TARGET="$2"
CMAKE_FLAGS="$3"
BUILD_LOG="${4:-}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORENSICS_DIR="$BUILD_DIR/forensics"
mkdir -p "$FORENSICS_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
MANIFEST="$FORENSICS_DIR/build_manifest_${TS}.txt"
LATEST="$FORENSICS_DIR/build_manifest_latest.txt"
INDEX="$FORENSICS_DIR/build_manifest_index.csv"

GIT_BRANCH="$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
GIT_HEAD="$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
GIT_DIRTY="$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

CMAKE_CACHE_FILE="$BUILD_DIR/CMakeCache.txt"
if [[ -f "$CMAKE_CACHE_FILE" ]]; then
    CMAKE_CACHE_SHA256="$(sha256sum "$CMAKE_CACHE_FILE" | awk '{print $1}')"
else
    CMAKE_CACHE_SHA256="missing"
fi

{
    echo "build_timestamp_iso=$(date -Iseconds)"
    echo "build_timestamp_unix=$(date +%s)"
    echo "project_root=$PROJECT_ROOT"
    echo "target=$TARGET"
    echo "build_dir=$BUILD_DIR"
    echo "build_log=${BUILD_LOG:-none}"
    echo "cmake_flags=$CMAKE_FLAGS"
    echo "git_branch=$GIT_BRANCH"
    echo "git_head=$GIT_HEAD"
    echo "git_dirty_file_count=$GIT_DIRTY"
    echo "cmake_cache_file=$CMAKE_CACHE_FILE"
    echo "cmake_cache_sha256=$CMAKE_CACHE_SHA256"
    echo "compiler_c=$(command -v icx || command -v cc || echo missing)"
    echo "compiler_cxx=$(command -v icpx || command -v c++ || echo missing)"
    echo "cmake_path=$(command -v cmake || echo missing)"
    echo "make_path=$(command -v make || echo missing)"
    echo "python_path=$(command -v python3 || echo missing)"
    echo "nproc=$(nproc 2>/dev/null || echo unknown)"
    echo "kernel=$(uname -srmo)"
    echo "hostname=$(hostname)"
    echo "IRISLIME_READY=${IRISLIME_READY:-unset}"
    echo "ONEAPI_ROOT=${ONEAPI_ROOT:-unset}"
    echo "MKLROOT=${MKLROOT:-unset}"
    echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-unset}"
    echo "assumptions=source config_env loaded; compilers available; build validated by llama-cli --list-devices"
} > "$MANIFEST"

cp "$MANIFEST" "$LATEST"

if [[ ! -f "$INDEX" ]]; then
    echo "timestamp,target,git_head,cmake_cache_sha256,manifest_path,build_log" > "$INDEX"
fi

echo "$TS,$TARGET,$GIT_HEAD,$CMAKE_CACHE_SHA256,$MANIFEST,${BUILD_LOG:-none}" >> "$INDEX"

echo "[+] Build manifest captured: $MANIFEST"
echo "[+] Build manifest index: $INDEX"
