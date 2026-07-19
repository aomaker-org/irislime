# IrisLime Quick Start Deployment Recipe

This guide provides the streamlined installation sequence for bringing up the IrisLime exploration environment on a newly cloned machine. Follow these terminal steps sequentially to link your source trees, activate the shell session variables, and run your baseline driver validation check.

## Step 1: Establish Sibling Tree Architecture
The workspace requires your custom `llama.cpp` inference engine fork to reside as a direct directory sibling to the `irislime` project root workspace.

Execute this terminal block to verify directory structures and establish the required development symlinks:

```bash
# Navigate to your central development root
cd ~/src

# Clone the custom organization engine fork if not already cached on disk
git clone git@github.com:aomaker-org/llama.cpp.git

# Enter the active project repository space
cd ~/src/irislime

# Link the sibling engine repository into the active workspace
ln -sf ../llama.cpp llama.cpp

# Create a centralized local folder for high-density model binaries and link it
mkdir -p ~/src/ai_models
ln -sf ~/src/ai_models models

```

## Step 2: Initialize Virtual Environment Dependencies

Initialize the localized Python virtual environment and ingest required orchestration libraries using the master Makefile:

```bash
cd ~/src/irislime

# Instantiate the local .venv allocation and update pip packages
make setup

```

## Step 3: Activate the Environment Session Gate

Always source the environment configuration script before executing compilation targets or running hardware validation loops. This evaluates the Intel toolchain environment variables, mounts your local python paths, and ensures correct hardware configuration for your OS:

```bash
# For WSL2 Ubuntu Bash environments
source config_env

# For native Windows 11 builds (utilizing VS2022/VS2026, Intel setvars, etc.)
# source config_win11
```

## Step 4: Execute the Hardware Validation Check

Run the automated hardware interrogation script to verify that the SYCL toolchain can safely map your integrated GPU silicon through the stable driver bypass path:

```bash
bash scratch/run_test002.sh

```

## Step 5: Verify the Execution Output
Once the test concludes, check that your environment successfully generated your unique hardware logs:
1. **The Raw Log:** Review the latest timestamped console capture under `scratch/run_test_002_console_*.log` to view the unfiltered GDB debugger trace streams.
2. **The Result Ledger**: Review `scratch/run_test_002.md` to confirm your machine's CPU model name and execution exit codes (`0` for success) have been cleanly appended to the tracking table matrix.
