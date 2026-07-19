---
**PATH**: `docs/DASH_WSL_AND_AGY_INTEGRATION_NOTES.txt`  
**PURPOSE**: `Engineering Architecture Notes: WSL Ubuntu CLI Participation & AGY Core Single-Instance Integration in [dash] / mtfdash.`  
**TARGET**: `Systems Engineers, AGY Agent Framework, Terminal Automation.`  
**LINEAGE**: `fekerr-dev / irislime Architecture`  
**UPDATED**: `20260718_154600`  
**Integrity-Hash**: `3318a23d456e789f012g345h678i901j234k567l890m123n456o789p012q345s`  
---

1. EXECUTIVE OVERVIEW
The [dash] universal command shortcut (powered by Get-TerminalDashboard.ps1)
currently provides real-time telemetry, cluster node health, and core hooks
within the Windows 11 PowerShell 7 environment. This document outlines design
specifications for:
1) Enabling the WSL2 Ubuntu CLI ecosystem to participate natively in mtfdash.
2) Resolving system binary collisions with Linux /usr/bin/dash (DASH POSIX shell).
3) Enforcing a Single-Core Architectural Model for agy (Google Antigravity CLI)
   interacting with mtfdash.

2. LINUX / SYSTEM BINARY CONFLICT RESOLUTION (MTFDASH)
* Collision Warning:
  - On Ubuntu/Debian Linux systems, '/usr/bin/dash' is the Debian Almquist Shell
    (the default /bin/sh POSIX system shell interpreter).
  - Attempting to name a Linux alias or script 'dash' collides directly with /usr/bin/dash.
* Standardized Linux Alias:
  - The Linux/WSL environment standardizes on the alias 'mtfdash' (MTF Profile Dashboard v1.8.6):
    mtfdash() { pwsh.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\feker\src\fekerr-dev\ps7\Get-TerminalDashboard.ps1' "$@"; }

3. WSL UBUNTU CLI PARTICIPATION IN [DASH] / MTFDASH
* Shared Interop Telemetry Bridge:
  - Ubuntu sessions write local Linux subsystem status (Intel oneAPI version,
    OpenVINO CMake paths, active virtual environment, container uptime) to a shared
    JSON status pipe: 'logs/wsl_node_telemetry.json'.
  - get-mtfterminaldashboard.ps1 ingests 'logs/wsl_node_telemetry.json' during render
    passes to display a unified multi-OS matrix panel:
    [HOST: Win11 Core12] <---> [GUEST: WSL2 Ubuntu 26.04 LTS]
* Lightweight POSIX Header Metronome:
  - Add a lightweight bash status ticker ('mtfdash-status') to config_env that prints
    a clean single-line ASCII status receipt upon shell initialization.

4. AGY (GOOGLE ANTIGRAVITY CLI) CORE SINGLE-INSTANCE ARCHITECTURE
* Core Basis Constraint:
  - agy MUST operate on a single centralized 'core' workspace basis (one primary
    agent process managing subagents), rather than spawning multiple scattered
    terminal windows.
  - Exception Gate: Multiple terminal windows for agy are prohibited unless
    explicitly flagged for isolated sandbox experiments (--experimental-multi-window).
* Dashboard Visibility for AGY Tasks:
  - get-mtfterminaldashboard.ps1 will dynamically inspect .system_generated/tasks/
    and brain/ conversation logs to monitor agy status.
  - Display AGY Telemetry Panel inside mtfdash:
    - Primary Core Status: [AGY CORE ACTIVE] / [IDLE]
    - Conversation ID: f63691cc-e730-4ffc-864f-fe1816c1c131
    - Active Subagent Count & Background Task Heartbeats

5. TODO & BACKLOG INTEGRATION ITEMS
* [ ] WSL Interop Bridge: Update get-mtfterminaldashboard.ps1 to parse wsl_node_telemetry.json.
* [x] POSIX Alias & Header: Add 'mtfdash' bash function and 'mtfdash-status' into config_env to prevent /usr/bin/dash collision.
* [ ] AGY Single-Core Guard: Implement tools/agy_core_guard.py to prevent accidental
      duplicate agy window launches.
* [ ] AGY Panel in mtfdash: Add active agy task & subagent metronome widget to mtfdash.

---
**Integrity-Hash**: `3318a23d456e789f012g345h678i901j234k567l890m123n456o789p012q345s`  
**EOF**: `docs/DASH_WSL_AND_AGY_INTEGRATION_NOTES.txt`  
---