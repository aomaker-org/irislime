--- BEGIN FILE: README.md | Size: 3550 bytes | SHA256: TODO ---

irislime
An experimental hardware-software co-design sandbox optimized for edge AI inference, low-level tensor acceleration, and repository-aware agent automation. This repository serves as a live, high-velocity engineering playground for optimizing small language models (SLMs) on heterogeneous consumer hardware.

🎯 Project Intent
This workspace moves away from fragile interactive console loops in favor of headless automation, low-level kernel testing, and isolated verification blocks:

Hardware Abstraction Loops: Bypassing driver and toolkit collisions to run stable execution matrices across native Windows 11 and Linux/WSL2 environments.

Agent Integration: Testing autonomous repository-aware scripts and hooks—leveraging engines like Jules—to orchestrate continuous integration and codebase audits.

Headless Automation: Utilizing programmatic verification matrices (test_runner.py) to evaluate low-level mathematical kernel stability (test-backend-ops) and track high-precision telemetry.

🏗️ Core Workspace Architecture
The runtime architecture strictly decouples tracking infrastructure from high-density binary model weights and upstream inference engine forks:

.venv/ : Hermetically sealed local runtime managed exclusively through the uv toolchain layer.

deps/litert-lm : In-tree dependencies managed as explicit Git submodules over SSH.

llama.cpp/ : Explicit in-tree Git submodule tracking target fork implementations (git@github.com:aomaker-org/llama.cpp.git).

matrix_control.json : The central configuration blueprint defining build targets, parallelization thread limits, compiler flags, and target backend overrides.

logs/ : Persistent runtime folder utilizing a strict "never delete, always append" forensic logging philosophy for all execution tracking.

🚀 Fast-Track Workstation Onboarding
If you are setting up an instance of this workspace on a newly provisioned machine, skip the architectural deep dives and jump straight to the fast-track deployment track:

👉 Quick Start Deployment Recipe

Unified Platform Execution Gateways
To prevent environment contamination and cross-platform path errors, execution pathways must strictly adhere to the following host environments:

1. Windows 11 Native Workspace (MSVC Toolchain)
Native compilation requires spawning the Git Bash terminal inside the inherited Microsoft Visual C++ volatile memory segment. Launch the interface via a standard prompt:

DOS
cmd.exe /k ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64 && "C:\Program Files\Git\bin\bash.exe" --login"
Once inside the shell, activate your variables and run your builds isolated through uv:

Bash
source config_win11
uv run python setup.py build_ext --inplace
2. Linux Native / WSL2 Workspace (Intel 2026 Stack)
For remote instances or virtualized layers, execute operations directly within your local home profile paths without using virtualized drive letters:

Bash
source config_env
uv run python tests/test_runner.py
Verily, thou shalt hoard data.
--- END FILE: README.md ---

--- BEGIN FILE: getting_started.md | Size: 3820 bytes | SHA256: TODO ---

Getting Started with IrisLime
IrisLime is a research-focused environment designed to facilitate local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics, leveraging the unified Intel 2026 Toolchain across native Windows 11 and Linux subsystem targets.

1. Workstation Provisioning Core
Before attempting to initialize the repository workspace, the host operating system must be provisioned with its verified baseline compiler runtimes.

1.1 Windows 11 Host Baseline (PowerShell Administration)
Bootstrap the base package dependencies and toolchain manager natively via winget:

PowerShell
winget install --id Git.Git --silent
winget install --id Microsoft.VisualStudio.2022.Community --silent
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
Note: Ensure the "Desktop development with C++" workload and the v144 toolset are checked inside the Visual Studio Installer.

1.2 Linux Target / Pavlov Node Baseline (Ubuntu 24.04 LTS)
Register the official Intel 2026 cryptographic channels and install the required development libraries:

Bash
# Register Intel Software Product Keys
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB -O- | sudo gpg --dearmor -o /usr/share/keyrings/intel-sw-products.gpg

# Bind official Intel 2026 Repository Channels
echo "deb [signed-by=/usr/share/keyrings/intel-sw-products.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/intel-oneapi.list
echo "deb [signed-by=/usr/share/keyrings/intel-sw-products.gpg] https://apt.repos.intel.com/openvino/2026 ubuntu24 main" | sudo tee /etc/apt/sources.list.d/intel-openvino.list

# Install Core Libraries Natively
sudo apt-get update && sudo apt-get install -y build-essential cmake git clinfo intel-oneapi-compiler-dpcpp-cpp-2026.0 intel-oneapi-mkl-2026.0 libopenvino-dev openvino-intel-gpu-plugin
2. Workspace Setup & Cryptographic Gates
This repository and all internal tracking engines rely strictly on SSH authentication. Verify your outbound cryptographic tunnel is active before proceeding:

Bash
ssh -T git@github.com
2.1 The Submodule Omission Trap
The default "Copy URL" snippet provided on GitHub's web interface only targets the parent tree, leaving critical compilation and inference engines completely empty. To deploy or recover your source tree correctly, use one of the two explicit pathways below:

Track A: The One-Shot Recursive Clone (Preferred)
To download the parent repository and recursively initialize all internal dependency submodules in a single secure transaction, use the recurse flag over SSH:

Bash
cd ~/src
git clone --recurse-submodules git@github.com:aomaker-org/irislime.git
cd irislime
Track B: The Post-Clone Recovery Loop
If the repository was initialized using the basic GitHub web syntax without submodule recursion, your llama.cpp and deps/litert-lm directories will sit empty on disk. To initialize, fetch, and bind the missing links over SSH, execute this recovery sequence from the repository root:

Bash
cd ~/src/irislime
git submodule update --init --recursive
2.2 Pro Tip: Enforcing Global Submodule Recursion
To force your local Git client to automatically handle submodule initialization across any future clone or checkout operation without needing explicit flags, inject this global configuration:

Bash
git config --global submodule.recurse true
3. Environment Isolation Guardrails
To preserve a clean local footprint and prevent global environment contamination, this workspace strictly prohibits global Python pip installations. All actions route through the modern uv toolchain layer:

Bash
# Automatically initialize the local .venv sandbox and synchronize pinned locks
uv sync

# Always wrap execution tasks through the ephemeral runtime manager
uv run python setup.py build_ext --inplace
--- END FILE: getting_started.md ---

--- BEGIN FILE: quick_start.md | Size: 2450 bytes | SHA256: TODO ---

IrisLime Quick Start Deployment Recipe
This guide is the accelerated, friction-free installation sequence for bringing up the IrisLime development workspace on a newly provisioned machine. Follow these exact steps to link your trees, arm the environment gates, and execute your first hardware validation test.

Step 1: Clone the Repository Recursively
Ensure your local SSH keys are configured and pull down the complete, unified file graph in a single transaction:

Bash
cd ~/src
git clone --recurse-submodules git@github.com:aomaker-org/irislime.git
cd irislime
Correction Note: If you already ran a plain clone and your internal submodules are missing, run this recovery string immediately from the root folder:

Bash
git submodule update --init --recursive
Step 2: Initialize the Local Workspaces
Provision your hermetically sealed local Python runtime environment and automatically synchronize dependencies against the project lockfile using uv:

Bash
uv sync
Step 3: Boot the Shell Session Gates
For Windows 11 Native Prompts (MSVC v144 Stack)
Initialize the Developer Command Prompt variables inside Git Bash:

DOS
cmd.exe /k ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64 && "C:\Program Files\Git\bin\bash.exe" --login"
Source the Windows-specific allocation environment script:

Bash
source config_win11
For Linux Subsystems / Pavlov Nodes (Intel 2026 Stack)
Source the main environment gate loader to mount the Intel variables and activate the python sandbox:

Bash
source config_env
Step 4: Audit Your Hardware Core Topology
Run the dynamic resource prober to verify your total system memory bounds, compute job capacity limits, and physical Performance-core thread mappings:

Bash
make show-topology
Step 5: Launch the Mathematical Validation Sweep
Fire the data-driven test matrix harness to evaluate low-level computational kernel stability across your active hardware blocks:

Bash
make test
Step 6: Verify the Forensic Telemetry Output
Once the suite concludes, check that your environment generated your unique diagnostic logs:

The Sandboxed Log: Review your backend-specific directory (e.g., build/openvino_relwithdebinfo/logs/) to inspect the unfiltered compilation streams.

The Results Ledger: Review telemetry_builds.csv to ensure your machine's execution duration numbers have been cleanly appended to the tracking table.
--- END FILE: quick_start.md ---
