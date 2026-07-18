<#
.SYNOPSIS
    Intelligently routes pipeline data to the clipboard, preventing clipboard bloat.
.DESCRIPTION
    If the output is small, it copies directly to the clipboard. If it is too large,
    it dumps the payload to a diagnostic log file and copies a short summary path descriptor.
#>
[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject,
    
    [int]$MaxCharacters = 20480, # ~20KB default threshold
    [string]$LogDir = "C:\Users\feker\src\fekerr-dev\logs"
)

begin {
    $Buffer = [System.Text.StringBuilder]::new()
}

process {
    if ($InputObject) {
        $null = $Buffer.AppendLine($InputObject)
    }
}

end {
    $FullText = $Buffer.ToString()
    if ([string]::IsNullOrWhiteSpace($FullText)) { return }
    
    if ($FullText.Length -le $MaxCharacters) {
        # Safe size: Send the exact output to the clipboard
        $FullText | clip.exe
    } else {
        # Overflow size: Save to file and copy a clean pointer
        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
        
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $FileName = "overflow_trace_${Timestamp}.log"
        $FileFullPath = Join-Path $LogDir $FileName
        
        # Write full content
        [System.IO.File]::WriteAllText($FileFullPath, $FullText, [System.Text.Encoding]::UTF8)
        
        # Construct clean summary receipt for clipboard
        $Receipt = @(
            "[!] CLIPBOARD OVERFLOW PROTECTION ACTIVE",
            "----------------------------------------------------------------",
            "The pipeline output exceeded the default copy safety threshold ($($MaxCharacters) chars).",
            "The full output trace has been safely dumped to disk.",
            "",
            "File Path: $FileFullPath",
            "File Size: $([Math]::Round($FullText.Length / 1KB, 2)) KB",
            "----------------------------------------------------------------"
        ) -join [System.Environment]::NewLine
        
        $Receipt | clip.exe
        Write-Host "[!] Large output threshold reached. Pointer receipt copied to clipboard." -ForegroundColor Yellow
    }
}

# Integrity-Hash: aacabcd818b3ae7bdbc3dad8cece8429c24be3f528b5b4985684fb68eca28965