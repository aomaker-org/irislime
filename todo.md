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
