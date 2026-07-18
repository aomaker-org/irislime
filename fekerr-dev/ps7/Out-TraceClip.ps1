function Out-TraceClip {
    <#
    .SYNOPSIS
        Executes a PowerShell command block, tracks millisecond delta-timings,
        streams outputs to the screen, copies the trace to the clipboard, and logs to disk.
    .EXAMPLE
        Out-TraceClip { Get-Process | Select-Object -First 10 }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [string]$LogDir = "$env:USERPROFILE\src\fekerr-dev\logs"
    )

    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $TimestampStart = Get-Date -Format "yyyy-MM-dd HH:mm:ss 'UTC'"
    $FileTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogPath = Join-Path $LogDir "ps_diagnostic_$FileTimestamp.log"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $OutputBuffer = [System.Collections.Generic.List[string]]::new()

    $Header = @"
================================================================================
DIAGNOSTIC RUN: $Command
STARTED AT:     $TimestampStart
================================================================================
"@
    Write-Host $Header -ForegroundColor Cyan
    $OutputBuffer.Add($Header)

    # Invoke the script block, capturing standard, warning, and error streams
    try {
        $Output = Invoke-Command -ScriptBlock $Command 3>&1 4>&1 5>&1 6>&1 -ErrorVariable StreamError
        
        foreach ($Line in $Output) {
            $Elapsed = $Stopwatch.Elapsed.TotalSeconds
            $FormattedLine = "[{0:000.000}] [stdout]: $Line" -f $Elapsed
            Write-Host $FormattedLine
            $OutputBuffer.Add($FormattedLine)
        }

        if ($StreamError) {
            foreach ($Err in $StreamError) {
                $Elapsed = $Stopwatch.Elapsed.TotalSeconds
                $FormattedLine = "[{0:000.000}] [stderr]: $Err" -f $Elapsed
                Write-Host $FormattedLine -ForegroundColor Red
                $OutputBuffer.Add($FormattedLine)
            }
        }
    }
    catch {
        $Elapsed = $Stopwatch.Elapsed.TotalSeconds
        $FormattedLine = "[{0:000.000}] [stderr]: $_" -f $Elapsed
        Write-Host $FormattedLine -ForegroundColor Red
        $OutputBuffer.Add($FormattedLine)
    }

    $Stopwatch.Stop()
    $ExitCode = $LASTEXITCODE

    $Footer = @"
================================================================================
EXIT CODE:      $ExitCode
================================================================================
"@
    Write-Host $Footer -ForegroundColor Cyan
    $OutputBuffer.Add($Footer)

    $FinalPayload = $OutputBuffer -join "`n"

    # Save cleanly to both clipboard and disk log files
    $FinalPayload | Set-Clipboard
    $FinalPayload | Out-File -FilePath $LogPath -Encoding utf8

    Write-Host "[+] PS7 Diagnostic log generated: $LogPath" -ForegroundColor Green
    Write-Host "[+] Diagnostic trace copied directly to clipboard!" -ForegroundColor Green
}
# Integrity-Hash: 37025ed35128abc709cae800d8114f0f5a39ab57990edb913de3ae25afd2dd24
