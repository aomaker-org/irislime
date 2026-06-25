#!/bin/bash
# tools/detect_regression.sh - Compare current performance against baseline
# Usage: ./tools/detect_regression.sh [baseline_file] [threshold_percent]

set -e

if [ -z "$IRISLIME_READY" ]; then
    echo "[!] ERROR: IrisLime environment not loaded. Run 'source config_env' first."
    exit 1
fi

BASELINE_FILE="${1:-docs/benchmarks/baseline_latest.json}"
THRESHOLD_PERCENT="${2:-10}"  # Default: 10% drop = regression

if [ ! -f "$BASELINE_FILE" ]; then
    echo "[!] ERROR: Baseline file not found: $BASELINE_FILE"
    echo "[*] Run './tools/capture_baseline.sh' to create a baseline first"
    exit 1
fi

echo "[+] Regression Detection"
echo "[+] Baseline: $BASELINE_FILE"
echo "[+] Threshold: ${THRESHOLD_PERCENT}% drop"
echo ""

# Parse baseline metrics
BASELINE_AVG=$(grep '"avg_throughput_tps"' "$BASELINE_FILE" | grep -oP '\d+\.\d+')
BASELINE_STDDEV=$(grep '"stddev_throughput_tps"' "$BASELINE_FILE" | grep -oP '\d+\.\d+')

if [ -z "$BASELINE_AVG" ]; then
    echo "[!] ERROR: Could not parse baseline JSON"
    exit 1
fi

echo "[*] Baseline: $BASELINE_AVG ± $BASELINE_STDDEV tok/sec"
echo ""

# Run current benchmark
echo "[*] Running current benchmark (5 iterations)..."
./tools/benchmark_tinyllama.sh 5 > /dev/null 2>&1

# Get latest results
LATEST_RESULTS=$(ls -t logs/test/benchmark_results_*.csv | head -1)
if [ -z "$LATEST_RESULTS" ]; then
    echo "[!] ERROR: No benchmark results found"
    exit 1
fi

# Extract throughputs from latest results
CURRENT_THROUGHPUTS=$(tail -n +2 "$LATEST_RESULTS" | awk -F',' '{print $5}')

# Calculate current metrics
CURRENT_COUNT=$(echo "$CURRENT_THROUGHPUTS" | wc -l)
CURRENT_AVG=$(echo "$CURRENT_THROUGHPUTS" | awk '{sum+=$1; count++} END {if (count>0) printf "%.2f", sum/count}')
CURRENT_MIN=$(echo "$CURRENT_THROUGHPUTS" | sort -n | head -1)
CURRENT_MAX=$(echo "$CURRENT_THROUGHPUTS" | sort -n | tail -1)
CURRENT_STDDEV=$(echo "$CURRENT_THROUGHPUTS" | awk -v avg=$CURRENT_AVG '{sum+=($1-avg)^2} END {if (NR>1) printf "%.2f", sqrt(sum/(NR-1)); else printf "0"}')

echo "[*] Current: $CURRENT_AVG ± $CURRENT_STDDEV tok/sec (n=$CURRENT_COUNT)"
echo ""

# Calculate change
CHANGE_ABSOLUTE=$(echo "scale=2; $CURRENT_AVG - $BASELINE_AVG" | bc)
CHANGE_PERCENT=$(echo "scale=2; ($CHANGE_ABSOLUTE / $BASELINE_AVG) * 100" | bc)

# Determine status
if (( $(echo "$CHANGE_PERCENT < -${THRESHOLD_PERCENT}" | bc -l) )); then
    STATUS="❌ REGRESSION"
    EXIT_CODE=1
elif (( $(echo "$CHANGE_PERCENT > ${THRESHOLD_PERCENT}" | bc -l) )); then
    STATUS="⬆️  IMPROVEMENT"
    EXIT_CODE=0
else
    STATUS="✅ NORMAL"
    EXIT_CODE=0
fi

echo "=== Regression Analysis ==="
echo ""
echo "Baseline Avg:     $BASELINE_AVG tok/sec"
echo "Current Avg:      $CURRENT_AVG tok/sec"
echo "Absolute Change:  $CHANGE_ABSOLUTE tok/sec"
echo "Percent Change:   $CHANGE_PERCENT%"
echo ""
echo "Regression Threshold: -${THRESHOLD_PERCENT}%"
echo "Status: $STATUS"
echo ""

if [ $EXIT_CODE -ne 0 ]; then
    echo "⚠️  PERFORMANCE REGRESSION DETECTED!"
    echo ""
    echo "Suggestions:"
    echo "1. Check for new BF16 errors: grep -i bf16 logs/test/benchmark_tinyllama_*.log"
    echo "2. Check for 'disabling SYCL graphs': grep 'disabling' logs/test/benchmark_tinyllama_*.log"
    echo "3. Check system load: top, free -h"
    echo "4. Check GPU memory: clinfo"
    echo "5. Review llama.cpp changes since last baseline"
    echo ""
    echo "To update baseline after fixes:"
    echo "  ./tools/capture_baseline.sh 10"
fi

# Save regression report
REPORT_FILE="logs/test/regression_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "=== Performance Regression Report ==="
    echo "Date: $(date -Iseconds)"
    echo ""
    echo "Baseline: $BASELINE_FILE"
    echo "Baseline Avg: $BASELINE_AVG ± $BASELINE_STDDEV tok/sec"
    echo ""
    echo "Current Results: $(basename $LATEST_RESULTS)"
    echo "Current Avg: $CURRENT_AVG ± $CURRENT_STDDEV tok/sec"
    echo ""
    echo "Change: $CHANGE_ABSOLUTE tok/sec ($CHANGE_PERCENT%)"
    echo "Threshold: -${THRESHOLD_PERCENT}%"
    echo ""
    echo "Status: $STATUS"
    echo ""
    echo "Details:"
    echo "- Baseline samples: $(grep '"samples"' $BASELINE_FILE | grep -oP '\d+')"
    echo "- Current samples: $CURRENT_COUNT"
    echo "- Current min/max: $CURRENT_MIN / $CURRENT_MAX"
} | tee "$REPORT_FILE"

echo ""
echo "[+] Report saved: $REPORT_FILE"

exit $EXIT_CODE
