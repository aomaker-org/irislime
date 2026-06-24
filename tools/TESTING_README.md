# IrisLime Testing Scripts

Comprehensive testing suite for validating TinyLlama-1.1B model compatibility and performance on Intel Iris Xe.

## Quick Start

```bash
source config_env
make build TARGET=sycl_release  # If not already built

# Optional: build OpenVINO variant (already logs to logs/build/)
./tools/build_openvino.sh

# Test the new model
./tools/test_tinyllama.sh

# Compare old vs new model
./tools/test_model_comparison.sh

# Benchmark performance
./tools/benchmark_tinyllama.sh 5  # Run 5 iterations

# New: run all available backends with robust stdin capture
python3 ./tools/multicap_runner.py

# New: OpenVINO-only healthcheck
./tools/openvino_healthcheck.sh
```

## Bare CLI and VS Code (Both Supported)

Every workflow below is supported in two modes:

1. Bare CLI (no IDE): run commands directly in shell.
2. VS Code task runner: use `Terminal -> Run Task...` and choose the matching task.

Available tasks in `.vscode/tasks.json`:
- `🔨 BUILD OPENVINO BACKEND`
- `🧪 RUN MULTICAP (PY)`
- `🩺 OPENVINO HEALTHCHECK`

---

## New Script: `multicap_runner.py`

**Purpose:** Run `llama.cpp` in multiple backend/build variants with deterministic input handling and forensic logs.

**Why this exists:**
- Prevents interactive prompt hangs by injecting two stdin lines (`<prompt>`, then `/exit`).
- Captures each backend run to a dedicated log file.
- Produces a single summary table log for quick triage.

**CLI usage:**
```bash
python3 ./tools/multicap_runner.py
python3 ./tools/multicap_runner.py --model ./models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf --openvino-device GPU
```

**Output artifacts:**
- Summary: `logs/test/llama_multi_capture_YYYYMMDD_HHMMSS.log`
- Per-method logs, e.g.:
	- `logs/test/cpu_release_ngl0_YYYYMMDD_HHMMSS.log`
	- `logs/test/sycl_release_SYCL0_YYYYMMDD_HHMMSS.log`
	- `logs/test/openvino_release_YYYYMMDD_HHMMSS.log`

**Device behavior:**
- SYCL device token is auto-discovered from `--list-devices` output (e.g. `SYCL0`).
- OpenVINO device is controlled with `--openvino-device` or `GGML_OPENVINO_DEVICE`.

---

## New Script: `openvino_healthcheck.sh`

**Purpose:** Fast OpenVINO-only verdict with forensic log capture.

**CLI usage:**
```bash
GGML_OPENVINO_DEVICE=GPU ./tools/openvino_healthcheck.sh
./tools/openvino_healthcheck.sh ./models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf
```

**Behavior:**
- Uses non-interactive stream injection (`prompt` then `/exit`).
- Runs OpenVINO backend only.
- Returns process exit code and writes timestamped forensic log.
- Uses hardened defaults for Iris Xe stability:
	- `GGML_OPENVINO_DEVICE=GPU`
	- `GGML_OPENVINO_DISABLE_CACHE=1`
	- `--single-turn --n-predict 1`
	These avoid known OpenVINO tensor-shape/cache reuse mismatches seen with longer interactive runs.

**Output artifact:**
- `logs/test/openvino_healthcheck_YYYYMMDD_HHMMSS.log`

---

## Existing `llama.cpp` Test Methods

There are two existing upstream test execution styles:

1. CTest-registered tests from build tree:
```bash
cd build/cpu_release
ctest -N
ctest --output-on-failure -R "test-log|test-tokenizer-1-llama-spm"
```

2. Direct test binaries in `build/*/bin/test-*`:
```bash
./build/cpu_release/bin/test-log
./build/cpu_release/bin/test-tokenizer-0 ./llama.cpp/models/ggml-vocab-llama-spm.gguf
```

Note: some CTest entries may be registered while corresponding binaries are not yet built in a partial build tree. In that case, complete or rebuild the relevant target set.

---

## Forensic Logging Policy (Build + Test)

All build and test runs should produce timestamped artifacts under `logs/`.

Recommended build logging examples:
```bash
# CPU release
TS=$(date +%Y%m%d_%H%M%S)
cmake --build build/cpu_release -j"$(nproc)" 2>&1 | tee "logs/build/cpu_release_${TS}.log"

# SYCL release
TS=$(date +%Y%m%d_%H%M%S)
cmake --build build/sycl_release -j"$(nproc)" 2>&1 | tee "logs/build/sycl_release_${TS}.log"

# Vulkan release
TS=$(date +%Y%m%d_%H%M%S)
cmake --build build/vulkan_release -j"$(nproc)" 2>&1 | tee "logs/build/vulkan_release_${TS}.log"

# OpenVINO release (already integrated)
./tools/build_openvino.sh
```

Recommended test logging examples:
```bash
TS=$(date +%Y%m%d_%H%M%S)
cd build/cpu_release && ctest --output-on-failure 2>&1 | tee "../../logs/test/ctest_cpu_${TS}.log"

python3 ./tools/multicap_runner.py
./tools/openvino_healthcheck.sh
```

Keep logs append-only and immutable for later regression and incident forensics.

## Scripts Overview

### 1. `test_tinyllama.sh` — Basic Inference Test

**Purpose:** Verify TinyLlama-1.1B model runs without BF16 errors on Iris Xe

**Usage:**
```bash
./tools/test_tinyllama.sh [prompt]
```

**Examples:**
```bash
./tools/test_tinyllama.sh                                    # Default prompt
./tools/test_tinyllama.sh "What is artificial intelligence?"
./tools/test_tinyllama.sh "Hello, how are you?"
```

**Output:**
- Inference results
- BF16 error detection (should be NONE)
- Log saved to: `logs/test/tinyllama_test_YYYYMMDD_HHMMSS.log`

**Success Indicator:**
```
✅ SUCCESS: Model inference completed without BF16 errors
```

**Forensic Logging:**
- Timestamp of execution
- Model path and CLI path
- Prompt used
- Exit code
- BF16 compatibility status

---

### 2. `test_model_comparison.sh` — Old vs New Model Comparison

**Purpose:** Document whether switching from Llama-3.2-1B to TinyLlama fixes BF16 issues

**Usage:**
```bash
./tools/test_model_comparison.sh [prompt]
```

**Example:**
```bash
./tools/test_model_comparison.sh "What is the capital of France?"
```

**What It Does:**
1. Tests old model (Llama-3.2-1B) — expects BF16 errors
2. Tests new model (TinyLlama-1.1B) — expects success
3. Generates comparison report

**Output:**
```
--- OLD Model (Llama-3.2-1B) ---
Result: ❌ BF16 ERROR DETECTED (as expected)

--- NEW Model (TinyLlama-1.1B) ---
Result: ✅ SUCCESS - No BF16 errors

=== COMPARISON SUMMARY ===
✅ MIGRATION SUCCESSFUL: Old model failed, new model works
```

**Forensic Artifact:**
- Log: `logs/test/model_comparison_YYYYMMDD_HHMMSS.log`
- Shows exact error messages from old model
- Documents successful migration

---

### 3. `benchmark_tinyllama.sh` — Performance Benchmarking

**Purpose:** Measure inference speed (tokens/sec) across multiple runs for consistency

**Usage:**
```bash
./tools/benchmark_tinyllama.sh [iterations]
```

**Examples:**
```bash
./tools/benchmark_tinyllama.sh        # 3 iterations (default)
./tools/benchmark_tinyllama.sh 10     # 10 iterations for better statistics
```

**Tests Multiple Prompts:**
- Short: "Hello" (5 chars)
- Medium: "What is machine learning?" (26 chars)
- Long: Multi-sentence question (120+ chars)

**Output Artifacts:**
1. **Log file:** `logs/test/benchmark_tinyllama_YYYYMMDD_HHMMSS.log`
2. **Results CSV:** `logs/test/benchmark_results_YYYYMMDD_HHMMSS.csv`

**CSV Format:**
```csv
prompt_length,iteration,tokens_predicted,time_elapsed_sec,tokens_per_sec
5,1,128,2.345,54.59
...
```

**Quick Stats:**
```
Average throughput: 52.34 tokens/sec
```

**Forensic Value:**
- Baseline performance metrics for Iris Xe
- Consistency check (variance across runs)
- Hardware stress testing
- Regression detection (if performance drops in future runs)

---

## Workflow for Model Migration Validation

### Step 1: Basic Functionality Test
```bash
./tools/test_tinyllama.sh "Hello, test this!"
```
✅ Verify no BF16 errors

### Step 2: Comparison Test (Document Migration)
```bash
./tools/test_model_comparison.sh
```
✅ Prove old model was broken, new model works

### Step 3: Performance Baseline
```bash
./tools/benchmark_tinyllama.sh 5
```
✅ Record baseline performance for future regression detection

### Step 4: Archive Results
```bash
cp logs/test/benchmark_results_*.csv docs/benchmarks/
```
✅ Keep forensic record of performance over time

---

## Log File Locations

All test results are saved in append-only log files:

```
logs/test/
├── tinyllama_test_20260622_083500.log      # Basic inference test
├── model_comparison_20260622_083530.log    # Old vs new comparison
├── benchmark_tinyllama_20260622_083600.log # Full benchmark log
└── benchmark_results_20260622_083600.csv   # Performance CSV
```

**Why Append-Only?**
- **Forensic trail:** Never lose evidence of what was tested
- **Regression detection:** Compare performance across time
- **Reproducibility:** Future developers see exactly what was tested and when
- **Debugging:** Full history if issues emerge later

---

## Troubleshooting

### Script Fails: "IrisLime environment not loaded"
```bash
source config_env
```

### Script Fails: "llama-cli not found"
Build the project first:
```bash
make build TARGET=sycl_release
```

### Script Fails: "Model not found"
Verify model was downloaded:
```bash
ls -lh models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```
Should be ~638 MB

### BF16 Errors Still Appearing
Check that the correct model is being used:
```bash
file models/tinyllama-*.gguf
```
Ensure it's Q4_K_M (not Q8_0 or F32)

### Performance is Very Slow
- Check GPU device is active: `clinfo` or `level-zero-loader`
- Verify SYCL backend is being used: add `--verbose` to llama-cli
- Try Q3_K_M quantization (smaller, faster, slightly lower quality)

---

## Integration with CI/CD

To run these tests in automated pipelines:

```bash
#!/bin/bash
set -e

source config_env
make build TARGET=sycl_release

# Run all tests
./tools/test_tinyllama.sh "Test prompt"
./tools/test_model_comparison.sh "Test prompt"
./tools/benchmark_tinyllama.sh 3

# Archive results
mkdir -p build_artifacts
cp logs/test/*.log build_artifacts/
cp logs/test/*.csv build_artifacts/
```

---

## Model Selection Notes

**Why TinyLlama-1.1B instead of Llama-3.2-1B?**
- ✅ Q4_K_M (F16-based) — no BF16 support issues
- ✅ 638 MB — similar footprint to original
- ✅ Proven Iris Xe compatibility
- ✅ Faster inference (1.1B vs 3.2B parameters)

**Alternative Models (if you want to switch later):**
```bash
# In models/ directory, other quantizations are available:
ls models/tinyllama-*.gguf

# Smaller/faster: Q3_K_M (526 MB)
# Larger/higher quality: Q5_K_M (747 MB)
```

---
