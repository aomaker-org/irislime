# IrisLime Codebase Knowledge Graph

A comprehensive map of the IrisLime project structure, dependencies, data flow, and module interactions.

---

## Project Overview

```
IrisLime Project
│
├─ Purpose: Local LLM inference on Intel Iris Xe GPU (WSL2/Linux)
├─ Language: Python (orchestration), C++ (llama.cpp engine)
├─ GPU Backend: SYCL via Intel oneAPI
├─ Model Format: GGUF (quantized)
└─ Primary Use Case: Edge AI research on integrated graphics
```

---

## Component Architecture

### Layer 1: User Interface

```
┌─────────────────────────────────────┐
│  User Interaction                   │
│  - doit.sh (entry point)            │
│  - tools/test_tinyllama.sh          │
│  - tools/test_model_comparison.sh   │
│  - tools/benchmark_tinyllama.sh     │
└──────────────┬──────────────────────┘
               │
          (invokes)
               │
```

### Layer 2: Python Orchestration

```
┌──────────────────────────────────────────┐
│  Python Tools (tools/ directory)         │
├──────────────────────────────────────────┤
│ ✓ config_env               [Environment setup]
│ ✓ builder.py               [Build orchestration]
│ ✓ model_manager.py         [HuggingFace download]
│ ✓ hardware.py              [GPU detection]
│ ✓ check_env.sh             [Diagnostics]
│                                          │
│ Interactions:                            │
│ - config_env → ONEAPI env vars          │
│ - builder.py → CMake orchestration      │
│ - model_manager.py → HF CLI             │
│ - hardware.py → Level Zero / OpenCL     │
└──────────────┬───────────────────────────┘
               │
          (orchestrates)
               │
```

### Layer 3: Build System (CMake)

```
┌─────────────────────────────────────┐
│ CMake Configuration                 │
├─────────────────────────────────────┤
│ Makefile (TARGET=sycl_release)      │
│   ↓                                  │
│ CMakeLists.txt (llama.cpp)          │
│   ├─ SYCL Backend (-DGGML_SYCL=ON)  │
│   ├─ Intel Compiler (icpx/icx)      │
│   ├─ Release Optimization           │
│   └─ Link Intel oneAPI libs         │
│                                      │
│ Output: build/sycl_release/bin/     │
│ - llama-cli (inference engine)      │
│ - llama-quantize (model convert)    │
│ - [... other tools ...]             │
└──────────────┬──────────────────────┘
               │
          (produces)
               │
```

### Layer 4: C++ Inference Engine (llama.cpp Fork)

```
┌────────────────────────────────────────────┐
│ llama.cpp (SYCL Backend)                   │
├────────────────────────────────────────────┤
│ llama/                                     │
│ ├─ src/llama.cpp       [LLM core]        │
│ ├─ src/llama-cli.cpp   [CLI interface]   │
│ └─ include/llama.h     [LLM API]         │
│                                            │
│ ggml/                                      │
│ ├─ src/ggml-sycl/      [SYCL kernels]    │
│ │  ├─ ggml-sycl.cpp    [Main dispatcher]│
│ │  ├─ binbcast.cpp     [Binary ops]     │
│ │  ├─ gemm.hpp         [Matrix ops]     │
│ │  ├─ convert.cpp      [Type convert]   │
│ │  ├─ concat.cpp       [Concatenate]    │
│ │  ├─ common.hpp       [BF16 config]    │
│ │  └─ [... 50+ ops ...]                │
│ ├─ src/ggml.c          [GGML core]     │
│ └─ include/ggml*.h     [GGML API]       │
│                                            │
│ Critical Issues Here:                      │
│ ❌ BF16 ops unsupported on Iris Xe       │
│ ⚠️  Device-to-device GPU transfer broken │
│ ⚠️  Graph execution accuracy concerns    │
└────────────────────┬───────────────────────┘
                     │
                (computes)
                     │
```

### Layer 5: Runtime Execution

```
┌──────────────────────────────────┐
│ Runtime (SYCL Level Zero)        │
├──────────────────────────────────┤
│ Level Zero API                   │
│   ├─ GPU device discovery        │
│   ├─ Memory management           │
│   ├─ Command queue / submission  │
│   └─ Event synchronization       │
│                                   │
│ Intel GPU Driver                 │
│   └─ Iris Xe (80 EU)            │
│       ├─ ~40-80 Xe Cores        │
│       ├─ Shared system RAM       │
│       └─ 128KB L3 cache/cluster │
└──────────────────────────────────┘
```

### Layer 6: Data Storage

```
┌──────────────────────────────┐
│ Data Layer                   │
├──────────────────────────────┤
│ models/                      │
│ └─ tinyllama-1.1b-*.gguf   │
│    (symlink to ~/src/ai_models)
│                              │
│ logs/                        │
│ ├─ test/                     │
│ │  ├─ tinyllama_test_*.log  │
│ │  ├─ model_comparison_*.log│
│ │  ├─ benchmark_*.log       │
│ │  └─ benchmark_results.csv │
│ ├─ build/                    │
│ │  └─ [build logs]          │
│ └─ debug/                    │
│    └─ [GPU debug output]    │
└──────────────────────────────┘
```

---

## Data Flow Diagram

### Inference Pipeline

```
User Input (prompt)
      │
      ▼
[llama-cli] 
      │
      ├─→ Load model from GGUF file
      │       │
      │       ▼
      │   [Parse GGUF header]
      │       │
      │       ▼
      │   [Allocate GPU memory]
      │       │
      │       ▼
      │   [Copy weights to GPU]
      │
      ├─→ Tokenize input
      │
      ├─→ Forward pass (loop):
      │   ├─ [llama_model_forward]
      │   │   │
      │   │   ├─ [embedding lookup]
      │   │   ├─ [positional encoding]
      │   │   │
      │   │   ├─→ For each transformer layer:
      │   │   │   ├─ [self-attention]
      │   │   │   │   ├─ [linear Q,K,V] → gemm.hpp
      │   │   │   │   ├─ [softmax] → binbcast.cpp
      │   │   │   │   └─ [attention weights × values] → gemm.hpp
      │   │   │   ├─ [layer norm] → normalize ops
      │   │   │   ├─ [feed-forward MLP] → gemm.hpp
      │   │   │   └─ [residual connections] → binbcast.cpp
      │   │   │
      │   │   └─ [final layer norm]
      │   │
      │   ├─ [logits → probabilities (softmax)]
      │   ├─ [sample next token]
      │   └─ [add to output]
      │
      ▼
  Output (generated text)
      │
      └─→ Log to logs/test/*.log
```

### GPU Operation Dispatch

```
ggml_compute_forward_OPERATION()
      │
      ▼
[ggml_sycl.cpp dispatcher]
      │
      ├─ Check operation type
      ├─ Check tensor types (F32, F16, BF16, I32, ...)
      │
      ├─→ BF16 tensors detected
      │   │
      │   ├─ Check #ifdef GGML_SYCL_HAS_BF16
      │   │
      │   ├─ YES: Try GPU kernel
      │   │   └─ ❌ FAILS on Iris Xe (no hardware support)
      │   │       └─ → "unsupported types" error
      │   │
      │   └─ NO: (if macro disabled at compile time)
      │       └─ → Fall through to error
      │
      ├─→ F16 tensors detected ✅
      │   └─ Dispatch to SYCL kernel [WORKS]
      │
      └─→ Other types (F32, I32, etc.)
          └─ Dispatch accordingly
```

---

## Dependency Tree

### External Dependencies

```
IrisLime
│
├─ Intel oneAPI Base Toolkit
│  ├─ icpx (C++ compiler)
│  ├─ icx (C compiler)
│  ├─ Level Zero (GPU API)
│  ├─ SYCL runtime
│  └─ oneMKL (optional optimization)
│
├─ HuggingFace Hub
│  └─ huggingface-hub Python package
│
├─ Python 3.x
│  └─ venv (virtual environment)
│
└─ llama.cpp fork (aomaker-org/llama.cpp)
   ├─ SYCL backend modifications
   ├─ BF16 handling (problematic on Iris Xe)
   └─ GGUF support
```

### Internal Dependencies

```
config_env
  │
  ├─ Activates: venv/
  ├─ Sources: $ONEAPI_ROOT/setvars.sh
  └─ Sets: IRISLIME_READY env var

Makefile (build TARGET=sycl_release)
  │
  ├─ Requires: config_env activated
  ├─ Calls: cmake (llama.cpp)
  ├─ Produces: build/sycl_release/bin/llama-cli
  └─ Uses: icpx compiler

tools/test_tinyllama.sh
  │
  ├─ Requires: config_env activated
  ├─ Requires: build/sycl_release/bin/llama-cli
  ├─ Uses: models/tinyllama-*.Q4_K_M.gguf
  └─ Produces: logs/test/tinyllama_test_*.log

tools/benchmark_tinyllama.sh
  │
  ├─ Requires: config_env activated
  ├─ Requires: build/sycl_release/bin/llama-cli
  ├─ Uses: models/tinyllama-*.Q4_K_M.gguf
  ├─ Produces: logs/test/benchmark_*.log
  └─ Produces: logs/test/benchmark_results_*.csv
```

---

## Critical Code Paths

### Model Loading Path

```
llama-cli --model tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

1. [llama-cli.cpp] main()
   ├─ Parse arguments
   ├─ Create SYCL context (ggml_backend_sycl_init())
   │  └─ Query GPU device (Level Zero)
   │  └─ Allocate buffers
   │
   ├─ Load model (llama_load_model_from_file())
   │  ├─ Read GGUF file header
   │  ├─ Check tensor types (F16, BF16, Q4_K_M, etc.)
   │  ├─ Copy weights to GPU memory
   │  │  └─ ISSUE: If BF16 tensors → GPU doesn't support
   │  └─ Create context (llama_new_context_with_model())
   │
   └─ Run inference loop
      └─ (see Data Flow section above)
```

### Type Mismatch Error Path

```
If model has BF16 tensors:

1. Model loaded successfully (weights in GPU memory)
2. Forward pass begins
3. Operation requires BF16 computation
4. Dispatch to ggml_sycl_op_bin_bcast()
   │
   ├─ Check src0->type: BF16 ✓
   ├─ Check src1->type: BF16 ✓
   ├─ Check dst->type: BF16 ✓
   │
   └─ Lookup type handler
      │
      ├─ if (BF16 && #ifdef GGML_SYCL_HAS_BF16)
      │  └─ Try GPU kernel
      │  └─ ❌ Fails (no hardware support)
      │
      └─ else
         └─ fprintf(stderr, "unsupported types...")
         └─ GGML_ABORT("fatal error")
```

---

## Known Issues & Bottlenecks

### Critical Path

1. **BF16 Type Support** (BLOCKING)
   - Location: `llama.cpp/ggml/src/ggml-sycl/common.hpp` lines 34-37
   - Impact: Runtime failure
   - Status: ✅ MITIGATED (model swap)
   - Fix: Use F16-based models

2. **Device Capability Checks** (TODO)
   - Location: `ggml-sycl.cpp` line 2425
   - Impact: Unsafe FP16 assumptions
   - Status: ⚠️ LOW PRIORITY
   - Fix: Add device query

### Optimization Opportunities

1. **Graph Mode Robustness** (Medium priority)
   - Logs disabling if unsupported ops found
   - Could be caught earlier

2. **GEMM Operation Selection** (Low priority)
   - Different algorithms available (MMQ, etc.)
   - Trade accuracy for speed

3. **Memory Allocation Strategy** (Low priority)
   - Host fallback available but slow
   - Could optimize pinned memory usage

---

## Build Artifact Map

After `make build TARGET=sycl_release`:

```
build/sycl_release/
│
├─ CMakeLists.txt (generated)
├─ CMakeCache.txt
├─ compile_commands.json (for IDE integration)
│
├─ bin/ (Executables)
│  ├─ llama-cli ⭐ (MAIN: inference engine)
│  ├─ llama-quantize (model quantization)
│  ├─ llama-convert-llama2c-to-ggml
│  ├─ llama-benchmark
│  ├─ llama-perplexity
│  ├─ llama-embedding
│  └─ [... 30+ other tools]
│
├─ lib/ (Libraries)
│  ├─ libggml.so.0
│  ├─ libggml-base.so.0
│  ├─ libggml-sycl.so.0 ⭐ (SYCL backend)
│  └─ libllama.so.0
│
├─ common/ (Shared utilities)
├─ ggml/ (GGML library)
├─ src/ (llama.cpp source)
├─ tools/ (Helper tools)
└─ vendor/ (Dependencies)
```

---

## Testing Infrastructure

```
Test Execution Flow:

User: ./tools/test_tinyllama.sh "prompt"
      │
      ▼
   [bash script]
      │
      ├─ Verify environment (config_env)
      ├─ Verify build exists
      ├─ Call llama-cli
      │  ├─ Load model
      │  ├─ Tokenize prompt
      │  ├─ Run forward pass (GPU)
      │  └─ Generate output
      │
      ├─ Capture stdout/stderr to logs/test/*.log
      ├─ Check for "bf16" in log
      │  └─ If found: ❌ FAIL
      │  └─ If not: ✅ PASS
      │
      └─ Print result to console

Results stored in:
- logs/test/tinyllama_test_YYYYMMDD_HHMMSS.log
- logs/test/model_comparison_YYYYMMDD_HHMMSS.log
- logs/test/benchmark_tinyllama_YYYYMMDD_HHMMSS.log
- logs/test/benchmark_results_YYYYMMDD_HHMMSS.csv
```

---

## Environment Variable Configuration

Critical path for GPU access:

```
shell startup
    │
    ▼
source config_env
    │
    ├─ Activate venv/
    │  └─ PATH includes Python packages
    │
    ├─ Source $ONEAPI_ROOT/setvars.sh
    │  ├─ PATH += Intel LLVM bin/
    │  ├─ LD_LIBRARY_PATH += oneAPI libs
    │  ├─ ONEAPI_ROOT set
    │  └─ Level Zero drivers enabled
    │
    └─ Export IRISLIME_READY=1
       └─ Guards: Makefile, build scripts
```

---

## Future Extensions

### Potential Add-ons

1. **Multi-Model Server**
   - Running multiple models in parallel
   - Depends on: GPU memory, sharing strategy

2. **Quantization Pipeline**
   - Convert HF models to GGUF offline
   - Depends on: model_manager.py enhancement

3. **Performance Profiler**
   - Layer-by-layer timing breakdown
   - Depends on: SYCL event logging

4. **A/B Testing Framework**
   - Compare model variants quantization-wise
   - Depends on: benchmark script enhancement

---

## Documentation Cross-References

- **Model Acquisition:** [docs/MODEL_ACQUISITION.md](MODEL_ACQUISITION.md)
- **SYCL Compatibility:** [docs/SYCL_IRIS_XE_ANALYSIS.md](SYCL_IRIS_XE_ANALYSIS.md)
- **Testing Guide:** [tools/TESTING_README.md](../tools/TESTING_README.md)
- **Getting Started:** [getting_started.md](../getting_started.md)

---

## Maintenance Notes

**Last Updated:** 2026-06-22

**To Update This Graph:**
- After significant code changes to llama.cpp
- When new kernel operations are added
- When new GPU device targets are supported
- When environment/build process changes

**Verification:**
- Run full test suite
- Capture new log patterns
- Update critical path documentation
