
[CmdletBinding()]
param (
    [string]$Path = '.',
    [string[]]$ExcludeDirs = @('.git', '.venv', 'logs', 'rclone_cache', 'node_modules', 'AppData'),
    [string[]]$IncludeExtensions = @('.ps1', '.py', '.toml', '.json', '.txt', '.sh', '.md', '.agy')
)

Write-Host '[*] Harvesting workspace files...' -ForegroundColor Yellow

$Files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $FilePath = $_.FullName
    $IsExcluded = $false
    foreach ($Exclude in $ExcludeDirs) {
        if ($FilePath -like '*\' + $Exclude + '\*') {
            $IsExcluded = $true
            break
        }
    }
    $IsIncludedExt = $false
    foreach ($Ext in $IncludeExtensions) {
        if ($_.Extension -eq $Ext) {
            $IsIncludedExt = $true
            break
        }
    }
    (-not $IsExcluded) -and $IsIncludedExt
}

if (-not $Files) {
    Write-Warning '[-] No matching files found to export.'
    return
}

$Buffer = [System.Text.StringBuilder]::new()
$Buffer.AppendLine('================================================================================') | Out-Null
$Buffer.AppendLine('FEKERR-DEV WORKSPACE HARVEST') | Out-Null
$Buffer.AppendLine('================================================================================') | Out-Null

foreach ($File in $Files) {
    try {
        $RelativePath = Resolve-Path $File.FullName -Relative
        $Buffer.AppendLine('--- PATH: ' + $RelativePath + ' ---') | Out-Null
        $Buffer.AppendLine('`') | Out-Null
        $Buffer.AppendLine((Get-Content $File.FullName -Raw)) | Out-Null
        $Buffer.AppendLine('`') | Out-Null
    }
    catch {
        Write-Warning '[-] Could not read content for file: ' + $File.FullName
    }
}

$FinalText = $Buffer.ToString()
$FinalText | Set-Clipboard

Write-Host '[+] Exported ' + $Files.Count + ' files directly to the system clipboard!' -ForegroundColor Green
# Integrity-Hash: 17a12ad9561596a0b941c9c8421c9d267f56814281c8980451f6ef15d897d59b

