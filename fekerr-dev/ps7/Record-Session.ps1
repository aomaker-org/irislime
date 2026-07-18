function Invoke-TimedLogged {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    process {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Ensure target directory exists cleanly
        $logDir = Split-Path -Path $LogPath
        if ($logDir -and !(Test-Path -Path $logDir -PathType Container)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # Structure pure flat ASCII headers
        "======================================================================" | Out-File -FilePath $LogPath -Encoding ascii -Append
        "SESSION RECORD START: $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss UTC'))" | Out-File -FilePath $LogPath -Encoding ascii -Append
        "======================================================================" | Out-File -FilePath $LogPath -Encoding ascii -Append

        try {
            # Execute script block and redirect all 6 streams (*>&1) into the pipeline
            & {
                $VerbosePreference = 'Continue'
                $WarningPreference = 'Continue'
                $DebugPreference   = 'Continue'
                $InformationPreference = 'Continue'

                & $ScriptBlock
            } *>&1 | ForEach-Object {
                # Convert stream object to flat string
                $line = $_.ToString()
                
                # Render to active console host for user/agy real-time visibility
                Write-Host $_

                # Force strip to plain flat ASCII bytes to guarantee pipeline parsing
                $asciiBytes = [System.Text.Encoding]::ASCII.GetBytes($line)
                $asciiLine  = [System.Text.Encoding]::ASCII.GetString($asciiBytes)
                $asciiLine | Out-File -FilePath $LogPath -Encoding ascii -Append
            }
        }
        catch {
            "CRITICAL SESSION WRAPPER ERROR: $_" | Out-File -FilePath $LogPath -Encoding ascii -Append
            Write-Error $_
        }
        finally {
            $stopwatch.Stop()
            "----------------------------------------------------------------------" | Out-File -FilePath $LogPath -Encoding ascii -Append
            "EXECUTION DURATION: $($stopwatch.Elapsed.TotalSeconds) seconds" | Out-File -FilePath $LogPath -Encoding ascii -Append
            "======================================================================" | Out-File -FilePath $LogPath -Encoding ascii -Append
        }
    }
}
