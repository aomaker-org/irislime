#!/bin/bash
# tools/capture_baseline.sh - Capture performance baseline for regression detection
# Usage: ./tools/capture_baseline.sh [iterations]

set -e

if [ -z "$IRISLIME_READY" ]; then
    echo "[!] ERROR: IrisLime environment not loaded. Run 'source config_env' first."
    exit 1
fi

ITERATIONS="${1:-10}"
BASELINE_DIR="docs/benchmarks"
mkdir -p "$BASELINE_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date "+%Y-%m-%d %H:%M:%S")

echo "[+] Capturing performance baseline"
echo "[+] Iterations: $ITERATIONS"
echo "[+] Baseline dir: $BASELINE_DIR"
echo ""

# Run benchmark
echo "[*] Running benchmark suite..."
./tools/benchmark_tinyllama.sh $ITERATIONS > /dev/null 2>&1

# Find the most recent benchmark results
LATEST_RESULTS=$(ls -t logs/test/benchmark_results_*.csv | head -1)
if [ -z "$LATEST_RESULTS" ]; then
    echo "[!] ERROR: No benchmark results found"
    exit 1
fi

# Calculate statistics
BASELINE_FILE="$BASELINE_DIR/baseline_${TIMESTAMP}.json"

{
    echo "{"
    echo "  \"timestamp\": \"$DATE_HUMAN\","
    echo "  \"timestamp_iso\": \"$(date -Iseconds)\","
    echo "  \"iterations\": $ITERATIONS,"
    echo "  \"model\": \"tinyllama-1.1b-chat-v1.0-Q4_K_M\","
    echo "  \"results_csv\": \"$(basename $LATEST_RESULTS)\","
    
    # Calculate metrics
    echo "  \"metrics\": {"
    
    # Extract throughput values (5th column)
    THROUGHPUTS=$(tail -n +2 "$LATEST_RESULTS" | awk -F',' '{print $5}')
    
    # Count samples
    COUNT=$(echo "$THROUGHPUTS" | wc -l)
    
    # Calculate average
    AVG=$(echo "$THROUGHPUTS" | awk '{sum+=$1; count++} END {if (count>0) printf "%.2f", sum/count}')
    
    # Calculate min/max
    MIN=$(echo "$THROUGHPUTS" | sort -n | head -1)
    MAX=$(echo "$THROUGHPUTS" | sort -n | tail -1)
    
    # Calculate stddev
    STDDEV=$(echo "$THROUGHPUTS" | awk -v avg=$AVG '{sum+=($1-avg)^2} END {if (NR>1) printf "%.2f", sqrt(sum/(NR-1)); else printf "0"}')
    
    echo "    \"samples\": $COUNT,"
    echo "    \"avg_throughput_tps\": $AVG,"
    echo "    \"min_throughput_tps\": $MIN,"
    echo "    \"max_throughput_tps\": $MAX,"
    echo "    \"stddev_throughput_tps\": $STDDEV,"
    echo "    \"variance_percent\": $(echo "scale=2; ($STDDEV / $AVG) * 100" | bc)"
    echo "  }"
    echo "}"
} | tee "$BASELINE_FILE"

echo ""
echo "[+] Baseline captured: $BASELINE_FILE"
echo "[+] CSV results: $LATEST_RESULTS"

# Also copy CSV to benchmarks directory for tracking
cp "$LATEST_RESULTS" "$BASELINE_DIR/results_${TIMESTAMP}.csv"
echo "[+] Results archived: $BASELINE_DIR/results_${TIMESTAMP}.csv"

# Create index
INDEX_FILE="$BASELINE_DIR/INDEX.md"
if [ ! -f "$INDEX_FILE" ]; then
    cat > "$INDEX_FILE" << 'EOFINDEX'
# Performance Baseline Index

Track performance baselines for regression detection.

## Files

| Baseline | Date | Avg Throughput | Samples | Status |
|----------|------|----------------|---------|--------|
EOFINDEX
fi

# Append to index
echo "| $(basename $BASELINE_FILE) | $DATE_HUMAN | $AVG tok/sec | $COUNT | ✅ |" >> "$INDEX_FILE"

echo "[+] Index updated: $INDEX_FILE"
echo ""
echo "=== Baseline Summary ==="
echo "Average throughput: $AVG tokens/sec"
echo "Min: $MIN, Max: $MAX"
echo "Std Dev: $STDDEV (variance: $(echo "scale=1; ($STDDEV / $AVG) * 100" | bc)%)"
echo ""
echo "✅ Baseline captured successfully"
