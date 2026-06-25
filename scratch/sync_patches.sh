#!/bin/sh
# Target Runway: scratch/sync_patches.sh
# Purpose: Non-destructively copy active optimization patches into the submodule tree.

SRC_FORK="../llama.cpp"
DEST_SUBMODULE="llama.cpp"

log_sync() {
    echo "[+] Syncing: $1"
    cp "$SRC_FORK/$1" "$DEST_SUBMODULE/$1"
}

echo "=== INITIALIZING HARDWARE PATCH TRANSFER ==="

# Port OpenVINO runtime extensions and quantization kernels
log_sync "ggml/src/ggml-openvino/ggml-openvino-extra.cpp"
log_sync "ggml/src/ggml-openvino/ggml-quants.cpp"
log_sync "ggml/src/ggml-openvino/openvino/pass/fuse_to_sdpa.h"
log_sync "ggml/src/ggml-openvino/openvino/pass/mark_decompression_convert_constant_folding.h"
log_sync "ggml/src/ggml-openvino/openvino/pass/squeeze_matmul.h"

# Port Intel SYCL binary broadcast optimizations
log_sync "ggml/src/ggml-sycl/binbcast.cpp"

echo "=== TRANSFER COMPLETE. EVALUATING INTERNAL SUBMODULE STATUS ==="
cd llama.cpp
git status
