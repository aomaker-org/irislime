#!/usr/bin/env bash
# /* 20260624 Copilot | multi-mode llama.cpp runner with robust non-interactive capture */

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -f config_env ]]; then
    # shellcheck disable=SC1091
    set +u
    source config_env || true
    set -u
fi

MODEL_PATH="${1:-$PROJECT_ROOT/models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf}"
PROMPT="${PROMPT:-The quick brown fox jumps over the lazy dog.}"
N_PREDICT="${N_PREDICT:-16}"
TIMEOUT_SEC="${TIMEOUT_SEC:-45}"
INPUT_LINE_1="${INPUT_LINE_1:-$PROMPT}"

LOG_DIR="$PROJECT_ROOT/logs/test"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
SUMMARY_LOG="$LOG_DIR/llama_multi_capture_${TS}.log"

if [[ ! -f "$MODEL_PATH" ]]; then
    echo "[!] Model not found: $MODEL_PATH"
    exit 2
fi

echo "============================================================" | tee "$SUMMARY_LOG"
echo "LLAMA MULTI CAPTURE RUN" | tee -a "$SUMMARY_LOG"
echo "timestamp: $(date -Iseconds)" | tee -a "$SUMMARY_LOG"
echo "model: $MODEL_PATH" | tee -a "$SUMMARY_LOG"
echo "prompt: $PROMPT" | tee -a "$SUMMARY_LOG"
echo "n_predict: $N_PREDICT" | tee -a "$SUMMARY_LOG"
echo "timeout_sec: $TIMEOUT_SEC" | tee -a "$SUMMARY_LOG"
echo "============================================================" | tee -a "$SUMMARY_LOG"
echo "" | tee -a "$SUMMARY_LOG"

echo "| Method | Status | Exit | Log |" | tee -a "$SUMMARY_LOG"
echo "| :--- | :--- | :--- | :--- |" | tee -a "$SUMMARY_LOG"

detect_sycl_device() {
    local sycl_bin="$PROJECT_ROOT/build/sycl_release/bin/llama-cli"
    if [[ ! -x "$sycl_bin" ]]; then
        return 0
    fi

    # --list-devices emits tokens like SYCL0, SYCL1; pick the first one.
    "$sycl_bin" --list-devices 2>/dev/null \
        | awk '/^[[:space:]]*SYCL[0-9]+:/ { sub(/^[[:space:]]*/, "", $1); sub(/:$/, "", $1); print $1; exit }'
}

run_case() {
    local name="$1"
    local bin="$2"
    shift 2
    local extra=("$@")

    local case_log="$LOG_DIR/${name}_${TS}.log"

    if [[ ! -x "$bin" ]]; then
        echo "| $name | EMPTY | N/A | ${case_log#$PROJECT_ROOT/} |" | tee -a "$SUMMARY_LOG"
        return 0
    fi

    {
        echo "=== CASE: $name ==="
        echo "timestamp: $(date -Iseconds)"
        echo "binary: $bin"
        echo "model: $MODEL_PATH"
        echo "prompt: $PROMPT"
        echo "extra_args: ${extra[*]:-(none)}"
        echo ""
    } > "$case_log"

    set +e
    timeout --signal=KILL "${TIMEOUT_SEC}s" \
        stdbuf -oL -eL \
        "$bin" \
        --model "$MODEL_PATH" \
        --conversation \
        --simple-io \
        --n-predict "$N_PREDICT" \
        "${extra[@]}" \
        < <(printf '%s\n/exit\n' "$INPUT_LINE_1") >> "$case_log" 2>&1
    local rc=$?
    set -e

    local status="PASS"
    if [[ $rc -eq 124 || $rc -eq 137 ]]; then
        status="TIMEOUT"
    elif [[ $rc -ne 0 ]]; then
        status="FAIL"
    fi

    echo "| $name | $status | $rc | ${case_log#$PROJECT_ROOT/} |" | tee -a "$SUMMARY_LOG"
}

run_case "cpu_release_ngl0" "$PROJECT_ROOT/build/cpu_release/bin/llama-cli" --n-gpu-layers 0
run_case "cpu_debug_ngl0" "$PROJECT_ROOT/build/cpu_debug/bin/llama-cli" --n-gpu-layers 0

SYCL_DEVICE="$(detect_sycl_device || true)"
if [[ -n "$SYCL_DEVICE" ]]; then
    run_case "sycl_release_${SYCL_DEVICE}" "$PROJECT_ROOT/build/sycl_release/bin/llama-cli" --n-gpu-layers 99 --device "$SYCL_DEVICE"
else
    run_case "sycl_release_auto" "$PROJECT_ROOT/build/sycl_release/bin/llama-cli" --n-gpu-layers 99
fi

run_case "openvino_release" "$PROJECT_ROOT/build/openvino_release/bin/llama-cli" --n-gpu-layers 99
run_case "vulkan_release" "$PROJECT_ROOT/build/vulkan_release/bin/llama-cli" --n-gpu-layers 99

echo "" | tee -a "$SUMMARY_LOG"
echo "summary_log: ${SUMMARY_LOG#$PROJECT_ROOT/}" | tee -a "$SUMMARY_LOG"
