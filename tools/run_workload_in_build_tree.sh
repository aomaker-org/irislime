#!/bin/bash
# tools/run_workload_in_build_tree.sh
# Execute a workload against a chosen build target and store logs/metadata in that build tree.
# Usage:
#   ./tools/run_workload_in_build_tree.sh --target sycl_release --device cpu --model models/foo.gguf --prompt "hello" --n-predict 32

set -euo pipefail

TARGET="sycl_release"
DEVICE="cpu"
MODEL=""
PROMPT="smoke"
N_PREDICT="16"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --device) DEVICE="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --n-predict) N_PREDICT="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [[ -z "$MODEL" ]]; then
    echo "[!] --model is required"
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/$TARGET"
CLI="$BUILD_DIR/bin/llama-cli"

if [[ ! -x "$CLI" ]]; then
    echo "[!] Missing executable: $CLI"
    echo "[*] Build first with: make build TARGET=$TARGET"
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/$MODEL" && ! -f "$MODEL" ]]; then
    echo "[!] Model not found: $MODEL"
    exit 1
fi

if [[ -f "$MODEL" ]]; then
    MODEL_PATH="$MODEL"
else
    MODEL_PATH="$PROJECT_ROOT/$MODEL"
fi

TS="$(date +%Y%m%d_%H%M%S)"
RUN_ROOT="$BUILD_DIR/forensics/workloads"
mkdir -p "$RUN_ROOT"

MODEL_BASE="$(basename "$MODEL_PATH" .gguf)"
RUN_ID="${TS}_${TARGET}_${DEVICE}_${MODEL_BASE}"
LOG_FILE="$RUN_ROOT/${RUN_ID}.log"
META_FILE="$RUN_ROOT/${RUN_ID}.meta"

{
    echo "run_id=$RUN_ID"
    echo "timestamp_iso=$(date -Iseconds)"
    echo "target=$TARGET"
    echo "device=$DEVICE"
    echo "build_dir=$BUILD_DIR"
    echo "cli=$CLI"
    echo "model=$MODEL_PATH"
    echo "prompt=$PROMPT"
    echo "n_predict=$N_PREDICT"
    echo "git_head=$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
    echo "git_branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
    echo "ONEAPI_ROOT=${ONEAPI_ROOT:-unset}"
    echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-unset}"
} > "$META_FILE"

set +e
"$CLI" \
  --model "$MODEL_PATH" \
  --prompt "$PROMPT" \
  --n-predict "$N_PREDICT" \
  --device "$DEVICE" \
  2>&1 | tee "$LOG_FILE"
EC=${PIPESTATUS[0]}
set -e

echo "exit_code=$EC" >> "$META_FILE"

echo "[+] Workload log: $LOG_FILE"
echo "[+] Workload meta: $META_FILE"
echo "[+] Exit code: $EC"

exit "$EC"
