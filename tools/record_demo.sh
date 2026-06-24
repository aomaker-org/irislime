#!/bin/bash
# record_demo.sh - Execute the matrix and save to logs

# Define the log filename with a timestamp for forensic tracking
LOG_FILE="docs/demo_results_$(date +%Y%m%d_%H%M%S).log"

echo "[+] Demo output will be saved to: $LOG_FILE"

# Execute the matrix and pipe to both stdout (for your screen recording)
# and the log file (for your git commit)
./run_demo.sh 2>&1 | tee "$LOG_FILE"

echo "[+] Demo complete. Results logged."
