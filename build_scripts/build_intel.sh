#!/bin/bash
set -e
echo "Building llama.cpp for Intel Iris Xe (SYCL)..."
if [ -z "$ONEAPI_ROOT" ]; then
    if [ -f "/opt/intel/oneapi/setvars.sh" ]; then
        source /opt/intel/oneapi/setvars.sh > /dev/null
    else
        echo "Warning: oneAPI not found. Intel GPU support requires oneAPI."
    fi
fi
if ! command -v icpx &> /dev/null; then
    echo "SYCL compiler (icpx) not found! Please ensure Intel oneAPI base toolkit is installed."
    echo "Falling back to standard CPU build as a mock for the script if SYCL isn't available..."
    SYCL_FLAG="-DGGML_SYCL=OFF"
else
    SYCL_FLAG="-DGGML_SYCL=ON"
fi
cd llama.cpp
mkdir -p build_intel
cd build_intel
if [ "$SYCL_FLAG" = "-DGGML_SYCL=ON" ]; then
    export CC=icx
    export CXX=icpx
fi
cmake .. -DCMAKE_BUILD_TYPE=Release $SYCL_FLAG
make -j$(nproc)
echo "Intel Iris Xe build complete in llama.cpp/build_intel/"
