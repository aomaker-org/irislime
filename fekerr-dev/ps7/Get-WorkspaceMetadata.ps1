<#
.SYNOPSIS
    Phase A 'Big Scrub' Metadata Discovery Tool.
.DESCRIPTION
    Sweeps through a target directory tree to build an inventory map of file metadata 
    without reading file contents. Designed to minimize memory and disk I/O impact.
.PARADIGMS (PowerShell vs. Python)
    - Uses .NET Framework compilation classes ([System.IO.Directory]) for rapid pipeline streaming.
    - Python translation equivalent would utilize 'os.scandir()' to yield generator objects.
    - Forces strict flat ASCII output formatting to ensure clean downstream parsing.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScanSource = "C:\Users\feker\src",

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "C:\Users\feker\src\fekerr-dev\docs\workspace_meta_index.txt"
)

# --- ENVIRONMENT & PRE-FLIGHT CHECKS ---
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$TargetDir = Split-Path -Path $OutputFile

# Ensure destination directory structure exists safely
if ($TargetDir -and !(Test-Path -Path $TargetDir -PathType Container)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# Write a clean, flat ASCII header block to clear any previous files
$Header = @"
======================================================================
PHASE A: 'BIG SCRUB' DISCOVERY METADATA INDEX
Generated (UTC): $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss'))
Target Scope: $ScanSource
======================================================================
"@
$Header | Out-File -FilePath $OutputFile -Encoding ascii -Force

# --- THE SCANNING ENGINE ---
# Regex pattern to filter out noisy dependency graphs and environment configurations
# Trailing backslash match avoids checking directories we want to completely skip
$SkipPattern = '\\(node_modules|\.git|venv|\.venv|obj|bin|dist|cache)\\ '

Write-Host "[*] Launching system sweep across: $ScanSource" -ForegroundColor Cyan
Write-Host "[*] I/O Optimization: Reading metadata structures only. Ignoring dependencies." -ForegroundColor Yellow

try {
    # .NET Paradigm: EnumerateFiles is a lazy-loaded streaming iterator.
    # Unlike Get-ChildItem, it does not collect all items into memory at once,
    # keeping our memory footprint locked low while WSL processes heavy export streams.
    [System.IO.Directory]::EnumerateFiles($ScanSource, "*", [System.IO.SearchOption]::AllDirectories) | 
        ForEach-Object {
            # Check the file path string against our skip regex engine
            if ($_ -notmatch $SkipPattern) {
                
                # Instantiating a lean file object to grab filesystem pointers
                $FileRef = [System.IO.FileInfo]::new($_)
                
                # Derive relative pathing for cleaner text tracking down-pipeline
                $RelativePath = $_.Replace($ScanSource, "")

                # Construct a strict, comma-separated flat ASCII payload line
                $MetaLine = "[FILE] Name: {0} | Size: {1} bytes | LastWrite: {2} | RelPath: {3}" -f 
                    $FileRef.Name, 
                    $FileRef.Length, 
                    $FileRef.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'), 
                    $RelativePath
                
                # Stream immediately out to the file using flat ASCII encoding bytes
                $MetaLine | Out-File -FilePath $OutputFile -Encoding ascii -Append
            }
        }
}
catch {
    $ErrorMsg = "[CRITICAL SCAN ERROR]: $_"
    $ErrorMsg | Out-File -FilePath $OutputFile -Encoding ascii -Append
    Write-Error $_
}
finally {
    $Stopwatch.Stop()
    
    # Calculate final indexing footprint
    $LineCount = (Get-Content -Path $OutputFile).Count
    $TotalFilesIndexed = if ($LineCount -gt 5) { $LineCount - 5 } else { 0 }

    # Append structural session footer data
    $Footer = @"
----------------------------------------------------------------------
DISCOVERY SCANNED COMPLETED
Execution Duration   : $($Stopwatch.Elapsed.TotalSeconds) seconds
Total Files Indexed  : $TotalFilesIndexed
======================================================================
"@
    $Footer | Out-File -FilePath $OutputFile -Encoding ascii -Append
    
    Write-Host "[+] Phase A Index compiled successfully at $OutputFile" -ForegroundColor Green
}
