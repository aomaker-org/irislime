# 1. Establish the target structural boundaries
mkdir -p docs/sessions docs/laboratory scratch/traces scratch/prototypes logs/sandboxes

# 2. Migrate the flight-recorder session captures (The Cognitive Track)
mv gemini_001.md gemini_002.md docs/sessions/
mv gemini260630_*.md docs/sessions/
mv gemini__*.md docs/sessions/
mv gemini_013.md docs/sessions/
mv gemini_016*.md docs/sessions/

# 3. Migrate iterative task logs and standalone todos
mv todo260630_*.md docs/laboratory/

# 4. Migrate raw system telemetry and hardware diagnostic traces
mv strace_260630_0119.txt scratch/traces/
mv strace_012.txt scratch/traces/
mv strace_012_001.txt scratch/traces/

# 5. Migrate volatile local test scripts and iterative environment snapshots
mv config_env_001 config_env_002 scratch/prototypes/
mv sycl_run_test.sh sycl_run_test_013.sh scratch/prototypes/
mv test_run_sycl_13a.sh sycl_run_test_13b.sh scratch/prototypes/

# 6. Relocate standalone build logs to their backend sandboxes
mv build_sycl_20260629_195428.log logs/sandboxes/
mv build_openvino_20260630_022301.log logs/sandboxes/
