#!/bin/bash
set -e
echo "Building llama.cpp for Android (aarch64)..."
if [ -z "$ANDROID_NDK" ]; then
    echo "ANDROID_NDK not set. Downloading Android NDK..."
    mkdir -p /tmp/ndk
    cd /tmp/ndk
    NDK_ZIP="android-ndk-r26d-linux.zip"
    # Expected SHA256 for android-ndk-r26d-linux.zip (verify at https://developer.android.com/ndk/downloads)
    NDK_SHA256="6d6e6a8d9cfe51d2b2b94d8eb4c34a748e7a6f05b9d3e85c9e0c5a86c0a94f73"
    wget -q "https://dl.google.com/android/repository/${NDK_ZIP}"
    if ! echo "${NDK_SHA256}  ${NDK_ZIP}" | sha256sum -c - 2>/dev/null; then
        echo "[!] ERROR: NDK checksum verification failed. Aborting." >&2
        exit 1
    fi
    unzip -q "$NDK_ZIP"
    export ANDROID_NDK=/tmp/ndk/android-ndk-r26d
    cd -
fi
cd llama.cpp
mkdir -p build_android
cd build_android
cmake .. -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF
make -j$(nproc)
echo "Android build complete in llama.cpp/build_android/"
