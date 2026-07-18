# Fekerr-Dev PowerShell 7 Host Toolkit

This directory serves as the centralized, high-performance execution toolkit for local Windows 11 development environments, specifically tuned for bare-metal firmwares, hardware accelerators, and cross-boundary container orchestration.

## Active Host Utilities

### 1. `Protect-FileIntegrity.ps1`
* **Purpose:** Cryptographically signs and verifies host execution assets using a closed SHA-256 loop.
* **Shorthands:** `sign <path>`, `verify <path>`

### 2. `Get-UncoveredFiles.ps1` (Optimized)
* **Purpose:** Isolates and packages untracked or ignored telemetry files from active repositories.
* **Shorthand:** `backup-uncovered`
* **Safety Filters:** Automatically prunes massive directories (`.venv/`, `build/`, `node_modules/`, `.ccache/`, `target/`) to prevent host-path leakage and storage bloat.

### 3. `Sync-CloudLogs.ps1` (Patched)
* **Purpose:** Multi-cloud log sweeper utilizing `rclone` to replicate logs to Google Drive and OneDrive.
* **Shorthand:** `sweep-logs`
* **Engine Workaround:** Patched directly around **PowerShell Core Bug #16695** by bypassing `-Exclude` flag failures with an explicit pipelined `Where-Object` match.

### 4. `pipe2clip.ps1` (Threshold-Gated)
* **Purpose:** Intelligent host clipboard buffer pipeline forwarding.
* **Shorthand:** `... | p2c`
* **Overflow Gate:** Enforces a **20 KB limit**. Small outputs go directly to the clipboard; outputs exceeding 20 KB are written to `logs/overflow_trace_[timestamp].log` while a clean metadata summary receipt is copied to the clipboard.

## Active Profile Shortcuts mapping
```powershell
function sign { & "C:\Users\feker\src\fekerr-dev\ps7\Protect-FileIntegrity.ps1" -Action Sign -Path $args[0] }
function verify { & "C:\Users\feker\src\fekerr-dev\ps7\Protect-FileIntegrity.ps1" -Action Verify -Path $args[0] }
function log-session { & "C:\Users\feker\src\fekerr-dev\ps7\Record-Session.ps1" -Module $args[0] -Action $args[1] }
function p2c {$input | Out-String | & "C:\Users\feker\src\fekerr-dev\ps7\pipe2clip.ps1" }
function sync-tars { & "C:\Users\feker\src\fekerr-dev\ps7\Backup-AndVerifyTars.ps1" @args }
function sweep-logs { & "C:\Users\feker\src\fekerr-dev\ps7\Sync-CloudLogs.ps1" -LogsDir "C:\Users\feker\src\fekerr-dev\logs" @args }
function backup-uncovered { & "C:\Users\feker\src\fekerr-dev\ps7\Get-UncoveredFiles.ps1" @args }
```
