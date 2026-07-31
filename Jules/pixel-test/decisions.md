# Decisions for Android Pixel Target Build

## Objective
Support cross-compilation for Google Pixel series (specifically Pixel 6a, 10 Pro, 10 XL) running standard Android ("vanilla android"), and allow testing via `adb` attached directly over USB-C.

## Target Architecture
* Pixel 6a uses Google Tensor (ARMv8).
* Pixel 10-series is assumed to also be an ARM64-v8a compatible target.
* Therefore, the chosen compilation target is `arm64-v8a`.

## Build Process
* `llama.cpp` is used as the underlying inference engine.
* We will establish an Android Makefile (`infra/make/android.mk`) to wrap CMake with the Android NDK.
* We configure dynamic submodule hydration using `git submodule update --init --recursive llama.cpp` specifically for the test setup, or standard Git commands.

## ADB Testing (Direct Laptop-to-Phone USB-C)
* Once built, binaries need to be pushed to `/data/local/tmp` on the device (the standard executable partition accessible to adb shell).
* Instructions will outline the `adb push` commands and shell execution.
