# ==============================================================================
# Filename:     tools/tail_all_logs.ps1
# Purpose:      Real-time Multi-Log Stream Telemetry Tail Utility
# Target OS:    Windows 11 PowerShell 7 / Windows Terminal
# Lineage:      IrisLime Infrastructure
# Usage:        pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\tail_all_logs.ps1
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   IrisLime Real-Time Multi-Log Stream Telemetry Tail    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$WorkspaceRoot = Get-Location
$LogDir = Join-Path $WorkspaceRoot "logs"

Write-Host "[*] Workspace Root: $WorkspaceRoot" -ForegroundColor Yellow
Write-Host "[*] Log Directory : $LogDir" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor Gray

# Find active log files
$LogFiles = Get-ChildItem -Path $LogDir -Recurse -Filter "*.log" | Select-Object -ExpandProperty FullName
$CsvFiles = Get-ChildItem -Path $LogDir -Recurse -Filter "*.csv" | Select-Object -ExpandProperty FullName
$AllTargets = $LogFiles + $CsvFiles

if (-not $AllTargets) {
    Write-Host "[!] No active log files found under $LogDir" -ForegroundColor Red
    Exit 1
}

Write-Host "[+] Monitoring $($AllTargets.Count) log targets simultaneously:" -ForegroundColor Green
foreach ($f in $AllTargets) {
    Write-Host "    - $f" -ForegroundColor DarkGray
}
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "[*] Streaming live log feeds (Press Ctrl+C to stop)...`n" -ForegroundColor Cyan

Get-Content -Path $AllTargets -Wait -Tail 10
