[CmdletBinding()]
param (
    [string[]]$Remotes = @("onedrive", "gdrive", "gaom"),
    [string]$CacheDir = "$env:USERPROFILE\src\fekerr-dev\rclone_cache"
)

if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             MULTI-CLOUD CACHE BUILDER: SLOW & GENTLE METADATA INDEXER"
Write-Host "================================================================================" -ForegroundColor Cyan

foreach ($RemoteName in $Remotes) {
    $FullRemote = "$($RemoteName):"
    $CacheFile = Join-Path $CacheDir "cache_$($RemoteName)_tree.json"
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    Write-Host "[*] Commencing recursive sweep of remote '$FullRemote'..." -ForegroundColor Yellow
    
    $RcloneArgs = @(
        "lsjson",`n        "-R",`n        "--fast-list",`n        "--no-mimetype",`n        "--exclude",`n        "/Personal Vault/**",
        $FullRemote
    )
    
    try {
        $RawJson = & rclone.exe $RcloneArgs 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[!] Rclone execution failed for $FullRemote. Error: $RawJson"
            continue
        }
        
        $ParsedItems = $RawJson | ConvertFrom-Json
        
        $CachePayload = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                generated_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss 'UTC'")
                source_remote = $FullRemote
                total_items = $ParsedItems.Count
                generation_duration_sec = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)
            }
            items = $ParsedItems
        }
        
        $CachePayload | ConvertTo-Json -Depth 10 | Out-File -FilePath $CacheFile -Encoding utf8
        
        Write-Host "[+] Index complete for '$FullRemote'! Saved to $CacheFile" -ForegroundColor Green
        Write-Host "    Indexed $($ParsedItems.Count) items in $($CachePayload.metadata.generated_at_duration_sec) seconds.`n" -ForegroundColor Green
    }
    catch {
        # Escaped the colon with a backtick to prevent parser namespace scoping errors
        Write-Error "[!] Critical failure compiling index for remote `$FullRemote`: $_"
    }
    finally {
        $Stopwatch.Stop()
    }
}

Write-Host "================================================================================" -ForegroundColor Cyan
# Integrity-Hash: 243af01e23fceb9e21d2a99cdacd6440d258ee94ab0bc8db6fb9d4a392691e4d

