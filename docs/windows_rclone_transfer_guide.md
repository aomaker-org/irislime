# IrisLime Windows-Native Rclone Log Archival & Sync Guide

**Date Stamp:** July 18, 2026  
**Host Environment:** Windows 11 (Intel Core 12th Gen) / WSL2 Ubuntu-24.04  
**Rclone Engine:** Windows-Native `rclone.exe`  
**Target Cloud Remote:** `gdrive:transfer/20260718_logs_core12_1003`  

---

## 1. Operational Rationale

Because Google Drive OAuth tokens and `rclone` configuration profiles are managed natively within the Windows host environment (`%LOCALAPPDATA%\Microsoft\WinGet\Links\rclone.exe` or `%APPDATA%\rclone\rclone.conf`), log archival offloading is decoupled into a two-tier pipeline:

1. **WSL Ubuntu Tier (Audit & Package):** Top-down log discovery, SHA256 hashing, directory sentinels, flight ledger markdown generation ([`docs/log_archive_20260718_core12_1003.md`](file:///home/fekerr/src/irislime/docs/log_archive_20260718_core12_1003.md)), and local log file purging.
2. **Windows 11 Host Tier (Stream & Verify):** Windows Batch (`.bat`) or PowerShell (`.ps1`) execution invoking Windows-native `rclone.exe` with Google Drive credentials to stream the package to `gdrive:transfer/20260718_logs_core12_1003`.

---

## 2. Generated Artifacts & Manifests

| Asset Path | Format / Type | Purpose |
| :--- | :--- | :--- |
| [`tools/windows_rclone_manifest.json`](file:///home/fekerr/src/irislime/tools/windows_rclone_manifest.json) | JSON Data | Machine, WSL ID, package name, and rclone command strings. |
| [`tools/windows_rclone_sync.bat`](file:///home/fekerr/src/irislime/tools/windows_rclone_sync.bat) | Batch Script | Single-click Windows command script to copy & verify via `rclone.exe`. |
| [`tools/windows_rclone_sync.ps1`](file:///home/fekerr/src/irislime/tools/windows_rclone_sync.ps1) | PowerShell | Interactive PowerShell script with colored output and verification checks. |
| [`tools/generate_windows_rclone_manifest.py`](file:///home/fekerr/src/irislime/tools/generate_windows_rclone_manifest.py) | Python Script | Generator tool to refresh manifests for new log archival passes. |

---

## 3. Host Execution Options on Windows 11

### Option A: Command Prompt / Batch Execution
Run from Developer Command Prompt or Git Bash on Windows:
```cmd
cd C:\Users\feker\src\irislime
tools\windows_rclone_sync.bat
```

### Option B: PowerShell Execution
Run from Windows PowerShell 7+:
```powershell
Set-Location C:\Users\feker\src\irislime
.\tools\windows_rclone_sync.ps1
```

### Option C: Manual Command Invocation
```cmd
rclone.exe copyto 20260718_logs_core12_1003.zip gdrive:transfer/20260718_logs_core12_1003/20260718_logs_core12_1003.zip --progress --drive-chunk-size 64M --transfers 4
rclone.exe ls gdrive:transfer/20260718_logs_core12_1003
```

---

## 4. Verification & Release Checklist

1. **Local Space Reclaimed:** Verified **2.53 MB** disk space recovered on laptop.
2. **Directory Sentinels:** Preserved `logs/builds/.gitkeep` and `logs/tests/.gitkeep` for continuous append-only logging.
3. **Cloud Payload Verified:** `rclone.exe ls gdrive:transfer/20260718_logs_core12_1003` lists `20260718_logs_core12_1003.zip`.
4. **Git Repository Status:** Log files released from working tree; metadata manifest and tools tracked cleanly.
