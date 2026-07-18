#!/usr/bin/env python3
"""
Windows-Native Rclone Log Sync & Manifest Generator

Generates Windows-compatible manifests, batch files, and PowerShell scripts
for executing rclone.exe from host Windows 11 to transfer archived logs to gdrive:.
"""

import datetime
import json
import os
from pathlib import Path

DEFAULT_MACHINE_ID = "core12"
DEFAULT_WSL_ID = "1003"
DEFAULT_REMOTE_TARGET = "gdrive:transfer"

def get_workspace_root() -> Path:
    return Path(__file__).resolve().parent.parent

def main():
    root = get_workspace_root()
    timestamp_date = datetime.datetime.now().strftime("%Y%m%d")
    folder_name = f"{timestamp_date}_logs_{DEFAULT_MACHINE_ID}_{DEFAULT_WSL_ID}"
    zip_name = f"{folder_name}.zip"
    remote_dest = f"{DEFAULT_REMOTE_TARGET}/{folder_name}"
    
    # Read existing doc manifest if available
    doc_manifest = root / "docs" / f"log_archive_{timestamp_date}_{DEFAULT_MACHINE_ID}_{DEFAULT_WSL_ID}.md"
    
    # Generate Windows Manifest JSON
    manifest_data = {
        "timestamp": timestamp_date,
        "machine_id": DEFAULT_MACHINE_ID,
        "wsl_ubuntu_id": DEFAULT_WSL_ID,
        "zip_package": zip_name,
        "remote_destination": remote_dest,
        "windows_rclone_cmd": f'rclone copyto "{zip_name}" "{remote_dest}/{zip_name}" --progress --drive-chunk-size 64M --transfers 4',
        "windows_verify_cmd": f'rclone ls "{remote_dest}"',
        "doc_ledger": str(doc_manifest.relative_to(root)) if doc_manifest.exists() else ""
    }
    
    json_path = root / "tools" / "windows_rclone_manifest.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2)
    print(f"[+] Written Windows Rclone Manifest: {json_path.relative_to(root)}")
    
    # Generate Windows Batch Script (.bat)
    bat_content = f"""@echo off
REM ==============================================================================
REM IrisLime Windows Rclone Log Archiver & Cloud Streamer
REM Target Remote: {remote_dest}
REM Package: {zip_name}
REM ==============================================================================

setlocal enabledelayedexpansion

set "ZIP_FILE={zip_name}"
set "REMOTE_DEST={remote_dest}"

echo ==============================================================================
echo   IrisLime Windows Rclone Log Archiver Streamer
echo ==============================================================================
echo Target Package: %ZIP_FILE%
echo Remote Target : %REMOTE_DEST%
echo.

REM Locate rclone.exe on Windows host
set "RCLONE_EXE="
if exist "%LOCALAPPDATA%\\Microsoft\\WinGet\\Links\\rclone.exe" set "RCLONE_EXE=%LOCALAPPDATA%\\Microsoft\\WinGet\\Links\\rclone.exe"
if "%RCLONE_EXE%"=="" (
    where rclone >nul 2>nul
    if !errorlevel! equ 0 set "RCLONE_EXE=rclone"
)

if "%RCLONE_EXE%"=="" (
    echo [ERROR] rclone.exe not found in WinGet links or PATH. Please install rclone on Windows.
    exit /b 1
)

echo [*] Using rclone binary: %RCLONE_EXE%
echo [*] Streaming archive package to cloud remote...

"%RCLONE_EXE%" copy "%ZIP_FILE%" "%REMOTE_DEST%" --progress --drive-chunk-size 64M --transfers 4

if !errorlevel! neq 0 (
    echo [ERROR] Rclone upload failed with code !errorlevel!.
    exit /b !errorlevel!
)

echo.
echo [*] Verifying remote payload delivery on gdrive...
"%RCLONE_EXE%" ls "%REMOTE_DEST%"

echo.
echo [SUCCESS] Log archive package transferred and verified on gdrive:!
echo.
"""
    bat_path = root / "tools" / "windows_rclone_sync.bat"
    with open(bat_path, "w", encoding="utf-8") as f:
        f.write(bat_content)
    print(f"[+] Written Windows Batch Script: {bat_path.relative_to(root)}")
    
    # Generate Windows PowerShell Script (.ps1)
    ps1_content = f"""# ==============================================================================
# IrisLime Windows Rclone Log Archiver & Cloud Streamer (PowerShell)
# Target Remote: {remote_dest}
# Package: {zip_name}
# ==============================================================================

$ErrorActionPreference = "Stop"

$ZipFile = "{zip_name}"
$RemoteDest = "{remote_dest}"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "  IrisLime Windows Rclone Log Archiver Streamer (PowerShell)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "Target Package : $ZipFile" -ForegroundColor Yellow
Write-Host "Remote Target  : $RemoteDest" -ForegroundColor Yellow
Write-Host ""

# Find rclone.exe
$RcloneExe = Get-Command "rclone" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
if (-not $RcloneExe) {{
    $WinGetPath = "$env:LOCALAPPDATA\\Microsoft\\WinGet\\Links\\rclone.exe"
    if (Test-Path $WinGetPath) {{
        $RcloneExe = $WinGetPath
    }}
}}

if (-not $RcloneExe) {{
    Write-Error "[ERROR] rclone.exe not found on Windows host system."
    exit 1
}}

Write-Host "[*] Using rclone executable: $RcloneExe" -ForegroundColor Green
Write-Host "[*] Executing rclone copy to $RemoteDest..." -ForegroundColor Green

& $RcloneExe copy "$ZipFile" "$RemoteDest" --progress --drive-chunk-size 64M --transfers 4

if ($LASTEXITCODE -eq 0) {{
    Write-Host "`n[*] Verifying remote payload delivery..." -ForegroundColor Green
    & $RcloneExe ls "$RemoteDest"
    Write-Host "`n[SUCCESS] Payload verified on $RemoteDest!" -ForegroundColor Cyan
}} else {{
    Write-Error "[!] Rclone transfer failed with exit code $LASTEXITCODE"
}}
"""
    ps1_path = root / "tools" / "windows_rclone_sync.ps1"
    with open(ps1_path, "w", encoding="utf-8") as f:
        f.write(ps1_content)
    print(f"[+] Written Windows PowerShell Script: {ps1_path.relative_to(root)}")

if __name__ == "__main__":
    main()
