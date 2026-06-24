# IrisLime: Tooling & Forensic Suite

This directory contains the orchestration and forensic tools used to maintain, verify, and document the IrisLime AI inference pipeline.

## Taxonomy
* **`core/`**: Critical infrastructure, orchestration, and build logic.
* **`active/`**: Maintained scripts for daily operations (benchmarking, demo recording).
* **`forensics/`**: Scripts and logs that provide the audit trail for project performance.
* **`archived/`**: Legacy tools superseded by newer versions.

## Standard Practices
1. **Never "Throw Away":** Every script is a living document. If a tool becomes obsolete, move it to `archived/` rather than deleting it.
2. **Standardized Pathing:** All tools must use absolute path references derived from the project root.
3. **Data Hoarding:** All benchmarks and diagnostic runs must be logged and archived in `../docs/` using the `record_demo.sh` workflow.

## Key Tools
| Tool | Purpose | Status |
| :--- | :--- | :--- |
| `builder.py` | Core project orchestrator | Active |
| `multicap_runner.py` | Multi-backend llama.cpp runner with per-case forensic logs | Active |
| `openvino_healthcheck.sh` | OpenVINO-only quick healthcheck with deterministic stdin exit | Active |
| `run_demo_20260620.sh` | Performs inference matrix benchmarking | Active |
| `record_demo.sh` | Orchestrates benchmark execution and forensic logging | Active |
| `scrub` | Generates artifacts for Trust Model verification | Active |

## Execution Modes

All tools should be runnable in both modes:
1. Bare CLI (no IDE)
2. VS Code task runner (`Terminal -> Run Task...`)

When introducing a new operational tool, keep command-line arguments stable so it can be called directly from shell and from tasks in `.vscode/tasks.json`.

## Forensic Logging Rule

All build and test invocations must emit timestamped logs under `logs/build/` or `logs/test/`.

Examples:
```bash
# Build logging
TS=$(date +%Y%m%d_%H%M%S)
cmake --build build/cpu_release -j"$(nproc)" 2>&1 | tee "logs/build/cpu_release_${TS}.log"

# Test logging
python3 ./tools/multicap_runner.py
./tools/openvino_healthcheck.sh
```

## Adding New Tools
When creating a new script:
1. Include the standard header (`# Tool`, `# Purpose`, `# Created`).
2. Utilize the project root variable: `PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`.
3. Ensure the tool is marked executable (`chmod +x`).

---
*Verily, thou shalt hoard data.*
