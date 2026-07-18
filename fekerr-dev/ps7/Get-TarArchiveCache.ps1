<#
================================================================================
.SYNOPSIS
    Get-TarArchiveCache.ps1 - High-performance, cache-backed tar archive scanner.

.DESCRIPTION
    Sweeps a target directory recursively for compressed archives (.tar, .tgz, etc.),
    calculates their cryptographically secure SHA-256 hashes, caches the results
    locally as a path-hashed JSON registry, and writes a human-readable text report.

.PARAMETER ScanRoot
    The target directory path to search. Defaults to 'C:\Users\feker\src\fekerr-dev'.

.PARAMETER CacheDir
    Directory path where the JSON cache and reports are written. Defaults to '~/.irislime_cache'.

.PARAMETER CacheLifetimeHours
    Time-to-live limit for the local cache before requiring a physical disk resweep.

.PARAMETER ForceRecalculate
    Switch to bypass the cache entirely and force a fresh physical disk scan.

.NOTES
    File Name      : Get-TarArchiveCache.ps1
    Version        : 1.1.2
    Created        : 260715_1945 (July 15, 2026)
    Target Shell   : PowerShell 7.4+ (Cross-Platform)
================================================================================
#>

# Enforce UTF-8 across the host process to resolve Windows console encoding (Mojibake)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Get-TarArchiveCache {
    [CmdletBinding()]
    param(
        [string]$ScanRoot = "C:\Users\feker\src\fekerr-dev",
        [string]$CacheDir = "$HOME/.irislime_cache",
        [int]$CacheLifetimeHours = 24,
        [switch]$ForceRecalculate
    )

    # Helper function: Stream-read physical files to calculate SHA-256 hashes efficiently
    function Get-FileSHA256 {
        param([string]$FilePath)
        try {
            $Stream = [System.IO.File]::OpenRead($FilePath)
            $SHA = [System.Security.Cryptography.SHA256]::Create()
            $HashBytes = $SHA.ComputeHash($Stream)
            $Stream.Close()
            $Stream.Dispose()
            return ($HashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
        } catch {
            return "ACCESS_DENIED_OR_FILE_LOCKED"
        }
    }

    # Normalize scan target path
    if (-not (Test-Path $ScanRoot)) {
        Write-Error "The specified directory does not exist: $ScanRoot"
        return
    }
    $ResolvedPath = (Resolve-Path $ScanRoot).Path
    
    # Compute MD5 hash of the normalized path string for unique cache segregation
    $PathBytes = [System.Text.Encoding]::UTF8.GetBytes($ResolvedPath.ToLower())
    $Hasher = [System.Security.Cryptography.MD5]::Create()
    $HashBytes = $Hasher.ComputeHash($PathBytes)
    $PathHash = ($HashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
    
    # Ensure cache workspace exists
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }
    
    $CacheFile = Join-Path $CacheDir "tar_scan_$($PathHash).json"
    $ReportFile = Join-Path $CacheDir "tar_scan_report_$($PathHash).txt"
    $CacheExists = Test-Path $CacheFile
    $UseCache = $false

    # Evaluate cache validity
    if ($CacheExists -and -not $ForceRecalculate) {
        $LastModified = (Get-Item $CacheFile).LastWriteTime
        if ($LastModified -gt (Get-Date).AddHours(-$CacheLifetimeHours)) {
            $UseCache = $true
        }
    }

    $Timestamp = Get-Date -Format "yyMMdd_HHmm"

    if ($UseCache) {
        Write-Host "⚡ [CACHE HIT] Fetching archive registry from: tar_scan_$($PathHash).json" -ForegroundColor Green
        $Files = Get-Content $CacheFile -Raw | ConvertFrom-Json
    }
    else {
        Write-Host "🔍 [CACHE MISS] Running physical sweep and computing SHA-256 hashes..." -ForegroundColor Cyan
        $Extensions = "*.tar", "*.tar.gz", "*.tar.xz", "*.tar.bz2", "*.tgz"
        
        $RawFiles = Get-ChildItem -Path $ResolvedPath -Include $Extensions -Recurse -File -ErrorAction SilentlyContinue
        $Files = [System.Collections.Generic.List[PSObject]]::new()

        foreach ($File in $RawFiles) {
            Write-Host "  └─ Hashing: $($File.Name)" -ForegroundColor Gray
            $Hash = Get-FileSHA256 -FilePath $File.FullName
            
            $Files.Add([PSCustomObject]@{
                Name         = $File.Name
                Size_MB      = [math]::round($File.Length / 1MB, 2)
                LastModified = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                SHA256       = $Hash
                Path         = $File.FullName
            })
        }

        # Commit scan results to cache
        $Files | ConvertTo-Json -Depth 3 | Out-File $CacheFile -Encoding utf8
        Write-Host "💾 [CACHE SAVE] Updated cache index: tar_scan_$($PathHash).json" -ForegroundColor Yellow
    }

    # Generate the Standardized Text Report payload
    $Header = @"
================================================================================
[ $Timestamp ] IRISLIME LOCAL FILE REGISTRY REPORT
Scan Path : $ResolvedPath
Host Shell: PS7 $($PSVersionTable.PSVersion)
================================================================================
"@

    $Footer = @"
================================================================================
Total Registered Archives : $($Files.Count)
Local Cache Reference     : $CacheFile
[ EOF ]
================================================================================
"@

    $ReportContent = [System.Text.StringBuilder]::new()
    [void]$ReportContent.AppendLine($Header)
    
    if ($Files.Count -eq 0) {
        [void]$ReportContent.AppendLine("  No archives matching target extensions were found in this directory.")
    } else {
        foreach ($File in $Files) {
            [void]$ReportContent.AppendLine("File: $($File.Name)")
            [void]$ReportContent.AppendLine("  Size    : $($File.Size_MB) MB")
            [void]$ReportContent.AppendLine("  Modified: $($File.LastModified)")
            [void]$ReportContent.AppendLine("  SHA-256 : $($File.SHA256)")
            [void]$ReportContent.AppendLine("  Location: $($File.Path)")
            [void]$ReportContent.AppendLine("-" * 80)
        }
    }
    
    [void]$ReportContent.AppendLine($Footer)
    
    # Write report back to disk using UTF-8
    $ReportContent.ToString() | Out-File $ReportFile -Encoding utf8

    # Output to the host terminal
    Write-Output $ReportContent.ToString()
}

# Run execution (Checking if arguments were passed to the script, else fallback)
$TargetFolder = if ($args.Count -gt 0) { $args[0] } else { "C:\Users\feker\src\fekerr-dev" }
Get-TarArchiveCache -ScanRoot $TargetFolder
