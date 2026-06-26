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
