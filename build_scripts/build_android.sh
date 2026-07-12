#!/bin/bash
set -e
echo "Building llama.cpp for Android (aarch64)..."
if [ -z "$ANDROID_NDK" ]; then
    echo "ANDROID_NDK not set. Downloading Android NDK..."
    mkdir -p /tmp/ndk
    cd /tmp/ndk
    wget -q https://dl.google.com/android/repository/android-ndk-r26d-linux.zip
    unzip -q android-ndk-r26d-linux.zip
    export ANDROID_NDK=/tmp/ndk/android-ndk-r26d
    cd -
fi
cd llama.cpp
mkdir -p build_android
cd build_android
cmake .. -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF
make -j$(nproc)
echo "Android build complete in llama.cpp/build_android/"
