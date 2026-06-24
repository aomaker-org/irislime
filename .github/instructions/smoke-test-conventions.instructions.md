---
applyTo: "tools/smoke*.py,smoke*.py"
description: >-
  IrisLime smoke test conventions. Applied when editing or creating smoke00x.py telemetry
  scripts in the tools/ directory.
---

# IrisLime Smoke Test Conventions

## Log Output

All smoke scripts must use `log_print()` (or equivalent dual-channel writer) so output
goes to both stdout and `output_stream`. The final artifact must be written to
`logs/test/` with a `YYYYMMDD_HHMM` timestamp suffix.

## Backend Table Format

Results must be emitted as a Markdown table with columns:
`| Target Configuration | Status | Latency | Execution Discovery Summary |`

Status values: `OK`, `EMPTY`, `FAIL`, `TIMEOUT` — no freeform strings.

## Process Invocation

Use `subprocess.Popen` with `bufsize=0` (unbuffered) and `text=True`.
Always set a `timeout` guard via `proc.communicate(timeout=N)` or `select`-based polling.

## Model Path Resolution

Resolve `MODEL_PATH` relative to `PROJECT_ROOT` (the parent of the `tools/` directory).
Never hardcode absolute paths. Use `os.path.join(PROJECT_ROOT, "models", MODEL_FILENAME)`.

## Error Reporting

On subprocess failure, capture both stdout and stderr into the log output.
Format: `[FAIL] <backend>: exit_code=<N> | stderr: <first 200 chars>`
