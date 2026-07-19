# `mtfdash` User & Subsystem Interop Guide (v1.8.6)

**Path:** `docs/MTFDASH_USER_AND_INTEROP_GUIDE.md`  
**Date:** July 18, 2026  
**Target:** Systems Engineering, AGY Core Framework, WSL2 Subsystem Automation  
**Lineage:** `irislime` / `fekerr-dev` Architecture  

---

## 1. Executive Overview & Namespace Architecture

`mtfdash` (v1.8.6) is the cross-platform terminal dashboard and node communication mesh powering the `irislime` / `fekerr-dev` architecture.

### Key Architectural Evolution (v1.8.6):
* **Binary Collision Elimination (`mtfdash`):** Refactored from `dash` to `mtfdash` to eliminate binary path collisions with the Debian Almquist POSIX system shell (`/usr/bin/dash`) inside WSL2 Ubuntu environments.
* **Case-Insensitive Flattening:** Stripped all CamelCase/PascalCase parameter constraints. All commands, flags (`-agy`, `-tail`, `-isolate`), and tokens utilize explicit `.tolower().trim()` evaluations.
* **Deep Narrative Log Buffer (25 Lines):** Displays real-time scrolling narrative log history with version stamps (e.g., `[v1.8.6]`).
* **Self-Healing Token Ring Scrubber:** Auto-scrubs nodes silent for >15 seconds to prevent token deadlocks.

---

## 2. Initiating `mtfdash` & Node Discovery

### 2.1 Starting Nodes on Windows 11 & WSL2

* **Windows 11 Host Node (PowerShell 7+):**
  ```powershell
  # Invoked via profile function or direct script call:
  mtfdash -slot auto -interval 5
  ```
  *Backing Engine:* `ps7/Get-TerminalDashboard.ps1`

* **WSL2 Ubuntu Guest Node (Bash CLI):**
  ```bash
  # Source the project environment:
  source config_env
  ```
  *Sourcing `config_env` automatically registers a live node heartbeat under `logs/nodes/node_wsl_ubuntu_<pid>.json`.*

### 2.2 Discovering Active Nodes

To view all active nodes operating on the same host computer (Win11 Host & WSL Ubuntu Guests):

```bash
mtfdash-nodes
# Alternatively:
python3 tools/mtfdash_node_manager.py discover
```

**Sample Discovery Matrix Output:**
```text
========================================================================
               MTFDASH LOCAL DISK NODE DISCOVERY MATRIX             
========================================================================
 Registry Directory: /home/fekerr/src/irislime/logs/nodes
 Active Nodes: 3 | Stale Nodes: 0
------------------------------------------------------------------------
 * Node ID:    win11_host_core12_4102
   Host/Tree:  [Core12-Laptop] <---> [Win11 Host] (Branch: main@e9da461)
   OS/PID:     Windows 11 (PID 4102)
   Path:       C:\Users\feker\src\irislime
   Last Seen:  2026-07-19T02:14:00Z
   Narrative:  [v1.8.6] Serviced rclone request: copyto 20260718_logs.zip gdrive:transfer/
------------------------------------------------------------------------
 * Node ID:    wsl_ubuntu_sandbox_17
   Host/Tree:  [Core12-Laptop] <---> [ubu26_0715] (Branch: feature/mtfdash-host-tree-tracking@e9da461)
   OS/PID:     WSL2 Ubuntu 26.04 (PID 17)
   Path:       /home/fekerr/src/irislime
   Last Seen:  2026-07-19T02:14:02Z
   Narrative:  [v1.8.6] Delegated rclone copy to Win11 host
------------------------------------------------------------------------
 * Node ID:    llamacpp_sandbox_20
   Host/Tree:  [Core12-Laptop] <---> [ubu26_0715] (Branch: main@e9da461)
   OS/PID:     Intel SYCL / oneAPI (PID 20)
   Path:       /home/fekerr/src/irislime/llama.cpp
   Last Seen:  2026-07-19T02:14:01Z
   Narrative:  [v1.8.6] Inference completed (127.97 tok/s)
------------------------------------------------------------------------
```

### 2.3 Host Computer & WSL Subsystem Tree Tracking
`mtfdash` inspects and embeds host environment context into each node's registry JSON state (`tree_context`):
* **Host Computer:** `host_computer` (e.g., `Core12-Laptop`).
* **Subsystem Distro Tree:** `distro_name` (`WSL_DISTRO_NAME` env var, e.g., `ubu26_0715`, `Ubuntu-26.04`, or `Win11 Host`).
* **Git Working Branch & Commit SHA:** `git_branch` and `git_sha` active on that filesystem tree.
* **Workspace Root Path:** Local POSIX path and translated Windows UNC path (`windows_unc_path`).

---

## 3. Inter-Node Communication Protocol & Mesh Engine

### 3.1 Local Disk Registry & Atomic File Writes
`mtfdash` nodes communicate through shared JSON state files located in [`logs/nodes/`](file:///home/fekerr/src/irislime/logs/nodes).

To ensure lock-free atomic file operations across the Windows and WSL filesystem boundary:
1. Payloads are written to `node_<id>.json.tmp`.
2. The file is replaced atomically using OS-level file replacement (`os.replace` / POSIX `rename`).

### 3.2 Dispatching & Executing Mesh Commands

* **Sending a Command to a Specific Node or All Nodes:**
  ```bash
  # Send command to a specific node:
  mtfdash-send win11_host_core12_4102 "echo Cluster status check"

  # Broadcast command to all active nodes:
  mtfdash-send all "sys-audit"
  ```

* **Processing Inbox Commands on a Node:**
  ```bash
  mtfdash-inbox
  # Alternatively:
  python3 tools/mtfdash_node_manager.py process-inbox
  ```

---

## 4. Subsystem Integration Bridges

### 4.1 AGY Core Bridge (`tools/agy_mtfdash_bridge.py`)
Binds Google Antigravity CLI activity, background tasks (`.system_generated/tasks/`), and subagent telemetry to `mtfdash`:

```bash
# Run AGY mtfdash bridge check or daemon:
agy-mtfdash
agy-mtfdash --daemon --interval 5
```

### 4.2 llama.cpp Inference Bridge (`tools/llamacpp_mtfdash_bridge.py`)
Binds `llama.cpp` inference speed (`tok/s`), model path (`tinyllama-1.1b-chat-v1.0.Q4_0.gguf`), and hardware runtimes (Intel SYCL / OpenVINO / CPU / Vulkan) to `mtfdash`. Intercepts prompt injection payloads dispatched over the mesh:

```bash
# Run llama.cpp prompt or daemon:
llama-mtfdash --prompt "Explain quantum computing"
llama-mtfdash --daemon
```

---

## 5. Cross-Subsystem Rclone Delegation Feature

### 5.1 Architectural Rationale
Google Drive OAuth tokens and `rclone.exe` configurations are managed natively on the Windows host machine (`%LOCALAPPDATA%\Microsoft\WinGet\Links\rclone.exe` or `%APPDATA%\rclone\rclone.conf`).

Rather than requiring duplicated OAuth configurations inside guest WSL Linux containers, **WSL Ubuntu nodes ask the Win11 host node on the same computer to service `rclone` operations for them over `mtfdash`.**

```
+-----------------------------------+       mtfdash mesh      +-------------------------------------+
|      WSL2 Ubuntu Guest Node       |  ====================>  |        Win11 Host Node (mtfdash)    |
| (Delegates: mtfdash-rclone-req)   |  logs/nodes/*.json      | (Executes: Windows rclone.exe)     |
+-----------------------------------+                         +-------------------------------------+
                                                                                 |
                                                                                 v
                                                                     +-----------------------+
                                                                     | Google Drive / Cloud  |
                                                                     +-----------------------+
```

### 5.2 Delegating Rclone Operations from WSL

From any WSL2 Ubuntu terminal:

```bash
# Delegate an rclone copy / upload operation to the Win11 host node:
python3 tools/mtfdash_node_manager.py rclone-delegate "copyto logs/archive.zip gdrive:transfer/archive.zip"
```

### 5.3 Execution Lifecycle
1. **Request Submission:** The WSL node formats an `rclone:<operation>` command payload and injects it into the active `win11_host` node registry file in `logs/nodes/`.
2. **Host Interception:** The Win11 `mtfdash` node (running `get-mtfterminaldashboard.ps1` / `process-inbox`) intercepts the delegated request.
3. **Path Resolution:** The host translates Linux POSIX paths (e.g., `/home/fekerr/...`) into Windows UNC paths via `wslpath -w` ([tools/wsl_rclone_bridge.py](file:///home/fekerr/src/irislime/tools/wsl_rclone_bridge.py)).
4. **Cloud Transfer & Verification:** The Win11 host executes Windows-native `rclone.exe`, uploads the file to the cloud remote, and appends the completion status to the cluster narrative log:
   `[v1.8.6] Serviced rclone request: copyto logs/archive.zip gdrive:transfer/archive.zip`

---

## 6. Summary Command Reference

| Action | Command | Description |
| :--- | :--- | :--- |
| **Discover Mesh Nodes** | `mtfdash-nodes` | Lists active Win11 host and WSL guest nodes in `logs/nodes/`. |
| **Send Mesh Command** | `mtfdash-send <target|all> "<cmd>"` | Injects a command payload into target node's inbox. |
| **Process Node Inbox** | `mtfdash-inbox` | Checks and executes pending commands for current node. |
| **Delegate Rclone** | `python3 tools/mtfdash_node_manager.py rclone-delegate "<args>"` | Asks Win11 host node to run `rclone.exe` operation. |
| **AGY Mesh Bridge** | `agy-mtfdash [--daemon]` | Streams AGY task telemetry and subagent status. |
| **llama.cpp Bridge** | `llama-mtfdash [--daemon]` | Streams inference metrics (SYCL/OpenVINO, tok/s). |
| **WSL Rclone Bridge** | `rclone <args>` | Transparent WSL wrapper executing host `rclone.exe`. |
