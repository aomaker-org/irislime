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
