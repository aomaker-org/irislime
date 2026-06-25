#!/bin/bash
# tools/benchmark_tinyllama.sh - Benchmark TinyLlama inference speed on Iris Xe
# Usage: ./tools/benchmark_tinyllama.sh [num_iterations]
# Measures: tokens/sec, memory usage, consistency across runs

set -e

if [ -z "$IRISLIME_READY" ]; then
    echo "[!] ERROR: IrisLime environment not loaded. Run 'source config_env' first."
    exit 1
fi

MODEL_PATH="./models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
LLAMA_CLI="./build/sycl_release/bin/llama-cli"
ITERATIONS="${1:-3}"

if [ ! -f "$MODEL_PATH" ]; then
    echo "[!] ERROR: Model not found at $MODEL_PATH"
    exit 1
fi

if [ ! -f "$LLAMA_CLI" ]; then
    echo "[!] ERROR: llama-cli not found at $LLAMA_CLI"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="./logs/test"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/benchmark_tinyllama_${TIMESTAMP}.log"
RESULTS_FILE="$LOG_DIR/benchmark_results_${TIMESTAMP}.csv"

# Prompts for testing (varied complexity)
declare -a PROMPTS=(
    "Hello"
    "What is machine learning?"
    "Explain quantum computing in simple terms. Why is it different from classical computing? What are the main challenges?"
)

echo "[+] TinyLlama Benchmark (GGUF Q4_K_M)"
echo "[+] Model: $MODEL_PATH"
echo "[+] Iterations: $ITERATIONS per prompt"
echo "[+] Log: $LOG_FILE"
echo "[+] Results CSV: $RESULTS_FILE"
echo ""

{
    echo "=== Benchmark Configuration ==="
    echo "Date: $(date -Iseconds)"
    echo "Model: $MODEL_PATH"
    echo "CLI: $LLAMA_CLI"
    echo "Iterations: $ITERATIONS"
    echo "Prompts: ${#PROMPTS[@]}"
    echo ""
    
    # CSV header
    echo "prompt_length,iteration,tokens_predicted,time_elapsed_sec,tokens_per_sec" > "$RESULTS_FILE"
    
    for prompt in "${PROMPTS[@]}"; do
        PROMPT_LEN=${#prompt}
        echo "--- Testing prompt ($PROMPT_LEN chars): \"$prompt\" ---"
        
        for ((i=1; i<=ITERATIONS; i++)); do
            echo "  Iteration $i..."
            
            START_TIME=$(date +%s%N)
            
            # Run and capture output
            OUTPUT=$("$LLAMA_CLI" \
                --model "$MODEL_PATH" \
                --prompt "$prompt" \
                --n-predict 128 \
                --device sycl \
                2>&1 || true)
            
            END_TIME=$(date +%s%N)
            
            # Calculate metrics
            ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))
            ELAPSED_SEC=$(echo "scale=3; $ELAPSED_MS / 1000" | bc)
            PREDICTED_TOKENS=$(echo "$OUTPUT" | grep -i "generated" | grep -oP '\d+(?= tokens)' | tail -1 || echo "128")
            TOKENS_PER_SEC=$(echo "scale=2; $PREDICTED_TOKENS / $ELAPSED_SEC" | bc 2>/dev/null || echo "0")
            
            echo "$PROMPT_LEN,$i,$PREDICTED_TOKENS,$ELAPSED_SEC,$TOKENS_PER_SEC" >> "$RESULTS_FILE"
            echo "    Elapsed: ${ELAPSED_SEC}s | Tokens: $PREDICTED_TOKENS | Rate: ${TOKENS_PER_SEC} tok/sec"
        done
        echo ""
    done
    
    echo "=== Benchmark Complete ==="
    echo ""
    echo "Results (CSV format):"
    cat "$RESULTS_FILE"
    
} | tee "$LOG_FILE"

echo ""
echo "[+] Benchmark complete."
echo "[+] Results saved to: $RESULTS_FILE"
echo ""
echo "=== Quick Stats ==="
tail -n +2 "$RESULTS_FILE" | awk -F, '{sum+=$5; count++} END {if(count>0) printf "Average throughput: %.2f tokens/sec\n", sum/count}'

exit 0
