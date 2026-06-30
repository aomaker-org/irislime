# IrisLime: Project Backlog

## Pending Features & Improvements
- [ ] **Forensic Metadata:** Capture `git rev-parse HEAD` in `build_meta.json` to track the exact version of `llama.cpp` used in every build.
- [ ] **Log Cleanup Utility:** Create a script to archive or purge logs older than 30 days to manage disk space.
- [ ] **Performance Benchmarking:** Add a `run-bench.sh` script to log inference speed (tokens/sec) alongside the build metadata.

## Known Issues
- [ ] None at the moment; build pipeline is currently active.

- [ ] **Documentation: Reconstruct Pristine Quick Start Blueprint**
      - Target: Manually re-assemble `quick_start.md` using VS Code's local environment to bypass web browser clipboard parsing bottlenecks.
      - Action: Use the verified layout strings captured inside `run_test_003.txt` to stitch together Steps 1 through 5, ensuring all inner triple-backtick fences are fully intact.

- [ ] **Tooling: Integrate Primality Header Daemon to Bash/Zsh Prompt**
      - Target: Shift the obscure primality calculation out of the cloud and down to local silicon inside `scratch/boot.sh`.
      - Action: Implement a lightweight bash array or math expression parsing engine to automatically intercept the current history integer count, check its congruence properties, and dynamically update the `$PS1` telemetry string with its algebraic signature without blocking terminal redraw latencies.

- [ ] **Infrastructure: Enforce GitHub Branch Protection Rules**
      - Target: Upstream `main`/`master` branch settings via the repository web interface.
      - Action: Lock down direct force-pushes, mandate linear commit tracking histories, and configure strict branch boundary status checks to shield your core production architecture.


# === HISTORICAL TODO INGESTION MATRIX: 20260630 ===
# IrisLime Engineering Ideation & Task Ledger
# Date Stamp:  20260630
# Timestamp:   20260630_0034
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Baseline:    Idempotent, non-destructive tracking context

## [20260630_0034] - System Architecture Brainstorming Matrix

- [ ] TODO-01: Standardize explicit compiler flags across all sub-makefiles (`infra/make/*.mk`). Force `-march=native`, `-flto`, and specify the microarchitectural target target context (`intel_gpu_tgllp`) for the SYCL engine to accelerate IGC compilation.
- [ ] TODO-02: Design a cloud offload pipeline using GitHub Actions. Provision a high-memory runner profile to bypass local memory constraints during Flash Attention template instantiation passes.
- [ ] TODO-03: Implement an out-of-process log monitor (`infra/log_monitor.py`) utilizing Linux `inotify` APIs. The daemon will capture raw compiler logs in real-time, injecting sub-second micro-timestamps and stream tracking tags (`[STDOUT]/[STDERR]`) without changing the underlying CMake configuration.
- [ ] TODO-04: Evaluate a Rust-centric parallel compute fallback using the Hugging Face Candle or Ratchet WebGPU frameworks. This will eliminate heavy C++ compile-time dependency trees while keeping execution speeds close to bare metal.
- [ ] TODO-05: Explore profile-guided optimization (PGO) pipelines to automate thread mapping across Intel hybrid P/E core layouts based on real-time hardware telemetry logs.

## Notes & Observations
The SYCL build stall at 22% confirms severe memory-bus and cache starvation when compiling high-density matrix template instances. Forcing memory-aware boundaries inside `infra/make/base.mk` resolves the issue locally, but offloading heavy builds to cloud compute contexts remains the most robust long-term architecture for automated agent workflows. All logs should be tracked inside a dedicated `logs/` directory tree to maintain maximum project observability.

# end of todo260630.md
# Workspace Architecture Blueprint: Nested Git Repositories & Sandboxing

## 1. Single-Stroke Initialization Workflow
To optimize session initialization and maintain upstream repository sterility, local prompt adjustments are completely decoupled from shared tracking files. Sourcing the private boot script evaluates the environment and updates shell telemetry in a single transaction path.

```bash
# Entry point for local development sessions
. scratch/boot.sh
echo "hmm"

## [2026-06-25 12:05 PDT] Meta-Task: Standardize Log Nomenclature
- Target: Refactor the scratchpad document taxonomy from sequential indexing to a temporal schema.
- Action: Transition `scratch/todo_001.md` to a strict datestamp tracking format (e.g., `20260625_1205.md` or a continuous timeline ledger).
- Purpose: Ensure task indices maintain absolute chronological context, preventing namespace collisions as parallel research iterations diverge.

# EPILOG: Expected filename on drive: scratch/todo_001.md

## [2026-06-25 12:07 PDT] Strategy: Enforce Universal GDB Execution Wrappers
- Target: Isolate and trace low-level hardware runtime crashes within the SYCL engine.
- Mechanism: Build a reusable non-interactive GDB execution wrapper to catch segmentation faults dynamically.
- Action: Execute all memory-unsafe binaries and discovery primitives through batch-mode debugging to auto-extract core dump backtraces (`bt`) immediately upon memory fault occurrences.

# EPILOG: Expected filename on drive: scratch/todo_001.md
