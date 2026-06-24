#!/usr/bin/env bash
# /* 20260624 copilot | OpenVINO-only healthcheck with forensic logs (CLI + VS Code task friendly) */

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
LOG_FILE="$LOG_DIR/openvino_healthcheck_${TS}.log"

MODEL="${1:-$PROJECT_ROOT/models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf}"
PROMPT="${PROMPT:-OpenVINO healthcheck prompt.}"
TIMEOUT_SEC="${TIMEOUT_SEC:-45}"
OPENVINO_DEVICE="${GGML_OPENVINO_DEVICE:-GPU}"
OPENVINO_DISABLE_CACHE="${GGML_OPENVINO_DISABLE_CACHE:-1}"
BIN="$PROJECT_ROOT/build/openvino_release/bin/llama-cli"

if [[ ! -f "$MODEL" ]]; then
    echo "[!] Missing model: $MODEL"
    exit 2
fi

if [[ ! -x "$BIN" ]]; then
    echo "[!] Missing OpenVINO llama-cli: $BIN"
    exit 3
fi

{
    echo "============================================================"
    echo "OPENVINO HEALTHCHECK"
    echo "timestamp: $(date -Iseconds)"
    echo "model: $MODEL"
    echo "binary: $BIN"
    echo "openvino_device: $OPENVINO_DEVICE"
    echo "openvino_disable_cache: $OPENVINO_DISABLE_CACHE"
    echo "timeout_sec: $TIMEOUT_SEC"
    echo "============================================================"
    echo ""
} | tee "$LOG_FILE"

set +e
GGML_OPENVINO_DEVICE="$OPENVINO_DEVICE" \
GGML_OPENVINO_DISABLE_CACHE="$OPENVINO_DISABLE_CACHE" \
    timeout --signal=KILL "${TIMEOUT_SEC}s" \
    stdbuf -oL -eL \
    "$BIN" \
    --model "$MODEL" \
    --conversation \
    --single-turn \
    --simple-io \
    --n-predict 1 \
    --n-gpu-layers 99 \
    < <(printf '%s\n/exit\n' "$PROMPT") \
    2>&1 | tee -a "$LOG_FILE"
RC=${PIPESTATUS[0]}
set -e

if grep -E "ov::Exception|Compute error|failed to decode|graph_compute: .*failed|GGML OpenVINO backend" "$LOG_FILE" >/dev/null 2>&1; then
    if [[ $RC -eq 0 ]]; then
        RC=10
    fi
fi

if [[ $RC -eq 0 ]]; then
    echo "[+] OPENVINO HEALTHCHECK PASS" | tee -a "$LOG_FILE"
elif [[ $RC -eq 124 || $RC -eq 137 ]]; then
    echo "[!] OPENVINO HEALTHCHECK TIMEOUT" | tee -a "$LOG_FILE"
else
    echo "[!] OPENVINO HEALTHCHECK FAIL (exit=$RC)" | tee -a "$LOG_FILE"
fi

echo "log_file: logs/test/$(basename "$LOG_FILE")" | tee -a "$LOG_FILE"
exit "$RC"
