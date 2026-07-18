[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [ValidateSet("onedrive", "gdrive", "gaom", "all")]
    [string]$Remote = "all",
    [string]$CacheDir = "$env:USERPROFILE\src\fekerr-dev\rclone_cache"
)

function Get-HumanSize ([double]$Bytes) {
    $Sizes = @("B", "KB", "MB", "GB", "TB")
    $Index = 0
    while ($Bytes -ge 1024 -and $Index -lt $Sizes.Count - 1) {
        $Bytes /= 1024
        $Index++
    }
    return "{0:N2} {1}" -f $Bytes, $Sizes[$Index]
}

Write-Host "[*] Querying local cloud metadata indices for term: '$Query'..." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

$TargetRemotes = if ($Remote -eq "all") { @("onedrive", "gdrive", "gaom") } else { @($Remote) }

foreach ($Target in $TargetRemotes) {
    $CacheFile = Join-Path $CacheDir "cache_$($Target)_tree.json"
    if (-not (Test-Path $CacheFile)) {
        Write-Host "[!] Skipping '$Target': Cache index file absent. Run Sync-CloudCache.ps1 first." -ForegroundColor Gray
        continue
    }
    
    $Data = Get-Content $CacheFile -Raw | ConvertFrom-Json
    Write-Host "[*] Searching '$Target' [Cached: $($Data.metadata.generated_at)]..." -ForegroundColor Yellow
    
    $Matches = $Data.items | Where-Object { $_.Path -like "*$Query*" -or $_.Name -like "*$Query*" }
    
    if ($Matches) {
        foreach ($Item in $Matches) {
            $Type = if ($Item.IsDir) { "[DIR]" } else { "[FIL]" }
            $Size = if ($Item.IsDir) { "DIR" } else { Get-HumanSize $Item.Size }
            Write-Host "  $Type  $($Size.PadRight(12))  $($Item.Path)"
        }
    } else {
        Write-Host "  [-] No matches located inside '$Target' index." -ForegroundColor Gray
    }
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}
# Integrity-Hash: 18d44f1cd0c80f7f93404aba07a2ba168110ec70f4f27a30ed31fcc88641ca2d
