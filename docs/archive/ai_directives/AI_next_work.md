cat << 'EOF' > AI_next_work.md
# ==============================================================================
# Path:        AI_next_work.md
# Purpose:     Authoritative State Serialization & Backlog Manifest
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification
# Updated:     20260710_0150 (fekerr & Gemini / Synchronization Break-State)
# ==============================================================================

## 1. Active Context & Current State

We have successfully stabilized and verified the baseline runtime environment wrapper (`config_env`) and unblinded the compilation tracking architecture.

### Current State Milestones
* **Hardened Loader Completed:** `config_env` features robust volatile shell flag tracking (`_IR_ORIG_SET_U`) to protect interactive session settings during vendor overrides, short-circuited help/unset intercepts, and clean shell redirections (`>/dev/null 2>&1`).
* **Low-Overhead Session Sugar:** Parameterized prompt tagging (`. config_env TAG_NAME`) allows instant visual switches across an exception gate without triggering re-initialization or `uv sync` delays.
* **Telemetry Pipelines Unblinded:** Verified that internal makefile logging redirections (`>>`) and background forks (`&`) were causing pipe starvation, leading to a false 1800s watchdog execution.
* **SYCL Release Target Verified:** Post-refactor streaming via `infra/make/sycl.mk` confirmed successful, logging a flawless 76-second compilation pass directly inside `telemetry_builds.csv`.

---

## 2. Established Code & System Architectural Requirements

Any agent or compiler loop mutating this workspace MUST adhere to these explicit constraints:

* **Idempotency Paramount:** Environment files must cleanly short-circuit via `IRISLIME_READY` checks unless explicitly overriden via a `force` parameter pass.
* **Forensics Transparency:** All logging outputs are treated as forensic evidence. They must be routed directly to visible, structured `./logs/` audit paths rather than hidden in a `.local/` stash space.
* **Streaming Integrity:** Lower-level component makefiles (`infra/make/*.mk`) must stream text lines directly to `stdout`/`stderr`. They must not manage background operations or run internal file appendages, preserving the parent Python runner's line-trapping visibility.
* **Shortcut Symmetry:** Terminal aliases must preserve a strict 1:1 filename mapping name to their underlying script files (e.g., `files2clip` mapping cleanly to `tools/files2clip`) to ensure transparent self-documentation.
* **Decoupled Model Staging:** Heavy binary artifacts reside one layer up in a sibling directory (`../models/`), completely decoupled from the active repository compilation trees.

---

## 3. High-Priority Technical Backlog

When communications resume, execute the following implementation tracks in sequence:

### 🚀 Track A: Documentation Alignment Pass
* **Objective:** Bring core documentation up to 2026 specification standards.
* **Action:** Extract and rewrite `README.md` and `QUICKSTART.md` to formally integrate the new parameterized `. config_env [tag]` interfaces, 1:1 utility aliases, and the external `../models/` directory topography.

### 🚀 Track B: Intelligent Progress Watchdog Integration
* **Objective:** Shield long, silent compiler loops (such as heavy Vulkan shader translations or linking cycles) from false watchdog kills.
* **Action:** Patch `tools/build_runner.py` to complement standard pipe streaming with an atomic metadata filesystem check (`st_mtime` inode scans via `pathlib`) when communication streams fall silent, allowing the compiler to keep running if disk output is steadily advancing.

### 🚀 Track C: Event-Driven, Low-Overhead Telemetry
* **Objective:** Collect system vitals (CPU load, RAM footprint, landmarks) without introducing runtime processing delays.
* **Action:** Implement an asynchronous background logging thread inside `build_runner.py` executing a low-cost, 1Hz native Linux memory read of `/proc/stat` and `/proc/meminfo`.
* **Action:** Integrate conditional event triggers (high CPU load, prolonged silence, or regex matches on `[100%] Built target`) to gate more expensive Windows host boundary queries (core temperatures, battery drain metrics) through a dampened cooldown filter.

# ==============================================================================
# Context Boundary: AI_next_work.md_Complete
# ==============================================================================
EOF

echo "[+] State manifest successfully serialized to AI_next_work.md"
