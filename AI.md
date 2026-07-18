# Workspace Specification & Operational Guardrails (`AI.md`)

**Last Synced State:** July 4, 2026  
**Host Architecture:** Windows 11 (Intel Core 12th Gen)  
**Primary Repository Workspace:** `irislime`  

---

## 1. System Topology & Validated Environments

Any LLM/SLM context processing this workspace must adhere strictly to the
physical file system paths and toolchains validated below. Do not assume
abstract defaults.

### 1.1 The Host Compiler Layer
* **Compiler Backend:** Microsoft Visual C++ (MSVC) Native 64-bit Optimizing
  Compiler.
* **Validated Binary Node:**
  `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe`
* **Target Build Framework:** MSVC v144 / Windows 11 Unified SDK.

### 1.2 Terminal Shell Interfaces
* **Native Host Prompt:** Developer Git Bash (VS 2022) configured via dynamic
  variable inheritance.
  * *Launch Directive:* Loads `VsDevCmd.bat -arch=amd64` to securely stage
    compiler variables (`INCLUDE`, `LIB`, `PATH`) into volatile memory before
    dropping execution cleanly into the native MinGW64 Bash interpreter
    (`bash-5.3$`).
* **Linux Subsystem Workspace:** Isolated single instance of `Ubuntu-24.04` LTS
  via WSL2.
* **Persistent Shell Silencers:** All visual and audible input boundary errors
  have been muted via terminal `bellStyle: none` options and GNU Readline
  `set bell-style none` configurations inside `~/.inputrc`.

### 1.3 Local Storage Runtime Matrix
* **Active SSD Storage Runway:** 78.84 GB free space allocated for active build
  fragments, C++ linking spaces, and local SLM token parameters.
* **Active Cloud Endpoints (`rclone`):**
  * `gaom:` ƒ?" 4 TiB Primary Allocation Array
  * `gdrive:` ƒ?" 5 TiB Architecture Drive
* *Storage Policy:* All large legacy hypervisor fragments and historical
  development tarballs have been permanently moved out of local storage sectors
  and archived securely in cold cloud nodes.

---

## 2. Core Operational Guardrails

* **The Immutable Logging Paradigm:** Practice a strict "never delete, always
  append" forensic logging philosophy for file records and transaction
  tracking.
* **Cross-Platform Path Alignment:** Never utilize virtualized drive-letter
  mappings (`G:`, `H:`). All data references between host Windows and guest
  Linux boundaries must evaluate via native cross-platform loopbacks
  (`\\wsl.localhost\Ubuntu-24.04\`) or localized home nodes (`--cd ~`).
* **Environment Isolation Guardrails:** All Python execution steps must route
  exclusively through the native `uv` toolchain manager. Avoid contaminating
  global system environments by running self-contained, ephemeral sandboxes
  (`uv run`).

---
