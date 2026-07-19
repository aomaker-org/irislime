# Forensic Analysis: The Heredoc Escaping Paradox & Documentation Overhaul

## 1. Issue Overview
During the execution of snapshot extraction tools, specifically `scratch/gather_snapshot.sh`, a "Heredoc Escaping Paradox" occurred.
The delivery layer (using `cat << 'EOF' > ...`) was so strict that it preserved escape tokens (`\$`) into the execution buffer,
causing git commands like `$(git branch --show-current)` to be printed as literal text instead of executing.

## 2. Remediation: Script Fixes
* **Fixed Script Execution Phase**: Modified `scratch/gather_snapshot.sh` to correctly strip the backslashes so bash expands the commands properly. This avoids the double-escape collision.
* **Result**: `$(git branch --show-current)` and `$(git rev-parse HEAD)` now evaluate dynamically and capture actual project state.

## 3. Remediation: Documentation Stratum
* **Bypassed Clipboard Artifacts**: Identified that previous clipboard logs were corrupted during Windows-to-WSL transitions.
* **Recovered Training Data**: Ran the provided `deploy_docs.sh` atomic injection shell script found in `scratch/20260627_1719-work_in_progress.txt`.
* **Restored Nodes**:
  - `README.md`
  - `quick_start.md`
  - `getting_started.md`
  - `training/README.md` (and related architectural guides)
* Committed the recovered pristine documentation layer.

## 4. Current State
* The project's active tree is stable.
* The local index is clean after consolidating the documentation and snapshot logic fixes.
