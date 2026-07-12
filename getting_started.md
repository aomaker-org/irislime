# Getting Started with IrisLime

This manual outlines the step-by-step procedures required to initialize your interactive shell environment, configure dependency path boundaries, and verify local multi-backend tracking states.

---

## Step 1: Initialize the Terminal Environment Vector

The system variables, path configurations, and semantic shortcuts are driven by the project's central shell coordinator script. Every time you spawn a new terminal window or container session, execute the authoritative environment load command from the workspace root:

```bash
. config_env
```

### The Hot-Reload Gateway
The script is explicitly engineered with a decoupled runtime guard. Sourcing `config_env` on a session where the variables are already active will automatically bypass heavy path exports while cleanly re-running the inner alias allocation arrays. This allows you to apply instant string adjustments or typo fixes to your aliases without tearing down your active variables.

---

## Step 2: Provisioning Workspace Submodules

The system tracks downstream dependency frameworks through explicitly pinned git submodules. To synchronize your local workspace with the organization's current baseline targets, execute the sequence:

### 1. Synchronize Acceleration Framework Repositories
Pull down the performance-patched version of the inference engines:
```bash
git submodule update --init --recursive
```

### 2. Ingest Academic Learning Laboratories
Execute the automated organizational provisioning script to fork and integrate our target learning environments straight into your local `deps/learning/` layout:
```bash
./tools/setup_learning_submodules.sh
```

This tool automatically leverages your authenticated GitHub CLI tool (`gh`) to clone your organization's forks of Harvard's TinyTorch (`cs249r_book`), Cornell's MiniTorch, and Karpathy's algorithmic compression engines.

---

## Step 3: Running Workspace Pre-Flight Diagnostics

Before executing heavy hardware compilation chains or token processing tasks, verify that your local filesystem footprints, modified git matrices, and active submodule hashes are clean.

Run the customized snapshot utility from your terminal prompt:
```bash
tools/view_repo_info.sh
```

This tool acts as a scrolling index trace, displaying your current git status tracking rows, listing active submodules, confirming remote repository parameters, and mapping your directory configurations while safely ignoring heavy compiled objects, system models, and build logs.

---
## Running Local SLM Health Checks (puppy_chow)

To verify that your compiled graphics hardware acceleration libraries are interacting flawlessly with model weights arrays, you can fire a localized inference loop using the project's lightweight `puppy_chow` validation series.

### 1. Fetch the Quantized Testing Weights Baseline
Run the standard library provisioner script to download a 398 MB 0.5B Qwen asset straight into your adjacent models directory:
```bash
uv run tools/model_manager.py
```

### 2. Invoke Stable, Greedy Inference Verification
Execute the hardened shell wrapper to prompt the model using strict ChatML boundary containers and a zero-temperature parameter constraint to force deterministic responses:
```bash
tools/puppy_chow_004.sh
```

This routes the token generation pass directly across your local Vulkan or SYCL processing pipelines, confirming your hardware interfaces are functioning perfectly.

---


