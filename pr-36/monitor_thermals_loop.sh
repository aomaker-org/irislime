#!/usr/bin/env bash
# PATH: pr-36/monitor_thermals_loop.sh
# PURPOSE: Continuous non-elevated thermal monitoring loop (1-minute interval).

INTERVAL=60

echo "================================================================="
echo "[ThermalMonitor] Starting 60s Host CPU Thermal Monitor Loop"
echo "Press [CTRL+C] to stop."
echo "================================================================="

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "--- Sample at ${TIMESTAMP} ---"
    
    powershell.exe -NoProfile -Command '
    Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation 2>$null | ForEach-Object {
        $c = [math]::Round($_.Temperature - 273.15, 1)
        [PSCustomObject]@{
            Zone    = $_.Name
            Temp_C  = "$c C"
            Temp_F  = "$([math]::Round(($c * 9/5) + 32, 1)) F"
            Status  = if ($c -gt 85) { "HOT" } elseif ($c -gt 70) { "WARM" } else { "COOL" }
        }
    } | Format-Table -AutoSize
    ' | tr -d '\r'
    
    sleep "${INTERVAL}"
done
