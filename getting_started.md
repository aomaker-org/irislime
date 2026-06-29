
# Getting Started: System Configuration & Architectural Principles

This document provides a deep dive into the underlying system dependencies, host-to-guest virtualization mechanics, and validation principles governing the IrisLime research sandbox.

## 1. Host Infrastructure Prerequisites

Prior to initializing the workspace orchestration scripts, the target host machine environment must satisfy the following hardware and toolchain baselines:

* **Operating System**: Windows 11 (Version 22H2 or higher, or Insider Preview tracks) with an active WSL2 (Windows Subsystem for Linux) Ubuntu 24.04 LTS instance.
* **Toolchain Stack**: Intel oneAPI Base Toolkit installed natively inside the WSL2 guest container (Version 2026 recommended).
* **Graphics Infrastructure**: Current Intel Graphics Compute Runtime installation on the Windows host to expose execution device slices to the virtualization container.

## 2. Kernel Graphics Virtualization Bridge

To allow the virtualized Linux guest shell to communicate directly with your physical Intel Iris Xe integrated graphics cores, you must instantiate the kernel graphics interface mapping node.

Execute the following commands within your WSL2 terminal session:

```bash
# 1. Expose the virtual graphics driver module to the guest kernel
sudo modprobe vgem

# 2. Verify hardware device node accessibility
ls -l /dev/dri/renderD128

```

## 3. The Isolated Environment Gating Model

To achieve absolute repeatability and protect the host workspace against configuration drift, this repository strictly avoids writing permanent modifications to your global user profile configurations (such as `~/.bashrc`). Instead, toolchain bindings are loaded dynamically inside your active shell session terminal.

Sourcing the environment gate evaluates two operational layers:

```bash
source config_env

```

1. **Intel oneAPI Compilation Variables**: Automatically evaluates `/opt/intel/oneapi/setvars.sh` to arm the native `icx` and `icpx` compilers within the active session.
2. **Python Process Isolation**: Kills any active external virtual environments and binds your shell strictly to the local project `.venv` space.

The system validates environment readiness via an explicit environmental marker (`IRISLIME_READY=1`). If this sentinel is missing from your active process context, the compilation Makefiles will halt execution immediately to block unoptimized compilation passes.

## 4. Crash Containment & Forensic Logging

When debugging low-level hardware memory allocations or driver translation layers across different hardware lines, running unbuffered binaries directly can drop dead with unhandled exceptions, leaving zero telemetry behind.

This workspace mandates that all memory-unsafe execution binaries pass through non-interactive, automated GDB wrappers (`scratch/run_gdb.sh`):

* **Crash Containment**: If a segmentation fault surfaces, the parent shell loop catches the true POSIX signal code (`139`), auto-extracts the full backtrace (`bt`), and terminates gracefully without hanging your terminal panel.
* **Privacy Protections**: Before logging tools rewrite active clipboard buffers, incoming clipboard states are securely archived as read-only snapshots inside the untracked `.security_scrub/` workspace folder to insulate local developer states against data overwrites.
