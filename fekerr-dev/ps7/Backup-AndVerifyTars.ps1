<#
.SYNOPSIS
    Gathers local .tar files, generates a manifest, syncs them to Google Drive and OneDrive,
    performs cryptographic verification checks, and safely deletes the original host files.
.DESCRIPTION
    Dual-cloud replication and cleanup utility with strict hash-verification safety boundaries.
#>
[CmdletBinding()]
param (
    [string]$EntityID = $(if ($env:ENTITY_ID) { $env:ENTITY_ID } elseif ($env:CORE_ID) { $env:CORE_ID } else { "core01" }),
    [string]$SearchPath = "C:\",
    [string]$StagingDir = "C:\Users\feker\src\fekerr-dev\staging_tars",
    [string]$GDriveTarget = "",
    [string]$OneDriveTarget = ""
)

if ([string]::IsNullOrEmpty($GDriveTarget)) { $GDriveTarget = "gdrive:transfer/tars/$EntityID" }
if ([string]::IsNullOrEmpty($OneDriveTarget)) { $OneDriveTarget = "onedrive:transfer/tars/$EntityID" }

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "              DUAL-CLOUD REPLICATION & SAFE REMOVAL PIPELINE"
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Initialize Staging Boundaries
if (-not (Test-Path $StagingDir)) {
    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null
}

# 2. Gather .tar Files (excluding files inside the staging directory or Python/Program Files)
Write-Host "[*] Gathering target .tar assets on host..." -ForegroundColor Yellow
$EnumOptions = [System.IO.EnumerationOptions]::new()
$EnumOptions.RecurseSubDirectories = $true
$EnumOptions.IgnoreInaccessible = $true

$Tars = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
[System.IO.Directory]::EnumerateFiles($SearchPath, "*.tar", $EnumOptions) | ForEach-Object {
    try {
        $File = [System.IO.FileInfo]::new($_)
        # Skip files that are already inside staging, AppData, or third-party program directories
        if ($File.FullName -notmatch "staging_tars|AppData|Local\\Temp|Program Files|Python") {
            $Tars.Add($File)
        }
    } catch {}
}

if ($Tars.Count -eq 0) {
    Write-Host "[-] No candidate .tar files discovered for migration. Exiting." -ForegroundColor Yellow
    return
}

# 3. Generate Manifest File
$ManifestPath = Join-Path $StagingDir "tars_manifest.txt"
Write-Host "[*] Generating cryptographic manifest: $ManifestPath" -ForegroundColor Yellow

$ManifestLines = [System.Collections.Generic.List[string]]::new()
$ManifestLines.Add("================================================================================")
$ManifestLines.Add("                   MIGRATED TAR ARCHIVE MANIFEST - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$ManifestLines.Add("================================================================================")

foreach ($Tar in $Tars) {
    Write-Host "    - Hash indexing: $($Tar.Name) ($([Math]::Round($Tar.Length/1MB, 2)) MB)" -ForegroundColor Gray
    $MD5 = (Get-FileHash -Path $Tar.FullName -Algorithm MD5).Hash
    $ManifestLines.Add("File:         $($Tar.Name)")
    $ManifestLines.Add("OriginalPath: $($Tar.FullName)")
    $ManifestLines.Add("Size(Bytes):  $($Tar.Length)")
    $ManifestLines.Add("MD5-Hash:     $MD5")
    $ManifestLines.Add("--------------------------------------------------------------------------------")
}

[System.IO.File]::WriteAllLines($ManifestPath, $ManifestLines, [System.Text.Encoding]::UTF8)

# 4. Copying Files to Staging
Write-Host "[*] Staging assets locally before replication..." -ForegroundColor Yellow
foreach ($Tar in $Tars) {
    $TargetCopyPath = Join-Path $StagingDir $Tar.Name
    if (-not (Test-Path $TargetCopyPath) -or (Get-Item $TargetCopyPath).Length -ne $Tar.Length) {
        Write-Host "    -> Copying $($Tar.Name) to staging..." -ForegroundColor Gray
        Copy-Item -Path $Tar.FullName -Destination $TargetCopyPath -Force
    }
}

# 5. Execute Rclone Uploads
Write-Host "[*] Uploading staging package to Google Drive..." -ForegroundColor Yellow
rclone copy "$StagingDir" "$GDriveTarget" --progress --fast-list

Write-Host "[*] Uploading staging package to OneDrive..." -ForegroundColor Yellow
rclone copy "$StagingDir" "$OneDriveTarget" --progress --fast-list

# 6. Cryptographic Cloud Integrity Verification
Write-Host "[*] Performing end-to-end cryptographic integrity checks..." -ForegroundColor Yellow

$GDriveCheck = $true
$OneDriveCheck = $true

Write-Host "    - Checking Google Drive storage..." -ForegroundColor Yellow
rclone check "$StagingDir" "$GDriveTarget" --one-way --fast-list 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Google Drive verification: PASSED" -ForegroundColor Green
} else {
    Write-Host "[!] Google Drive verification: FAILED! Mismatched files or errors detected." -ForegroundColor Red
    $GDriveCheck = $false
}

Write-Host "    - Checking OneDrive storage..." -ForegroundColor Yellow
rclone check "$StagingDir" "$OneDriveTarget" --one-way --fast-list 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] OneDrive verification: PASSED" -ForegroundColor Green
} else {
    Write-Host "[!] OneDrive verification: FAILED! Mismatched files or errors detected." -ForegroundColor Red
    $OneDriveCheck = $false
}

# 7. Safe Deletion Protocol (Requires both clouds to verify cleanly)
if ($GDriveCheck -and $OneDriveCheck) {
    Write-Host "[+] 100% cloud integrity verified. Initiating safe host file cleanup..." -ForegroundColor Green
    foreach ($Tar in $Tars) {
        if (Test-Path $Tar.FullName) {
            Write-Host "    - Purging host file: $($Tar.FullName)" -ForegroundColor Red
            Remove-Item -Path $Tar.FullName -Force -Confirm:$false
        }
    }
    
    # Empty out staging workspace files, leaving the local manifest as a historical marker
    Get-ChildItem -Path $StagingDir -File | Where-Object { $_.Name -ne "tars_manifest.txt" } | Remove-Item -Force
    Write-Host "[+] Host cleanup complete. Local manifest preserved at: $ManifestPath" -ForegroundColor Green
} else {
    Write-Host "[X] Safety Abort: Cloud verification failed. Host files preserved!" -ForegroundColor Red
}
Write-Host "================================================================================" -ForegroundColor Cyan
# Integrity-Hash: 61d91fd91547c2c1716ebb2666f607259b8c76a5a873d262471910ec8caaa2a1