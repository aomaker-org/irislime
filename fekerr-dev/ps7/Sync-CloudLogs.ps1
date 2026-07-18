<#
.SYNOPSIS
    Sweeps local execution logs and telemetry data to dual-cloud locations with unified metadata tracking.
.DESCRIPTION
    Scans local log directories, packages them with run-time environment context, 
    uploads to Google Drive and OneDrive, and manages local workspace rotation.
#>
[CmdletBinding()]
param (
    [string]$EntityID = $(if ($env:ENTITY_ID) { $env:ENTITY_ID } elseif ($env:CORE_ID) { $env:CORE_ID } else { "core01" }),
    [string]$LogsDir = "C:\Users\feker\src\fekerr-dev\logs",
    [string]$GDriveTarget = "",
    [string]$OneDriveTarget = ""
)

if ([string]::IsNullOrEmpty($GDriveTarget)) { $GDriveTarget = "gdrive:transfer/rcloned_logs/$EntityID" }
if ([string]::IsNullOrEmpty($OneDriveTarget)) { $OneDriveTarget = "onedrive:transfer/rcloned_logs/$EntityID" }

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                    WORKSPACE TELEMETRY & LOG REPLICATION SWEEP"
Write-Host "================================================================================" -ForegroundColor Cyan

if (-not (Test-Path $LogsDir)) {
    Write-Host "[-] Log directory not found. Nothing to sweep." -ForegroundColor Yellow
    return
}

# 1. Gather active files to replicate (Bypassing PS Bug #16695 by avoiding -Exclude with -File)
$LogFiles = Get-ChildItem -Path $LogsDir -File | Where-Object { $_.Name -ne "cloud_sweep_manifest.json" }
if (-not $LogFiles -or $LogFiles.Count -eq 0) {
    Write-Host "[-] No diagnostic telemetry files are currently queued for replication." -ForegroundColor Yellow
    return
}

# 2. Build the unified tracking manifest metadata
$ManifestPath = Join-Path $LogsDir "cloud_sweep_manifest.json"
Write-Host "[*] Packaging sweep telemetry metadata..." -ForegroundColor Yellow

$Metadata = @{
    Timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
    HostMachine = $env:COMPUTERNAME
    User        = $env:USERNAME
    FilesCount  = $LogFiles.Count
    Payload     = [System.Collections.Generic.List[PSCustomObject]]::new()
}

foreach ($File in $LogFiles) {
    $Hash = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash
    $Metadata.Payload.Add([PSCustomObject]@{
        Name    = $File.Name
        Size    = $File.Length
        SHA256  = $Hash
    })
    Write-Host "    -> Indexed: $($File.Name) ($Hash)" -ForegroundColor Gray
}

# Save serialized JSON manifest
$Metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $ManifestPath -Encoding utf8

# 3. Synchronize to Google Drive
Write-Host "[*] Replicating log files to Google Drive..." -ForegroundColor Yellow
rclone copy "$LogsDir" "$GDriveTarget" --progress --fast-list

# 4. Synchronize to OneDrive
Write-Host "[*] Replicating log files to OneDrive..." -ForegroundColor Yellow
rclone copy "$LogsDir" "$OneDriveTarget" --progress --fast-list

# 5. Verify the cloud footprint
Write-Host "[*] Verifying cryptographic upload states..." -ForegroundColor Yellow
$GCheck = $true
$OCheck = $true

rclone check "$LogsDir" "$GDriveTarget" --one-way --fast-list 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { $GCheck = $false }

rclone check "$LogsDir" "$OneDriveTarget" --one-way --fast-list 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { $OCheck = $false }

# 6. Safe Rotation Deletion Pass
if ($GCheck -and $OCheck) {
    Write-Host "[+] Dual-cloud verification passed! Rotating local telemetry files." -ForegroundColor Green
    # Keep the tracking manifest as a historical marker on the host partition
    $LogFiles | ForEach-Object {
        Write-Host "    - Pruning local target: $($_.Name)" -ForegroundColor Red
        Remove-Item $_.FullName -Force
    }
} else {
    Write-Host "[!] Verification mismatch detected. Preserving local diagnostic log files." -ForegroundColor Red
}
Write-Host "================================================================================" -ForegroundColor Cyan

# Integrity-Hash: be4f7c1fa1e0bbddcc646b056ec193210a9366c651ff7cc51ef40b00719ccf70