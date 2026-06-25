#!/usr/bin/env bash
# ==============================================================================
# 20260623 fekerr & gemini | IRISLIME AUTOMATION SUITE
# FILE: tools/build_openvino.sh
# CONFIG: Resilient logging with guaranteed host clipboard tracking
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/logs"

mkdir -p "$LOGS_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M")
LOG_FILE="$LOGS_DIR/build_openvino_${TIMESTAMP}.log"

# Setup an independent stdout channel descriptor
exec 3>&1

echo "============================================================"
echo "🔨 STARTING ATOMIC BUILD RUN: ${TIMESTAMP}"
echo "PROJECT ROOT: $PROJECT_ROOT"
echo "============================================================"

# Define a teardown function that guarantees log archival and clipboard replication
cleanup_and_clip() {
    local exit_code=$?
    
    # Append execution signature summary block straight to log target
    if [ $exit_code -eq 0 ]; then
        echo -e "\n🟢 BUILD SUCCESS" >> "$LOG_FILE"
    else
        echo -e "\n🔴 BUILD FAILED (Exit Code: $exit_code)" >> "$LOG_FILE"
    fi
    
    # Guaranteed delivery to host clipboard infrastructure
    if command -v clip.exe >/dev/null 2>&1; then
        cat "$LOG_FILE" | clip.exe
        echo "📋 Telemetry profile successfully dispatched via clip.exe!"
    else
        echo "⚠️ clip.exe bypassed (Not in path framework)."
    fi
    
    # Return cleanly back to the parent folder stack boundary
    cd "$PROJECT_ROOT"
}

# Attach the validation routine to the shell script exit trap event
trap cleanup_and_clip EXIT

# Run configuration and compilation inside a captured execution block
{
    mkdir -p "$PROJECT_ROOT/build/openvino_release"
    cd "$PROJECT_ROOT/build/openvino_release"

    # Standard clean build definitions, now insulated from header version drifting
    cmake -DLLAMA_OPENVINO=ON \
          -DOpenVINO_DIR=/home/fekerr/src/openvino/build/ \
          "$PROJECT_ROOT/llama.cpp"

    echo "============================================================"
    echo "🚀 RUNNING COMPILATION PASS..."
    echo "============================================================"
    make -j$(nproc)

    echo "============================================================"
    echo "🎯 OPENVINO BACKEND COMPILED SUCCESSFULLY"
    echo "============================================================"
} 2>&1 | tee "$LOG_FILE" >&3

# END FILE: tools/build_openvino.sh
