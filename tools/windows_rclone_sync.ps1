# ==============================================================================
# IrisLime Windows Rclone Log Archiver & Cloud Streamer (PowerShell)
# Target Remote: gdrive:transfer/20260718_logs_core12_1003
# Package: 20260718_logs_core12_1003.zip
# ==============================================================================

$ErrorActionPreference = "Stop"

$ZipFile = "20260718_logs_core12_1003.zip"
$RemoteDest = "gdrive:transfer/20260718_logs_core12_1003"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "  IrisLime Windows Rclone Log Archiver Streamer (PowerShell)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "Target Package : $ZipFile" -ForegroundColor Yellow
Write-Host "Remote Target  : $RemoteDest" -ForegroundColor Yellow
Write-Host ""

# Find rclone.exe
$RcloneExe = Get-Command "rclone" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
if (-not $RcloneExe) {
    $WinGetPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\rclone.exe"
    if (Test-Path $WinGetPath) {
        $RcloneExe = $WinGetPath
    }
}

if (-not $RcloneExe) {
    Write-Error "[ERROR] rclone.exe not found on Windows host system."
    exit 1
}

Write-Host "[*] Using rclone executable: $RcloneExe" -ForegroundColor Green
Write-Host "[*] Executing rclone copy to $RemoteDest..." -ForegroundColor Green

& $RcloneExe copy "$ZipFile" "$RemoteDest" --progress --drive-chunk-size 64M --transfers 4

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[*] Verifying remote payload delivery..." -ForegroundColor Green
    & $RcloneExe ls "$RemoteDest"
    Write-Host "`n[SUCCESS] Payload verified on $RemoteDest!" -ForegroundColor Cyan
} else {
    Write-Error "[!] Rclone transfer failed with exit code $LASTEXITCODE"
}
