
---

## Project Telemetry & Ignored Files Tracking

To guarantee light, high-velocity repository states, `irislime` enforces a strict isolation boundary between **rebuildable local runtimes** and **essential diagnostic telemetry**:

1. **Ignored via `.gitignore`:** Heavy assets like `.venv/` and `build/` are ignored to prevent local compiling leakage.
2. **Backed up via `backup-uncovered`:** Small benchmarking results (e.g., `.local_host_telemetry.csv`, local testing logs) are zipped, packaged with host metadata descriptors, and automatically swept to Google Drive and OneDrive.
3. **Regenerated via unified tools:** Since your code manifests are kept completely synchronized, running `uv sync` inside the WSL sandbox regenerates the virtual environment in seconds.
