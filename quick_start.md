# IrisLime Quick Start Deployment Recipe

This guide is the friction-free installation sequence for bringing up the IrisLime development environment on a newly cloned machine. Follow these exact terminal steps to link your trees, arm the environment, and execute your first hardware validation test.

# Create a centralized local storage directory for model binaries and link it
mkdir -p ~/src/ai_models
ln -sf ~/src/ai_models models
```

## Step 2: Initialize the Environment & Dependencies
Initialize the Python virtual environment and pull in required orchestration assets using the master Makefile:

```bash
cd ~/src/irislime

# Initialize the virtual environment and install dependencies
make setup
```

## Step 3: Boot the Shell Session
Always source the private boot utility before compiling or running tests. This loads the Intel oneAPI toolchain compiler variables, activates the Python environment, and transforms your prompt to display active execution history counters:

```bash
. scratch/boot.sh
```
*Note: You must **source** this script using `.` or `source`. Do not execute it directly.*

## Step 4: Fire the Hardware Validation Test
Run the latest unfiltered validation script to verify that your host machine's hardware profile is recognized and that the graphics layer can be reached safely via the OpenCL driver bypass:

```bash
bash scratch/run_test002.sh
```

## Step 5: Verify the Execution Output
Once the test concludes, check that your environment successfully generated your unique hardware logs:
1. **The Raw Log:** Review `scratch/run_test_002_console_*.log` to see the complete, unfiltered GDB terminal stream.
2. **The Results Ledger:** Review `scratch/run_test_002.md` to see your machine's specific CPU identifier and execution status cleanly appended to the tracking table.
