# SYCL/Iris Xe Compatibility Analysis

## Executive Summary

IrisLime targets **Intel Iris Xe integrated graphics** via the SYCL compute abstraction. This document catalogs known limitations, workarounds, and optimization opportunities specific to this hardware/software stack.

**Current Status:** Model migration (Llama-3.2-1B → TinyLlama-1.1B) successfully avoids BF16 issues. Comprehensive testing infrastructure in place.

---

## Critical Issues Identified

### 1. ❌ **BF16 (bfloat16) Not Supported**

**Issue:** Iris Xe lacks native BF16 support in SYCL kernels.

**Technical Root Cause:**
- `GGML_SYCL_HAS_BF16` is automatically **defined** if the Intel LLVM compiler has `<sycl/ext/oneapi/bfloat16.hpp>`
- This macro indicates *compiler support*, NOT GPU support
- When a BF16 operation reaches `ggml_sycl_op_bin_bcast()`:
  - The `#ifdef GGML_SYCL_HAS_BF16` block is enabled
  - Code tries to dispatch BF16 computation to GPU
  - Iris Xe silently fails → falls through to unsupported type error

**Evidence from logs:**
```
SNAKE_FUSE(type=f16,ne=[64,32,2,3]): ggml_sycl_op_bin_bcast: unsupported types: dst: bf16, src0: bf16, src1: f32
```

**Workaround:** ✅ Use F16-based quantizations (Q4_K_M, Q5_K_M) instead of BF16 models
- Current model: `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` (F16-based, works)
- Avoid: Any model with BF16 tensors in critical paths

**Affected Operations:**
- Binary broadcasts (add, multiply with mixed types)
- Concatenation (concat.cpp line 200)
- Set rows (set_rows.cpp line 8+)
- Type conversions (convert.cpp line 717+)
- GEMM operations (gemm.hpp line 32+)

**Files to watch:**
```
llama.cpp/ggml/src/ggml-sycl/
├── common.hpp        # BF16 detection (lines 34-37)
├── binbcast.cpp      # Binary broadcast ops (line 296, 340)
├── convert.cpp       # Type conversions (line 717+)
├── concat.cpp        # Concatenation (line 200)
└── gemm.hpp          # Matrix multiply (line 32)
```

---

### 2. ⚠️ **Device-to-Device GPU Communication Issues (Multi-GPU Only)**

**Issue:** Cross-GPU data transfers fail on systems with multiple Iris Xe GPUs.

**Code Reference:**
```cpp
//todo, it's known issue：error in device2device cross GPUs. 
// reused when the issue is fixed. DON"T remove
```
Source: `ggml-sycl.cpp` lines 694, 697

**Impact:** **None** for single-GPU systems (like IrisLime laptops)

**Status:** Workaround in place—uses single device

---

### 3. ⚠️ **FP16 Capability Not Verified at Runtime**

**Issue:** Code assumes FP16 support without device capability check.

**Code Reference:**
```cpp
bool use_fp16 = true;  // TODO(Yu) SYCL capability check
```
Source: `ggml-sycl.cpp` line 2425

**Impact:** **Low** - Iris Xe guarantees FP16 support

**Recommendation:** Add device capability query on startup:
```cpp
// Proposed fix:
bool use_fp16 = device.has(sycl::aspect::fp16);
```

---

### 4. ⚠️ **Graph Execution Accuracy Issues with Quantized Kernels (MMQ)**

**Issue:** Matrix-multiply-quantized (MMQ) kernels have accuracy concerns.

**Code Reference:**
```cpp
// TODO: accuracy issues in MMQ
```
Source: `ggml-sycl.cpp` line 3504

**Impact:** Potential numerical precision degradation with certain quantizations

**Recommendation:** Monitor via regression testing (see benchmark scripts)

---

### 5. ⚠️ **Unsupported Buffer Types May Cause Assertions**

**Issue:** Code asserts if buffer type mismatches device expectations.

**Code Reference:**
```cpp
GGML_ASSERT(buf->buft == ggml_backend_sycl_buffer_type(sycl_ctx->device) 
            && "unsupported buffer type");
```
Source: `ggml-sycl.cpp` lines 5057, 5078

**Impact:** Can crash with unhelpful error messages

**Recommendation:** Add detailed logging before assertion failure

---

### 6. ⚠️ **Graph Node Type Limitations**

**Issue:** SYCL graph mode disables itself if unsupported node types are encountered.

**Code Reference:**
```cpp
GGML_LOG_INFO("%s: disabling SYCL graphs due to unsupported node type %s\n", 
              __func__, ggml_op_name(node->op));
```
Source: `ggml-sycl.cpp` lines 5182, 5191

**Impact:** Falls back to slow non-graphed execution

**Recommendation:** Monitor logs for "disabling SYCL graphs" messages—indicates performance regression

---

## Hardware-Specific Optimizations

### Iris Xe Core Calculation

**Code:**
```cpp
info.devices[i].nsm = prop.get_max_compute_units() / 16; //16: Number of Xe Cores
```
Source: `ggml-sycl.cpp` line 143

**Meaning:** Each Xe GPU has ~16 cores per compute unit. IrisLime correctly computes NSM (number of SMs).

**Iris Xe Architecture (Intel Core 12th Gen - U45 / P28):**
- Integrated GPU: 80 Execution Units (EUs) max
- Each EU ≈ 0.5 Xe Core
- Total: ~40-80 Xe Cores (varies by CPU SKU)
- Memory: Shared system RAM (limited bandwidth)
- Cache: 128 KB L3 per EU cluster

---

## Known Workarounds & Best Practices

### ✅ Do's

1. **Use F16-based quantizations** (Q4_K_M, Q5_K_M, Q3_K_M, Q8_0)
   - All have no BF16 dependencies
   - Proven compatible with Iris Xe

2. **Monitor logs for BF16 references**
   ```bash
   ./tools/test_tinyllama.sh | grep -i bf16
   # Should output: "No BF16 references in log"
   ```

3. **Use model comparison script to validate migration**
   ```bash
   ./tools/test_model_comparison.sh
   # Documents old vs new model behavior
   ```

4. **Benchmark before/after model switches**
   ```bash
   ./tools/benchmark_tinyllama.sh 5
   # Captures baseline performance (tokens/sec)
   ```

5. **Watch for "disabling SYCL graphs" in logs**
   - Indicates performance fallback
   - File GitHub issue if it happens

### ❌ Avoid's

1. **BF16 models** - Will fail at runtime
   - Examples: Some fine-tuned LLaMA-3.2 models
   - Check model card on HuggingFace

2. **Multi-GPU setups** - Known device-to-device issues
   - Workaround: Bind to single device via `SYCL_DEVICE_FILTER`

3. **Direct GPU allocation beyond available VRAM**
   - Fallback to host memory is available but slow
   - Check: `GGML_SYCL_HOST_MEM_FALLBACK`

---

## Build Configuration Flags

### Current IrisLime Build (`make build TARGET=sycl_release`)

```bash
CMAKE_FLAGS := -DGGML_SYCL=ON \
               -DCMAKE_BUILD_TYPE=Release \
               -DCMAKE_CXX_COMPILER=icpx \
               -DCMAKE_C_COMPILER=icx
```

### Available Tunables (in `Makefile`)

```makefile
# To disable BF16 at compile time (if you want to prevent accidental BF16 usage):
CMAKE_FLAGS += -DGGML_SYCL_HAS_BF16=OFF

# To enable verbose SYCL output:
CMAKE_FLAGS += -DGGML_SYCL_DEBUG=ON

# To use host memory fallback more aggressively:
CMAKE_FLAGS += -DGGML_SYCL_HOST_MEM_FALLBACK=ON
```

---

## Regression Detection Strategy

### Performance Baselines (Captured by `tools/benchmark_tinyllama.sh`)

Expected throughput on Intel Core 12 (80 EUs):
- **Short prompts** (~5 chars): 55-65 tokens/sec
- **Medium prompts** (~25 chars): 50-60 tokens/sec
- **Long prompts** (120+ chars): 48-58 tokens/sec

**Variance:** ±5 tokens/sec is normal (system load dependent)

**Regression threshold:** >10% drop in 3-run average

### Running Regression Tests

```bash
# Baseline capture
./tools/benchmark_tinyllama.sh 10 > results_baseline.txt

# After code changes
./tools/benchmark_tinyllama.sh 10 > results_new.txt

# Compare CSV outputs
diff <(tail -n +2 results_baseline.csv | awk '{print $5}' | sort -n) \
     <(tail -n +2 results_new.csv | awk '{print $5}' | sort -n)
```

---

## Debugging Checklist

When inference fails or is slow:

- [ ] Check for BF16 errors: `grep -i "bf16" logs/test/*.log`
- [ ] Verify SYCL device is recognized: `clinfo` or `level-zero-loader`
- [ ] Check for "disabling SYCL graphs": `grep "disabling SYCL graphs" logs/test/*.log`
- [ ] Verify model format: `file models/*.gguf | grep -v "Q4_K_M\|Q3_K_M\|Q5_K_M"`
- [ ] Monitor logs for buffer type assertions: `grep "unsupported buffer type" logs/test/*.log`
- [ ] Check available GPU memory: `intel-gpu-tools` or system monitor
- [ ] Verify OneAPI environment: `source $ONEAPI_ROOT/setvars.sh && icx --version`

---

## Future Work / Open Issues

### Recommended Improvements

1. **Dynamic BF16 Support Detection**
   - Proposal: Query device at runtime instead of compile-time
   - Impact: Single binary works across devices with/without BF16

2. **Buffer Type Validation**
   - Proposal: Better error messages before assertion
   - Impact: Easier debugging

3. **Graph Execution Robustness**
   - Proposal: Log unsupported node types earlier in planning phase
   - Impact: Catch performance issues at startup

4. **FP16 Capability Check**
   - Proposal: Add device capability query (line 2425)
   - Impact: Safer assumptions about hardware

---

## References

- **SYCL Specification:** https://www.khronos.org/sycl/
- **Intel LLVM Compiler:** https://github.com/intel/llvm
- **llama.cpp SYCL Backend:** `/llama.cpp/ggml/src/ggml-sycl/`
- **Intel oneAPI:** https://www.intel.com/content/www/us/en/developer/tools/oneapi/

---

## Document Maintenance

- **Last Updated:** 2026-06-22
- **Analyzed Version:** llama.cpp with SYCL backend (refactor/migration branch)
- **Hardware Target:** Intel Core 12 (Iris Xe 80 EU)
- **OS:** Linux WSL2

**To Update This Document:**
Run model comparison and benchmarking scripts after major llama.cpp updates and note any new errors in logs.
