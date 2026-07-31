#!/bin/bash
# ==============================================================================
# Script: push_and_run.sh
# Purpose: Push compiled llama.cpp Android binaries to a connected Pixel device
#          and execute them via adb shell.
# Setup: Requires adb installed and a phone connected via USB-C with Debugging on.
# ==============================================================================

# Variables
BUILD_DIR="build/android_arm64-v8a"
DEVICE_DIR="/data/local/tmp/llama-pixel"
# Default path for testing (update with a valid model for actual use)
MODEL_PATH=${MODEL_PATH:-"models/your_model.gguf"}
MODEL_NAME=$(basename $MODEL_PATH)
PROMPT="Hello from core12 laptop over USB-C to Pixel!"

echo "[*] Checking for attached ADB devices..."
adb devices

echo "[*] Creating target directory on phone: ${DEVICE_DIR}"
adb shell mkdir -p ${DEVICE_DIR}

echo "[*] Pushing binaries to phone..."
# Push main executable. Ensure the target binary is named 'llama-cli' or 'main' depending on llama.cpp version.
if [ -f "${BUILD_DIR}/bin/llama-cli" ]; then
    adb push ${BUILD_DIR}/bin/llama-cli ${DEVICE_DIR}/llama-cli
    adb shell chmod +x ${DEVICE_DIR}/llama-cli
    BIN_NAME="llama-cli"
elif [ -f "${BUILD_DIR}/bin/main" ]; then
    adb push ${BUILD_DIR}/bin/main ${DEVICE_DIR}/main
    adb shell chmod +x ${DEVICE_DIR}/main
    BIN_NAME="main"
else
    echo "[!] Could not find compiled main binary in ${BUILD_DIR}/bin/."
fi

echo "[*] Pushing model to phone (this might take a while)..."
if [ -f "$MODEL_PATH" ]; then
    adb push "$MODEL_PATH" "${DEVICE_DIR}/${MODEL_NAME}"
else
    echo "[!] Model file ${MODEL_PATH} not found. Skipping model push."
fi

if [ -n "$BIN_NAME" ]; then
    echo "[*] Executing binary on phone..."
    adb shell "cd ${DEVICE_DIR} && ./${BIN_NAME} -m ${MODEL_NAME} -p \"${PROMPT}\" -n 64"
else
    echo "[!] No binary found to execute."
fi

echo "[*] Done."
