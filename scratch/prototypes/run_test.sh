#!/usr/bin/env bash
# scratch/run_test.sh
# Test suite engine designed to execute runtime targets through GDB wrappers.
# Guarantees continuous multi-test execution loops and records metrics to an append-only ledger.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GDB_WRAPPER="./scratch/run_gdb.sh"
TEST_LEDGER="./scratch/test_suite_ledger.md"

# 1. Initialize Test Ledger Layout if Missing (Append-Only Base Schema)
if [ ! -f "$TEST_LEDGER" ]; then
    echo "# IrisLime Automated Test Suite Execution Ledger" > "$TEST_LEDGER"
    echo "" >> "$TEST_LEDGER"
    echo "| Date/Time (PDT) | Test Pipeline Definition | Status | Exit Code | Binary Core Target |" >> "$TEST_LEDGER"
    echo "| :--- | :--- | :--- | :--- | :--- |" >> "$TEST_LEDGER"
fi

# 2. Isolation and Logging Harness Function
execute_isolated_test() {
    local TEST_LABEL="$1"
    local TEST_COMMAND="$2"
    local CORE_TARGET="$3"
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo "========================================================"
    echo "[TEST START] Pipeline: $TEST_LABEL"
    echo "========================================================"
    
    # Run target within an isolated eval block to protect the runner loop from early termination
    eval "$TEST_COMMAND"
    local RUN_STATUS=$?
    
    echo "--------------------------------------------------------"
    if [ $RUN_STATUS -eq 0 ]; then
        echo "[TEST PASS] $TEST_LABEL executed cleanly."
        echo "| $TIMESTAMP | $TEST_LABEL | PASS | 0 | $CORE_TARGET |" >> "$TEST_LEDGER"
    else
        echo "[TEST FAULT] $TEST_LABEL terminated unexpectedly with Exit Code: $RUN_STATUS"
        echo "| $TIMESTAMP | $TEST_LABEL | FAULT | $RUN_STATUS | $CORE_TARGET |" >> "$TEST_LEDGER"
    fi
    echo "========================================================"
    echo ""
    
    return $RUN_STATUS
}

# --- ACTIVE TEST REGISTRY ---

# Test Case 001: Default SYCL Hardware Topology Interrogation (Level Zero Path)
execute_isolated_test \
    "SYCL Hardware Device Discovery (Level Zero Default)" \
    "export ZE_ENABLE_TRACING_LAYER=0; $GDB_WRAPPER ./build/bin/llama-ls-sycl-device" \
    "./build/bin/llama-ls-sycl-device"

# Test Case 002: Bypassing Level Zero via the OpenCL Hardware Pipeline Selector
execute_isolated_test \
    "SYCL Hardware Device Discovery (OpenCL Backend Bypass)" \
    "export ONEAPI_DEVICE_SELECTOR=opencl:gpu; $GDB_WRAPPER ./build/bin/llama-ls-sycl-device" \
    "./build/bin/llama-ls-sycl-device"

# Test Case 003: Base System Shared Library Binding Check (Llama CLI Engine)
execute_isolated_test \
    "Llama CLI Engine Version Initialization" \
    "export ONEAPI_DEVICE_SELECTOR=opencl:gpu; $GDB_WRAPPER ./build/bin/llama-cli --version" \
    "./build/bin/llama-cli"


echo "[+] Test execution loop concluded. Complete runtime history logged to scratch/test_suite_ledger.md"

# EPILOG: Expected filename on drive: scratch/run_test.sh
