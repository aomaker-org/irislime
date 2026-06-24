#!/usr/bin/env bash
# /* 20260624 Copilot | tiny-model CPU-safe launcher to bypass BF16/GPU instability */

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -f config_env ]]; then
    # shellcheck disable=SC1091
    set +u
    source config_env || true
    set -u
fi

LOG_DIR="$PROJECT_ROOT/logs/test"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/tiny_q2_cpu_safe_${TS}.log"

CLI="$PROJECT_ROOT/build/cpu_release/bin/llama-cli"
if [[ ! -x "$CLI" ]]; then
    echo "[!] Missing CPU llama-cli: $CLI"
    exit 2
fi

# Prefer the smallest tinyllama quant available, otherwise fallback to the smallest gguf file.
MODEL=""
if ls "$PROJECT_ROOT"/models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf >/dev/null 2>&1; then
    MODEL="$PROJECT_ROOT/models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
else
    MODEL="$(find "$PROJECT_ROOT/models" -maxdepth 1 -type f -name '*.gguf' -printf '%s %p\n' | sort -n | head -1 | awk '{print $2}')"
fi

if [[ -z "$MODEL" || ! -f "$MODEL" ]]; then
    echo "[!] No GGUF model found in $PROJECT_ROOT/models"
    exit 3
fi

PROMPT="${1:-Write one short sentence about stable CPU inference.}"

{
    echo "============================================================"
    echo "TINY MODEL CPU SAFE RUN"
    echo "timestamp: $(date -Iseconds)"
    echo "model: $MODEL"
    echo "binary: $CLI"
    echo "prompt: $PROMPT"
    echo "strategy: force CPU path (--n-gpu-layers 0) to avoid BF16/GPU path instability"
    echo "============================================================"
    echo ""
} | tee "$LOG_FILE"

set +e
timeout --signal=KILL 60s \
    stdbuf -oL -eL \
    "$CLI" \
    --model "$MODEL" \
    --conversation \
    --simple-io \
    --n-predict 32 \
    --ctx-size 256 \
    --n-gpu-layers 0 \
    < <(printf '%s\n/exit\n' "$PROMPT") \
    2>&1 | tee -a "$LOG_FILE"
RC=${PIPESTATUS[0]}
set -e

if [[ $RC -eq 0 ]]; then
    echo "[+] PASS: CPU-safe tiny-model inference succeeded" | tee -a "$LOG_FILE"
elif [[ $RC -eq 124 || $RC -eq 137 ]]; then
    echo "[!] TIMEOUT: CPU-safe run timed out" | tee -a "$LOG_FILE"
else
    echo "[!] FAIL: CPU-safe run failed with exit code $RC" | tee -a "$LOG_FILE"
fi

echo "log_file: ${LOG_FILE#$PROJECT_ROOT/}" | tee -a "$LOG_FILE"
exit "$RC"
