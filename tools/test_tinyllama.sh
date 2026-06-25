#!/bin/bash
# tools/test_tinyllama.sh - Test TinyLlama-1.1B model on Iris Xe
# Usage: ./tools/test_tinyllama.sh [prompt]

set -e
set -o pipefail

# Ensure environment is loaded
if [ -z "$IRISLIME_READY" ]; then
    echo "[!] ERROR: IrisLime environment not loaded. Run 'source config_env' first."
    exit 1
fi

# Model configuration
MODEL_PATH="./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
LLAMA_CLI="./build/sycl_release/bin/llama-cli"

# Verify model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "[!] ERROR: Model not found at $MODEL_PATH"
    exit 1
fi

# Verify llama-cli exists
if [ ! -f "$LLAMA_CLI" ]; then
    echo "[!] ERROR: llama-cli not found at $LLAMA_CLI"
    echo "[*] Run 'make build TARGET=sycl_release' first"
    exit 1
fi

# Default prompt or user-provided
PROMPT="${1:-Hello, how are you today?}"

# Logging setup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="./logs/test"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/tinyllama_test_${TIMESTAMP}.log"

echo "[+] TinyLlama-1.1B Test (GGUF Q4_K_M)"
echo "[+] Model: $MODEL_PATH"
echo "[+] CLI: $LLAMA_CLI"
echo "[+] Prompt: $PROMPT"
echo "[+] Log: $LOG_FILE"
echo ""
echo "--- Test Output ---"

# Run inference with forensic logging
{
    echo "=== Test Execution ==="
    echo "Timestamp: $(date -Iseconds)"
    echo "Model: $MODEL_PATH"
    echo "CLI: $LLAMA_CLI"
    echo "Prompt: $PROMPT"
    echo ""
    echo "=== Inference Output ==="
} | tee "$LOG_FILE"

set +e
"$LLAMA_CLI" \
    --model "$MODEL_PATH" \
    --prompt "$PROMPT" \
    --n-predict 128 \
    --device sycl \
    2>&1 | tee -a "$LOG_FILE"
INFERENCE_EXIT=${PIPESTATUS[0]}
set -e

{
    echo ""
    echo "=== Inference Result ==="
    echo "Exit Code: $INFERENCE_EXIT"

    if [ $INFERENCE_EXIT -eq 0 ]; then
        echo "✅ SUCCESS: Model inference completed without BF16 errors"
    else
        echo "❌ FAILURE: Model inference failed (see logs above)"
    fi
} | tee -a "$LOG_FILE"

if [ $INFERENCE_EXIT -ne 0 ]; then
    echo ""
    echo "[!] Inference failed with exit code: $INFERENCE_EXIT"
fi

# Summary
echo ""
echo "[+] Test complete. Full log: $LOG_FILE"

# Check for BF16 errors in log
if [ $INFERENCE_EXIT -eq 0 ]; then
    if grep -q "bf16\|BF16" "$LOG_FILE"; then
        echo "[!] WARNING: BF16 references detected in log (may indicate unsupported ops)"
        grep "bf16\|BF16" "$LOG_FILE" | head -5
    else
        echo "[✓] No BF16 references in log - compatibility verified!"
    fi
else
    echo "[!] Compatibility not verified due to inference failure."
fi

exit ${INFERENCE_EXIT:-0}
