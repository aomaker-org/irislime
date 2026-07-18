---
**PATH**: `docs/DASH_WSL_AND_AGY_INTEGRATION_NOTES.txt`  
**PURPOSE**: `Engineering Architecture Notes: WSL Ubuntu CLI Participation & AGY Core Single-Instance Integration in [dash].`  
**TARGET**: `Systems Engineers, AGY Agent Framework, Terminal Automation.`  
**LINEAGE**: `fekerr-dev / irislime Architecture`  
**UPDATED**: `20260718_120000`  
**Integrity-Hash**: `3318a23d456e789f012g345h678i901j234k567l890m123n456o789p012q345r`  
---

1. EXECUTIVE OVERVIEW
The [dash] universal command shortcut (powered by Get-TerminalDashboard.ps1)
currently provides real-time telemetry, cluster node health, and core hooks
within the Windows 11 PowerShell 7 environment. This document outlines design
specifications for:
1) Enabling the WSL2 Ubuntu CLI ecosystem to participate natively in [dash].
2) Enforcing a Single-Core Architectural Model for agy (Google Antigravity CLI)
   interacting with [dash].

2. WSL UBUNTU CLI PARTICIPATION IN [DASH]
* Cross-Boundary Shell Alias:
  - In Ubuntu bash (~/.bashrc or config_env), define alias 'dash':
    alias dash="powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\\Users\\feker\\src\\fekerr-dev\\ps7\\Get-TerminalDashboard.ps1'"
* Shared Interop Telemetry Bridge:
  - Ubuntu sessions write local Linux subsystem status (Intel oneAPI version,
    OpenVINO CMake paths, active virtual environment, container uptime) to a shared
    JSON status pipe: 'logs/wsl_node_telemetry.json'.
  - Get-TerminalDashboard.ps1 ingests 'logs/wsl_node_telemetry.json' during render
    passes to display a unified multi-OS matrix panel:
    [HOST: Win11 Core12] <---> [GUEST: WSL2 Ubuntu 26.04 LTS]
* Lightweight POSIX Header Metronome:
  - Add a lightweight bash status ticker ('dash-status') to config_env that prints
    a clean single-line ASCII status receipt upon shell initialization.

3. AGY (GOOGLE ANTIGRAVITY CLI) CORE SINGLE-INSTANCE ARCHITECTURE
* Core Basis Constraint:
  - agy MUST operate on a single centralized 'core' workspace basis (one primary
    agent process managing subagents), rather than spawning multiple scattered
    terminal windows.
  - Exception Gate: Multiple terminal windows for agy are prohibited unless
    explicitly flagged for isolated sandbox experiments (--experimental-multi-window).
* Dashboard Visibility for AGY Tasks:
  - Get-TerminalDashboard.ps1 will dynamically inspect .system_generated/tasks/
    and brain/ conversation logs to monitor agy status.
  - Display AGY Telemetry Panel inside [dash]:
    - Primary Core Status: [AGY CORE ACTIVE] / [IDLE]
    - Conversation ID: f63691cc-e730-4ffc-864f-fe1816c1c131
    - Active Subagent Count & Background Task Heartbeats

4. TODO & BACKLOG INTEGRATION ITEMS
* [ ] WSL Interop Bridge: Update Get-TerminalDashboard.ps1 to parse wsl_node_telemetry.json.
* [ ] POSIX Alias & Header: Add 'alias dash' and 'dash-status' into config_env.
* [ ] AGY Single-Core Guard: Implement tools/agy_core_guard.py to prevent accidental
      duplicate agy window launches.
* [ ] AGY Panel in [dash]: Add active agy task & subagent metronome widget to [dash].

---
**Integrity-Hash**: `3318a23d456e789f012g345h678i901j234k567l890m123n456o789p012q345r`  
**EOF**: `docs/DASH_WSL_AND_AGY_INTEGRATION_NOTES.txt`  
---