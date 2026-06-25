#!/bin/bash
# tools/test_model_comparison.sh - Compare old model vs new TinyLlama
# Usage: ./tools/test_model_comparison.sh [prompt]
# Documents whether BF16 issues persist with old model vs fixed with new model

set -e

if [ -z "$IRISLIME_READY" ]; then
    echo "[!] ERROR: IrisLime environment not loaded. Run 'source config_env' first."
    exit 1
fi

# Model paths
OLD_MODEL="./models/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
NEW_MODEL="./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
LLAMA_CLI="./build/sycl_release/bin/llama-cli"

# Verify CLI exists
if [ ! -f "$LLAMA_CLI" ]; then
    echo "[!] ERROR: llama-cli not found. Run 'make build TARGET=sycl_release' first."
    exit 1
fi

# Logging
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="./logs/test"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/model_comparison_${TIMESTAMP}.log"

PROMPT="${1:-What is the capital of France?}"

{
    echo "=== Model Comparison Test ==="
    echo "Date: $(date -Iseconds)"
    echo "Prompt: $PROMPT"
    echo "CLI: $LLAMA_CLI"
    echo ""
    
    # Test old model if available
    if [ -f "$OLD_MODEL" ]; then
        echo "--- OLD Model (Llama-3.2-1B) ---"
        echo "Path: $OLD_MODEL"
        echo "Expected Issue: BF16 unsupported on Iris Xe"
        echo ""
        
        OLD_EXIT=0
        {
            "$LLAMA_CLI" \
                --model "$OLD_MODEL" \
                --prompt "$PROMPT" \
                --n-predict 64 \
                --device sycl \
                2>&1
        } | tee -a "$LOG_FILE" || OLD_EXIT=$?
        
        echo ""
        echo "Old Model Exit Code: $OLD_EXIT"
        if grep -q "bf16\|BF16" "$LOG_FILE"; then
            echo "Result: ❌ BF16 ERROR DETECTED (as expected)"
        else
            echo "Result: ✅ No BF16 error (unexpected)"
        fi
        echo ""
    else
        echo "--- OLD Model (Llama-3.2-1B) ---"
        echo "Status: NOT FOUND (skipping)"
        OLD_EXIT=-1
        echo ""
    fi
    
    # Test new model
    if [ -f "$NEW_MODEL" ]; then
        echo "--- NEW Model (TinyLlama-1.1B) ---"
        echo "Path: $NEW_MODEL"
        echo "Expected Result: No BF16 issues (F16-based quantization)"
        echo ""
        
        NEW_EXIT=0
        {
            "$LLAMA_CLI" \
                --model "$NEW_MODEL" \
                --prompt "$PROMPT" \
                --n-predict 64 \
                --device sycl \
                2>&1
        } | tee -a "$LOG_FILE" || NEW_EXIT=$?
        
        echo ""
        echo "New Model Exit Code: $NEW_EXIT"
        if grep -q "bf16\|BF16" "$LOG_FILE"; then
            echo "Result: ⚠️  BF16 REFERENCES FOUND (unexpected)"
        else
            echo "Result: ✅ SUCCESS - No BF16 errors"
        fi
        echo ""
    else
        echo "--- NEW Model (TinyLlama-1.1B) ---"
        echo "Status: NOT FOUND"
        NEW_EXIT=-1
        echo ""
    fi
    
    # Summary
    echo "=== COMPARISON SUMMARY ==="
    if [ $OLD_EXIT -ne 0 ] && [ $NEW_EXIT -eq 0 ]; then
        echo "✅ MIGRATION SUCCESSFUL: Old model failed, new model works"
    elif [ $NEW_EXIT -eq 0 ]; then
        echo "✅ New model compatible with Iris Xe"
    else
        echo "❌ New model also has issues (check logs)"
    fi
    
} | tee "$LOG_FILE"

echo ""
echo "[+] Comparison complete. Log: $LOG_FILE"

# Summary for forensics
echo ""
echo "=== Forensic Summary ==="
echo "Old Model (Llama-3.2-1B): Exit $OLD_EXIT"
echo "New Model (TinyLlama-1.1B): Exit $NEW_EXIT"
echo ""
if grep -q "bf16\|BF16" "$LOG_FILE"; then
    echo "BF16 Issues Detected:"
    grep -i "bf16" "$LOG_FILE" | sort -u
fi

exit $NEW_EXIT
