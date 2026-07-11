#!/usr/bin/env bash
# ==============================================================================
# Path:        tools/puppy_chow_002.sh
# Purpose:     Hardened Greedy-Inference System Verification Wrapper for Qwen
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification / Testing Suite
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0715 (Greedy constraints & confirmed native llama-cli flags)
# ==============================================================================

set -eo pipefail

LLAMA_BIN="./build/vulkan_debug/bin/llama-cli"
MODEL_PATH="../models/qwen2.5-0.5b-instruct-q4_k_m.gguf"

if [ ! -f "${LLAMA_BIN}" ]; then
    echo "[!] Error: Compiled binary asset missing at: ${LLAMA_BIN}"
    exit 1
fi

if [ ! -f "${MODEL_PATH}" ]; then
    echo "[!] Error: Downloaded model weights missing at: ${MODEL_PATH}"
    exit 1
fi

clear
echo "=================================================================="
echo "[+] LAUNCHING PUPPY_CHOW INFERENCE HEALTH CHECK (VULKAN CORE)"
echo "=================================================================="
echo "  [*] Baseline Parameter Gate: Greedy Decoding Active (--temp 0)"
echo "  [*] Context Framework:       Strict ChatML Boundary Separation"
echo "  [*] Pipeline Mode:           Simple IO Mode Engaged"
echo "==================================================================\n"

# Execute the inference pass with strict parameter alignment
"${LLAMA_BIN}" \
  -m "${MODEL_PATH}" \
  --temp 0 \
  --simple-io \
  -p "<|im_start|>system
You are puppy_chow, an unyielding local systems validation assistant. You process text logs methodically. You never step out of character, and you do not reference Alibaba Cloud. Break down user data chronologically.
<|im_end|>
<|im_start|>user
Analyze this log status item: '[Watchdog Reset] Activity confirmed after 17.00s of quiet.'
<|im_end|>
<|im_start|>assistant
"

echo -e "\n\n=================================================================="
echo "[+] INFERENCE PROFILING COMPLETE"
echo "=================================================================="

# end of file: tools/puppy_chow_002.sh
