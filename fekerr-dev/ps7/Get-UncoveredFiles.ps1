<#
.SYNOPSIS
    Identifies files in a Git repository that are untracked or ignored, and bundles them.
.DESCRIPTION
    Queries Git for ignored or untracked telemetry and scratch files, generates a
    ZIP package in the absolute logs directory, and appends companion metadata.
    Uses deep path segment pruning to skip build, virtualenv, and node_modules folders.
.PARAMETER RepoPath
    The local filesystem path to the target Git repository.
.PARAMETER OutputDir
    The destination directory for the generated ZIP and metadata files.
#>
[CmdletBinding()]
param (
    [string]$RepoPath = "C:\Users\feker\src\irislime",
    [string]$OutputDir = "C:\Users\feker\src\fekerr-dev\logs"
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             WORKSPACE AUDITOR: UNCOVERED FILE PACKAGER (OPTIMIZED)"
Write-Host "================================================================================" -ForegroundColor Cyan

if (-not (Test-Path $RepoPath)) {
    Write-Error "Target repository path not found: $RepoPath"
    return
}

Push-Location $RepoPath
try {
    $Null = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "The directory at $RepoPath is not a valid Git repository."
        return
    }

    Write-Host "[*] Auditing git status for uncovered files (untracked & ignored)..." -ForegroundColor Yellow
    
    # Get raw untracked & ignored listing from git
    $RawPaths = git ls-files --others --ignored --exclude-standard
    
    if ($RawPaths.Count -eq 0 -or [string]::IsNullOrEmpty($RawPaths)) {
        Write-Host "[+] All files in this repository are covered under standard tracking. Nothing to do." -ForegroundColor Green
        return
    }

    # Dynamic Deep Exclusion Block
    # These rules match if any single folder segment in the relative path matches the name.
    $ExcludedSegments = @(".venv", "node_modules", ".git", ".ccache", "__pycache__", "build", "dist", "out", "target")
    $UncoveredPaths = [System.Collections.Generic.List[string]]::new()
    
    foreach ($Path in $RawPaths) {
        if ([string]::IsNullOrEmpty($Path)) { continue }
        
        # Standardize slashes to forward-slash format and split into distinct directory segments
        $NormalizedPath = $Path.Replace("\", "/")
        $Segments = $NormalizedPath.Split("/")
        
        $IsExcluded = $false
        foreach ($Segment in $Segments) {
            if ($ExcludedSegments -contains $Segment) {
                $IsExcluded = $true
                break
            }
        }
        
        if (-not $IsExcluded) {
            $UncoveredPaths.Add($NormalizedPath)
        }
    }
    
    if ($UncoveredPaths.Count -eq 0) {
        Write-Host "[+] All uncovered items are environment or build directories (venv, build, node_modules, etc.). Skipping." -ForegroundColor Green
        return
    }

    # Initialize unique run identifiers
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $RepoName = (Split-Path $RepoPath -Leaf)
    $ZipName = "uncovered_${RepoName}_${Timestamp}.zip"
    $ZipFullPath = Join-Path $OutputDir $ZipName
    $MetaFullPath = $ZipFullPath.Replace(".zip", ".meta")

    Write-Host "[+] Found $($UncoveredPaths.Count) non-environment, non-build uncovered files. Packaging..." -ForegroundColor Green
    
    # Temporary staging folder for zipping to preserve path structures
    $StagingFolder = Join-Path $env:TEMP "git_uncovered_staging_${Timestamp}"
    New-Item -ItemType Directory -Path $StagingFolder -Force | Out-Null

    $FileIndex = [System.Collections.Generic.List[string]]::new()
    foreach ($RelativePath in $UncoveredPaths) {
        $SourceFile = Join-Path $RepoPath $RelativePath
        if (Test-Path $SourceFile -PathType Leaf) {
            $DestFile = Join-Path $StagingFolder $RelativePath
            $DestDir = Split-Path $DestFile
            if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
            Copy-Item -Path $SourceFile -Destination $DestFile -Force
            $FileIndex.Add($RelativePath)
            Write-Host "    -> Staged: $RelativePath" -ForegroundColor Gray
        }
    }

    # Create the zip archive
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    Compress-Archive -Path "$StagingFolder\*" -DestinationPath $ZipFullPath -Force
    Remove-Item -Path $StagingFolder -Recurse -Force
    
    # Calculate Zip Hash
    $Hash = (Get-FileHash -Path $ZipFullPath -Algorithm SHA256).Hash

    # Build and write metadata companion manifest
    $Metadata = @{
        ArchiveName = $ZipName
        Timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
        SourceRepo  = $RepoName
        SHA256      = $Hash
        FilesCount  = $FileIndex.Count
        Contents    = $FileIndex
        Purpose     = "Backup package of untracked/ignored workspace logs and telemetry files (deep folder segment exclusion active)"
    }
    $Metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $MetaFullPath -Encoding utf8

    Write-Host "[+] Package established successfully!" -ForegroundColor Green
    Write-Host "    Archive:  $ZipFullPath" -ForegroundColor Gray
    Write-Host "    Metadata: $MetaFullPath" -ForegroundColor Gray
}
finally {
    Pop-Location
    Write-Host "================================================================================" -ForegroundColor Cyan
}
