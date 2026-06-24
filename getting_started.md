# Getting Started with IrisLime

**IrisLime** is a research-focused environment designed to facilitate local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics, leveraging WSL2 and the Intel oneAPI toolkit.

## 1. Prerequisites

* **Windows 11** with WSL2 enabled.
* [Intel oneAPI Base Toolkit](https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit.html) installed (v2026 recommended).
* Ensure Windows host GPU drivers are current.

## 2. System Configuration (Manual)

To bridge your Windows GPU to the WSL2 environment:

1. **Enable the vgem bridge:** Run `sudo modprobe vgem` to enable the virtual graphics module.
2. **Verification:** Check for the render node: `ls -l /dev/dri/renderD128`.
*(If not present, ensure you have initialized your WSL2 instance after driver updates).*

## 3. Workspace Setup (The Dependency Injection Model)

We follow an architecture that isolates the application code, engine fork, and model weights to maintain a lean, forensic-ready repository.

### Step-by-Step Initialization

1. **Clone the project:**
```bash
cd ~/src
git clone https://github.com/aomaker-org/irislime.git
cd irislime

```


2. **Clone and link the inference engine:**
Clone your fork of `llama.cpp` as a sibling directory, then link it to the project:
```bash
cd ~/src
git clone https://github.com/aomaker-org/llama.cpp.git
cd ~/src/irislime
# Link the engine fork
ln -s ../llama.cpp llama.cpp

```


3. **Configure Model Storage:**
Store large binary model files in a central location to prevent Git repository bloat:
```bash
mkdir -p ~/src/ai_models
# Link the central storage to your current project
ln -s ~/src/ai_models models

```


4. **Acquire a Model:**
Download a baseline model (e.g., Llama-3-8B-Instruct) into your central store:
```bash
wget https://huggingface.co/lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf -O ~/src/ai_models/llama-3-8b.Q4_K_M.gguf

```



## 4. Initialization

Always initialize the local environment variables before building or running:

```bash
source config_env

```

## 5. Architectural Rationale

* **Repository Isolation:** By using symlinks for `llama.cpp` and `models`, we prevent Git index pollution and ensure binary files remain outside the version control system.
* **Modular Evolution:** The `llama.cpp` engine can be branched or updated independently of the application logic.
* **Portability:** You can rebuild the `irislime` environment on any machine, point the symlinks to your existing `ai_models` folder, and resume research immediately.
