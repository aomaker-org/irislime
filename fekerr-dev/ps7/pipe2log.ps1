<#
.SYNOPSIS
    Pipes pipeline output to a log file while prepending high-resolution 
    wall-clock, elapsed-cumulative, and step-delta timestamps.
.DESCRIPTION
    A lightweight, performance-optimized filter designed to handle high-throughput 
    pipeline streams. Measures execution times down to the millisecond.
.PARAMETER InputObject
    The incoming pipeline object to be logged.
.PARAMETER FilePath
    The target destination log file. Defaults to a timestamped file in the current directory.
.PARAMETER PassThru
    Passes the raw incoming pipeline objects down the line (acts like 'tee').
.EXAMPLE
    Get-Content huge_file.txt | .\pipe2log.ps1 -FilePath .\run.log -PassThru
================================================================================
#>
[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true)]
    $InputObject,

    [string]$FilePath = ".\pipeline_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [switch]$PassThru
)

begin {
    # Initialize the high-resolution hardware stopwatch
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $LastTicks = 0L
    
    # Safe .NET-based Path Resolution (Handles non-existent files flawlessly)
    $AbsoluteFilePath = [System.IO.Path]::GetFullPath($FilePath)
    $AbsoluteDir = Split-Path -Path $AbsoluteFilePath -Parent

    if ($AbsoluteDir -and -not (Test-Path $AbsoluteDir)) {
        New-Item -ItemType Directory -Path $AbsoluteDir -Force | Out-Null
    }

    # Write clean initialization block header to disk
    "================================================================================" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    " PIPELINE LOG INITIALIZED AT: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    "================================================================================" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
}

process {
    # Fetch high-res ticks directly from the CPU instruction registers
    $CurrentTicks = $Stopwatch.ElapsedTicks
    $TotalElapsed = $Stopwatch.Elapsed
    
    # Calculate delta time since the last printed line
    $DeltaTicks = $CurrentTicks - $LastTicks
    $DeltaSpan = [TimeSpan]::new($DeltaTicks)
    $LastTicks = $CurrentTicks

    # Format our timing layers
    $WallClock = [DateTime]::Now.ToString("HH:mm:ss.fff")
    $ElapsedStr = "{0:hh\:mm\:ss\.fff}" -f $TotalElapsed
    $DeltaStr = "{0:s\.fff}s" -f $DeltaSpan

    # Convert the pipeline object to a detailed string representation (log extensively)
    $ObjectString = $InputObject
    if ($null -ne $InputObject -and $InputObject.GetType().Name -ne "String") {
        $ObjectString = $InputObject | Out-String
        $ObjectString = $ObjectString.TrimEnd([System.Environment]::NewLine)
    }

    # Construct the ultimate timestamped prefix
    # Format: [WallClock] [CumulativeElapsed] [+StepDelta] Text
    $Lines = $ObjectString -split "\r?\n"
    foreach ($Line in $Lines) {
        $FormattedLine = "[$WallClock] [+$ElapsedStr] [+$DeltaStr] $Line"
        # Write directly to disk
        $FormattedLine | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    }

    # If PassThru is toggled, send the RAW object down the pipeline to preserve pipe chain integrity
    if ($PassThru) {
        $InputObject
    }
}

end {
    $Stopwatch.Stop()
    $AbsoluteFilePath = [System.IO.Path]::GetFullPath($FilePath)
    "================================================================================" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    " PIPELINE TERMINATED SUCCESSFULLY" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    " TOTAL RUNTIME TIME: $($Stopwatch.Elapsed)" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
    "================================================================================" | Out-File -FilePath $AbsoluteFilePath -Encoding utf8 -Append
}

# Integrity-Hash: 74eb95bd18be968c60d9fbc11e11115bf74944b3025a6a5999f45eeb3bb874b2