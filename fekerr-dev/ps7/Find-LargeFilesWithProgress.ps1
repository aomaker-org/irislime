<#
.SYNOPSIS
    Recursively scans a directory for Tar archives (including compressed variants) with high-performance progress.
.DESCRIPTION
    Uses fast .NET enumeration to bypass Windows system junctions, filtering for .tar, .tar.gz, 
    .tar.xz, .tar.bz2, and .tgz files while ignoring unrelated "target" or "star" false positives.
.PARAMETER SearchPath
    The starting directory path to scan. Defaults to C:\.
.PARAMETER MinSizeMB
    The minimum file size in MB to display. Defaults to 0 (shows all).
#>
[CmdletBinding()]
param (
    [string]$SearchPath = "C:\",
    [double]$MinSizeMB = 0
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "          SMART FILE SYSTEM SCANNER: TAR ARCHIVE DETECTOR"
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "[*] Initializing search in: $SearchPath" -ForegroundColor Yellow
Write-Host "[*] Looking for:            .tar, .tar.gz, .tar.xz, .tar.bz2, .tgz" -ForegroundColor Yellow

$EnumOptions = [System.IO.EnumerationOptions]::new()
$EnumOptions.RecurseSubDirectories = $true
$EnumOptions.IgnoreInaccessible = $true

$MatchedFiles = [System.Collections.Generic.List[PSCustomObject]]::new()
$Counter = 0

# Regex to match true tar extensions: .tar, .tgz, or .tar.anything (e.g., .tar.gz, .tar.xz)
$TarRegex = "\.(tar|tgz)(\.[a-z0-9]+)?$"

try {
    # Broad scan for any file containing "tar" in the name/extension to catch compressed variants
    [System.IO.Directory]::EnumerateFiles($SearchPath, "*tar*", $EnumOptions) | ForEach-Object {
        $FileName = [System.IO.Path]::GetFileName($_)
        
        # Strictly match true tar extensions and discard "target", "start", etc.
        if ($FileName -match $TarRegex) {
            try {
                $File = [System.IO.FileInfo]::new($_)
                $SizeMB = [Math]::Round($File.Length / 1MB, 2)
                
                if ($SizeMB -ge $MinSizeMB) {
                    $MatchedFiles.Add([PSCustomObject]@{
                        Name         = $File.Name
                        Size_MB      = $SizeMB
                        LastModified = $File.LastWriteTime
                        Path         = $File.FullName
                    })
                }
            } catch {}
        }
        
        $Counter++
        # Perform low-overhead console overwrites to show the engine is actively working
        if ($Counter % 100 -eq 0) {
            [Console]::Write("`r[*] Analyzed candidates: $Counter | Matches: $($MatchedFiles.Count)")
        }
    }
}
catch {
    Write-Host "`n[!] Critical scan exception: $_" -ForegroundColor Red
}

# Clear the progress line
[Console]::Write("`r" + " " * 70 + "`r")

if ($MatchedFiles.Count -gt 0) {
    Write-Host "[+] Scan complete! Found $($MatchedFiles.Count) verified Tar archives:" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
    $MatchedFiles | Sort-Object Size_MB -Descending | Format-Table -AutoSize
} else {
    Write-Host "[-] Scan complete. No true Tar archives found in $SearchPath." -ForegroundColor Yellow
}
Write-Host "================================================================================" -ForegroundColor Cyan
# Integrity-Hash: ef900450e9cac9efa68c0374e7358f95d020ca98d49027f07f8bf97c86259310