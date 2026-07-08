#!/usr/bin/bash
# ==============================================================================
# Automated Replication Script Generated for Backend: sycl (DEBUG)
# Generation Timestamp: 20260706_145421_001 | Status: 0
# Measured Execution Duration: 0.8390 seconds
# ==============================================================================

export CMAKE_PREFIX_PATH=/opt/intel/oneapi/tbb/2023.1/env/..:/opt/intel/oneapi/mkl/2026.1/lib/cmake:/opt/intel/oneapi/dpl/2022.13/lib/cmake/oneDPL:/opt/intel/oneapi/compiler/2026.1:/opt/intel/oneapi/tbb/2023.1/env/..:/opt/intel/oneapi/mkl/2026.1/lib/cmake:/opt/intel/oneapi/dpl/2022.13/lib/cmake/oneDPL:/opt/intel/oneapi/compiler/2026.1
export CPATH=/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/dev-utilities/2026.0/include:/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/dev-utilities/2026.0/include
export CPLUS_INCLUDE_PATH=/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/tbb/2023.1/env/../include:/opt/intel/oneapi/mkl/2026.1/include:/opt/intel/oneapi/dpl/2022.13/include:/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/tbb/2023.1/env/../include:/opt/intel/oneapi/mkl/2026.1/include:/opt/intel/oneapi/dpl/2022.13/include
export C_INCLUDE_PATH=/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/tbb/2023.1/env/../include:/opt/intel/oneapi/mkl/2026.1/include:/opt/intel/oneapi/umf/1.1/include:/opt/intel/oneapi/tbb/2023.1/env/../include:/opt/intel/oneapi/mkl/2026.1/include
export DEBUGINFOD_CACHE_PATH=/home/fekerr/.cache/gdb_symbols
export DIAGUTIL_PATH=/opt/intel/oneapi/compiler/2026.1/etc/compiler/sys_check/sys_check.sh:/opt/intel/oneapi/compiler/2026.1/etc/compiler/sys_check/sys_check.sh
export INFOPATH=/opt/intel/oneapi/debugger/2026.1/share/info:/opt/intel/oneapi/debugger/2026.1/share/info
export INTEL_OPENVINO_DIR=/usr
export IRISLIME_ACTIVE_BACKEND=sycl
export IRISLIME_ACTIVE_PROFILE=DEBUG
export IRISLIME_MODELS_DIR=../models
export IRISLIME_READY=1
export IRISLIME_TEST_MODEL=../models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf
export LD_LIBRARY_PATH=/opt/intel/oneapi/tcm/1.5/lib:/opt/intel/oneapi/umf/1.1/lib:/opt/intel/oneapi/tcm/1.5/env/../lib:/opt/intel/oneapi/tbb/2023.1/env/../lib/intel64/gcc4.8:/opt/intel/oneapi/mkl/2026.1/lib:/opt/intel/oneapi/debugger/2026.1/opt/debugger/lib:/opt/intel/oneapi/compiler/2026.1/opt/compiler/lib:/opt/intel/oneapi/compiler/2026.1/lib:/opt/intel/oneapi/tcm/1.5/lib:/opt/intel/oneapi/umf/1.1/lib:/opt/intel/oneapi/tcm/1.5/env/../lib:/opt/intel/oneapi/tbb/2023.1/env/../lib/intel64/gcc4.8:/opt/intel/oneapi/mkl/2026.1/lib:/opt/intel/oneapi/debugger/2026.1/opt/debugger/lib:/opt/intel/oneapi/compiler/2026.1/opt/compiler/lib:/opt/intel/oneapi/compiler/2026.1/lib
export LIBRARY_PATH=/opt/intel/oneapi/tcm/1.5/lib:/opt/intel/oneapi/umf/1.1/lib:/opt/intel/oneapi/tbb/2023.1/env/../lib/intel64/gcc4.8:/opt/intel/oneapi/mkl/2026.1/lib:/opt/intel/oneapi/compiler/2026.1/lib:/opt/intel/oneapi/tcm/1.5/lib:/opt/intel/oneapi/umf/1.1/lib:/opt/intel/oneapi/tbb/2023.1/env/../lib/intel64/gcc4.8:/opt/intel/oneapi/mkl/2026.1/lib:/opt/intel/oneapi/compiler/2026.1/lib
export MANPATH=/opt/intel/oneapi/debugger/2026.1/share/man:/opt/intel/oneapi/compiler/2026.1/share/man:/home/fekerr/.nvm/versions/node/v20.20.2/share/man:/opt/intel/oneapi/debugger/2026.1/share/man:/opt/intel/oneapi/compiler/2026.1/share/man:
export NLSPATH=/opt/intel/oneapi/compiler/2026.1/lib/compiler/locale/%l_%t/%N:/opt/intel/oneapi/compiler/2026.1/lib/compiler/locale/%l_%t/%N
export ONEAPI_DEVICE_SELECTOR=level0:gpu
export ONEAPI_ROOT=/opt/intel/oneapi
export OpenVINO_DIR=/usr/lib/cmake/openvino2024.6.0
export PATH=/home/fekerr/src/irislime/.venv/bin:/home/fekerr/.nvm/versions/node/v20.20.2/bin:/opt/intel/oneapi/mkl/2026.1/bin:/opt/intel/oneapi/dev-utilities/2026.0/bin:/opt/intel/oneapi/debugger/2026.1/opt/debugger/bin:/opt/intel/oneapi/compiler/2026.1/bin:/home/fekerr/src/irislime/.venv/bin:/home/fekerr/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:/mnt/c/Windows/System32/OpenSSH/:/mnt/c/Program\ Files/dotnet/:/mnt/c/Program\ Files/Git/cmd:/mnt/c/Users/feker/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/feker/AppData/Local/Programs/Microsoft\ VS\ Code\ Insiders/bin:/mnt/c/Users/feker/AppData/Local/Microsoft/WinGet/Links:/mnt/c/Users/feker/AppData/Local/PowerToys/DSCModules/:/snap/bin
export PKG_CONFIG_PATH=/opt/intel/oneapi/tbb/2023.1/env/../lib/pkgconfig:/opt/intel/oneapi/mkl/2026.1/lib/pkgconfig:/opt/intel/oneapi/dpl/2022.13/lib/pkgconfig:/opt/intel/oneapi/compiler/2026.1/lib/pkgconfig:/opt/intel/oneapi/tbb/2023.1/env/../lib/pkgconfig:/opt/intel/oneapi/mkl/2026.1/lib/pkgconfig:/opt/intel/oneapi/dpl/2022.13/lib/pkgconfig:/opt/intel/oneapi/compiler/2026.1/lib/pkgconfig
export TCMROOT=/opt/intel/oneapi/tcm/1.5/env/..
export TCM_ENABLE=1
export TCM_ROOT=/opt/intel/oneapi/tcm/1.5
export ZES_ENABLE_SYSMAN=1

# Fully Expanded Target Command Line Statement
build/sycl_debug/bin/test-backend-ops --list-ops
