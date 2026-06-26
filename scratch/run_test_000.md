# Test 000: OpenCL GPU Device Discovery

## Objective
Verify that the SYCL compiler toolchain can safely see the Intel Iris Xe integrated GPU using the OpenCL driver backend, bypassing the buggy Level Zero tracking layers.

## Execution Command
```bash
export ONEAPI_DEVICE_SELECTOR=opencl:gpu
./scratch/run_gdb.sh ./build/bin/llama-ls-sycl-device
rectly into that open prompt, and hit Enter:

History Ledger
Date/Time (PDT)	Status	Exit Code	Notes
2026-06-25 12:55:53	PASS	0	Found Intel Graphics [0x46a8] with 96 EUs.
EPILOG: Expected filename on drive: scratch/run_test_000.md
| 2026-06-25 18:47:24 | PASS | 0 | Automated run cleared cleanly. |
| 2026-06-25 18:56:47 | PASS | 0 | Automated run cleared cleanly. |
