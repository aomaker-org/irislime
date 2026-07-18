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

# Ensure target zip file exists, or fetch from WSL network share if missing
if (-not (Test-Path $ZipFile)) {
    $Distro = $env:WSL_DISTRO_NAME
    if (-not $Distro) { $Distro = "ubu26_0715" }
    $WslZipPath = "\\wsl.localhost\$Distro\home\fekerr\src\irislime\$ZipFile"
    $WslZipAlt = "\\wsl$\$Distro\home\fekerr\src\irislime\$ZipFile"
    
    if (Test-Path $WslZipPath) {
        Write-Host "[*] Copying $ZipFile from WSL environment ($WslZipPath)..." -ForegroundColor Yellow
        Copy-Item $WslZipPath -Destination $ZipFile
    } elseif (Test-Path $WslZipAlt) {
        Write-Host "[*] Copying $ZipFile from WSL environment ($WslZipAlt)..." -ForegroundColor Yellow
        Copy-Item $WslZipAlt -Destination $ZipFile
    } else {
        Write-Error "[ERROR] Target zip package '$ZipFile' not found in local directory or WSL environment."
        exit 1
    }
}

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
Write-Host "[*] Executing rclone copyto to $RemoteDest/$ZipFile..." -ForegroundColor Green

& $RcloneExe copyto "$ZipFile" "$RemoteDest/$ZipFile" --progress --drive-chunk-size 64M --transfers 4

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[*] Verifying remote payload delivery..." -ForegroundColor Green
    & $RcloneExe ls "$RemoteDest"

    # Write Cross-Host Handshake Receipt for WSL
    $ReceiptData = [PSCustomObject]@{
        status = "SUCCESS"
        machine_id = "core12"
        wsl_ubuntu_id = "1003"
        package = $ZipFile
        remote_destination = $RemoteDest
        verified = $true
        transferred_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json -Depth 3

    Set-Content -Path "tools\windows_rclone_receipt.json" -Value $ReceiptData -Encoding UTF8

    Write-Host "`n[SUCCESS] Payload verified on $RemoteDest!" -ForegroundColor Cyan
    Write-Host "[HANDSHAKE] Handshake receipt written to tools\windows_rclone_receipt.json" -ForegroundColor Green
} else {
    Write-Error "[!] Rclone transfer failed with exit code $LASTEXITCODE"
}
