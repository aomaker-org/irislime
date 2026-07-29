#!/usr/bin/env bash
# PATH: pr-36/check_temp.sh
# PURPOSE: Query non-elevated Windows host thermal zone from WSL.

powershell.exe -NoProfile -Command '
Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation 2>$null | ForEach-Object {
    $c = [math]::Round($_.Temperature - 273.15, 1)
    [PSCustomObject]@{
        Zone    = $_.Name
        Temp_C  = "$c °C"
        Temp_F  = "$([math]::Round(($c * 9/5) + 32, 1)) °F"
        Status  = if ($c -gt 85) { "HOT" } elseif ($c -gt 70) { "WARM" } else { "COOL" }
    }
} | Format-Table -AutoSize
'
