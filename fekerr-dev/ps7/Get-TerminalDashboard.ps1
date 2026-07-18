param(
    [string]$SlotID = "AUTO",
    [int]$UpdateIntervalSec = 5,
    [switch]$Isolate
)

$LogsDirectory  = "C:\Users\feker\src\fekerr-dev\logs"
$SlotJsoncPath  = "$LogsDirectory\$SlotID.jsonc"
$HelloAgyPath   = "$LogsDirectory\hello.agy"
$HistoryPath    = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

$CmdIndex = 1
if (Test-Path -Path $HistoryPath) {
    try { $CmdIndex = [System.IO.File]::ReadAllLines($HistoryPath).Length + 1 } catch { $CmdIndex = (Get-History).Count + 1 }
} else { $CmdIndex = (Get-History).Count + 1 }

$global:TargetNodePointerIndex = 0

# Track live heartbeats of all active slots from files
function Get-LiveClusterMembers {
    $LiveNodes = @()
    $Files = Get-ChildItem -Path $LogsDirectory -Filter "*.jsonc" -ErrorAction SilentlyContinue
    foreach ($File in $Files) {
        try {
            $Content = Get-Content -Path $File.FullName -Raw -ErrorAction SilentlyContinue
            if ($Content -match '\{.*\}') {
                $Data = ConvertFrom-Json -InputObject $Content -ErrorAction SilentlyContinue
                if ($null -ne $Data -and (-not [string]::IsNullOrEmpty($Data.WindowSlot))) {
                    $NodeName = $Data.WindowSlot.Trim()
                    # Verify file freshness (must have ticked within last 30 seconds)
                    if ($File.LastWriteTime -gt (Get-Date).AddSeconds(-30)) {
                        if ($LiveNodes -notcontains $NodeName) { $LiveNodes += $NodeName }
                    }
                }
            }
        } catch {}
    }
    return ,($LiveNodes | Sort-Object)
}

function Get-MeshTopologyAndToken {
    $ClusterNodes = @()
    $LastTargetedNode = $null
    $LastActionType = "PULSE_INITIAL"
    $LastActionTime = [DateTime]::UtcNow
    
    if (Test-Path -Path $HelloAgyPath) {
        try {
            $Lines = Get-Content -Path $HelloAgyPath -ErrorAction SilentlyContinue
            foreach ($Line in $Lines) {
                if ($Line -match '\{.*\}') {
                    $Obj = ConvertFrom-Json -InputObject $Line -ErrorAction SilentlyContinue
                    if ($null -ne $Obj) {
                        $CleanNode = $Obj.node.Trim()
                        if ($CleanNode -ne $SlotID.Trim() -and $ClusterNodes -notcontains $CleanNode) {
                            $ClusterNodes += $CleanNode
                        }
                        if ($Obj.action -match "PULSE_") {
                            if ($Obj.msg -match 'says hi,\s*(?<target>W[A-F0-9_\s]+),\s*\*poke\*') {
                                $LastTargetedNode = $Matches['target'].Trim()
                                $LastActionTime = [DateTime]::Parse($Obj.timestamp)
                                $LastActionType = $Obj.action
                            }
                            elseif ($Obj.msg -match "says \*ow! ok, fine I'll poke '(?<target>W[A-F0-9_\s]+)' in an hour\*") {
                                $LastTargetedNode = $Matches['target'].Trim()
                                $LastActionTime = [DateTime]::Parse($Obj.timestamp)
                                $LastActionType = $Obj.action
                            }
                        }
                        elseif ($Obj.action -eq "TOKEN_PUSH") {
                            if ($Obj.msg -match "Hey (?<target>W[A-F0-9_\s]+), you hold the token!") {
                                $LastTargetedNode = $Matches['target'].Trim()
                                $LastActionTime = [DateTime]::Parse($Obj.timestamp)
                                $LastActionType = $Obj.action
                            }
                        }
                        elseif ($Obj.action -eq "TOKEN_RECOVERY") {
                            if ($Obj.msg -match "Claiming recovered authority for target (?<target>W[A-F0-9_\s]+)") {
                                $LastTargetedNode = $Matches['target'].Trim()
                                $LastActionTime = [DateTime]::Parse($Obj.timestamp)
                                $LastActionType = $Obj.action
                            }
                        }
                    }
                }
            }
        } catch {}
    }
    return ,($ClusterNodes, $LastTargetedNode, $LastActionTime, $LastActionType)
}

function Show-MtfHeader {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "  MESH TELEMETRY FABRIC (MTF) v1.5.5 | Resilient Token Monitor: ${SlotID}" -ForegroundColor Cyan
    Write-Host "  [Space] Poke/Push | [V] View Members | [H] Help Menu | [Q] Quit" -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Cyan
    
    if (Test-Path -Path $HelloAgyPath) {
        try {
            Get-Content -Path $HelloAgyPath -Tail 4 | ForEach-Object {
                if ($_ -match '\{.*\}') {
                    $Obj = ConvertFrom-Json -InputObject $_ -ErrorAction SilentlyContinue
                    if ($null -ne $Obj) {
                        $Color = if ($Obj.action -eq "TOKEN_RECOVERY") { "Red" } elseif ($Obj.action -eq "TOKEN_PUSH") { "Cyan" } elseif ($Obj.msg -match '\*ow!\*') { "DarkYellow" } elseif ($Obj.action -match "PULSE") { "Magenta" } else { "DarkGreen" }
                        Write-Host "   -> [$($Obj.timestamp)] ($($Obj.node)) [$($Obj.action)]: $($Obj.msg)" -ForegroundColor $Color
                    }
                }
            }
        } catch {}
    }
    
    Write-Host "======================================================================" -ForegroundColor Cyan
    
    $TopologyData = Get-MeshTopologyAndToken
    $Nodes = $TopologyData[0]
    $CurrentTokenHolder = $TopologyData[1]
    $LastActionTime = $TopologyData[2]
    
    $LiveCluster = Get-LiveClusterMembers
    $HasToken = ($null -eq $CurrentTokenHolder -or $CurrentTokenHolder.Trim() -eq $SlotID.Trim())
    
    if ($LiveCluster.Count -gt 0) {
        if ($global:TargetNodePointerIndex -ge $LiveCluster.Count) { $global:TargetNodePointerIndex = 0 }
        
        $StagedList = @()
        for ($i=0; $i -lt $LiveCluster.Count; $i++) {
            if ($LiveCluster[$i] -eq $SlotID.Trim()) { continue }
            if ($i -eq $global:TargetNodePointerIndex) {
                $StagedList += "[$i] $($LiveCluster[$i]) (*)"
            } else {
                $StagedList += "[$i] $($LiveCluster[$i])"
            }
        }
        Write-Host "  [Topology] Online Ring Members: $($StagedList -join ' | ')" -ForegroundColor Gray
        
        if ($HasToken) {
            $NextTarget = $LiveCluster[$global:TargetNodePointerIndex]
            if ($NextTarget -eq $SlotID.Trim() -and $LiveCluster.Count -gt 1) { 
                $NextTarget = $LiveCluster[($global:TargetNodePointerIndex + 1) % $LiveCluster.Count] 
            }
            
            $TimeElapsed = [DateTime]::UtcNow - $LastActionTime
            $TimeRemaining = [TimeSpan]::FromHours(1.0) - $TimeElapsed
            if ($TimeRemaining.TotalSeconds -lt 0) { $TimeRemaining = [TimeSpan]::Zero }
            $MinStr = "{0:mm}m {0:ss}s" -f $TimeRemaining
            
            Write-Host "  [TOKEN STATE] Active Token Held Locally by ${SlotID}" -ForegroundColor Green
            Write-Host "  [Next Up    ] Automated Poke -> ${NextTarget} in $MinStr" -ForegroundColor Yellow
        } else {
            # Is the current token holder dead or real?
            $HolderStatus = if ($LiveCluster -contains $CurrentTokenHolder) { "Online" } else { "GHOST/DEAD (Scrubber Monitoring)" }
            Write-Host "  [TOKEN STATE] Token is Remote -> Held by ${CurrentTokenHolder} [$HolderStatus]" -ForegroundColor DarkGray
            Write-Host "  [Next Up    ] Standing by..." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [Topology] Standalone Mode. Profiling system handles..." -ForegroundColor DarkGray
    }
    Write-Host "======================================================================`n" -ForegroundColor Cyan
}

function Invoke-DirectedMeshPulse {
    param([string]$TriggerType = "MANUAL")
    $TS = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss")
    $LiveCluster = Get-LiveClusterMembers
    
    if ($LiveCluster.Count -le 1) {
        $PulseLine = "{`"timestamp`":`"$TS`",`"node`":`"${SlotID}`",`"action`":`"PULSE_SOLO`",`"msg`":`"${SlotID} says hi, searching for online targets...`"}"
        try { $PulseLine | Out-File -FilePath $HelloAgyPath -Append -Encoding ascii } catch {}
        return
    }
    
    # Track only valid online destinations
    $CleanTargets = @()
    foreach($N in $LiveCluster) { if ($N -ne $SlotID.Trim()) { $CleanTargets += $N } }
    
    if ($global:TargetNodePointerIndex -ge $CleanTargets.Count) { $global:TargetNodePointerIndex = 0 }
    $TargetNode = $CleanTargets[$global:TargetNodePointerIndex]
    $global:TargetNodePointerIndex = ($global:TargetNodePointerIndex + 1) % $CleanTargets.Count
    
    $MsgString = if ($TriggerType -eq "REACT") {
        "${SlotID} says *ow! ok, fine I'll poke '${TargetNode}' in an hour*"
    } else {
        "${SlotID} says hi, ${TargetNode}, *poke*"
    }
    
    $PulseLine = "{`"timestamp`":`"$TS`",`"node`":`"${SlotID}`",`"action`":`"PULSE_${TriggerType}`",`"msg`":`"${MsgString}`"}"
    try { $PulseLine | Out-File -FilePath $HelloAgyPath -Append -Encoding ascii } catch {}
    Show-MtfHeader
}

function Invoke-TokenPushInvite {
    $TS = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss")
    $TopologyData = Get-MeshTopologyAndToken
    $CurrentTokenHolder = $TopologyData[1]
    
    if (-not [string]::IsNullOrEmpty($CurrentTokenHolder)) {
        $PushLine = "{`"timestamp`":`"$TS`",`"node`":`"${SlotID}`",`"action`":`"TOKEN_PUSH`",`"msg`":`"Hey ${CurrentTokenHolder}, you hold the token! ${SlotID} says hi, ${CurrentTokenHolder}, *poke*`"}"
        try { $PushLine | Out-File -FilePath $HelloAgyPath -Append -Encoding ascii } catch {}
    } else {
        Invoke-DirectedMeshPulse -TriggerType "MANUAL"
    }
    Show-MtfHeader
}

$global:MeshIsolateActive = $Isolate.IsPresent
Show-MtfHeader

$LocalLoopCount = 1
$LastHeaderRefresh = [DateTime]::UtcNow

while ($true) {
    try {
        $TopologyData = Get-MeshTopologyAndToken
        $CurrentTokenHolder = $TopologyData[1]
        $LastActionTime = $TopologyData[2]
        $LastActionType = $TopologyData[3]
        
        $LiveCluster = Get-LiveClusterMembers
        $HasToken = ($null -eq $CurrentTokenHolder -or $CurrentTokenHolder.Trim() -eq $SlotID.Trim())

        # --- THE RESILIENT SCRUBBER ENGINE COMPONENT ---
        if (-not $HasToken) {
            $SecsSinceAction = ([DateTime]::UtcNow - $LastActionTime).TotalSeconds
            # If token is held by a non-existent or dead slot for over 15 seconds, initiate scrub sequence
            if (($LiveCluster -notcontains $CurrentTokenHolder) -and ($SecsSinceAction -gt 15)) {
                # Lowest alphabetized active node assumes the duty to prevent split-brain collision
                if ($LiveCluster.Count -gt 0 -and $LiveCluster[0] -eq $SlotID.Trim()) {
                    $TS = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ss")
                    $RecoveryLine = "{`"timestamp`":`"$TS`",`"node`":`"${SlotID}`",`"action`":`"TOKEN_RECOVERY`",`"msg`":`"Scrubber detected dead token holder [${CurrentTokenHolder}]. Claiming recovered authority for target ${SlotID}.`"}"
                    try { $RecoveryLine | Out-File -FilePath $HelloAgyPath -Append -Encoding ascii } catch {}
                    Start-Sleep -Milliseconds 500
                    continue
                }
            }
        }

        # NORMAL OPERATION PROCESSING
        if ($HasToken -and (-not $global:MeshIsolateActive)) {
            $TimeOutExpired = ([DateTime]::UtcNow - $LastActionTime).TotalHours -ge 1.0
            $ReceivedPushInvite = ($LastActionType -eq "TOKEN_PUSH")
            
            if ($TimeOutExpired -or $ReceivedPushInvite) {
                $TriggerLabel = if ($ReceivedPushInvite) { "REACT" } else { "AUTO" }
                Start-Sleep -Milliseconds 750
                Invoke-DirectedMeshPulse -TriggerType $TriggerLabel
            }
        }

        if (([DateTime]::UtcNow - $LastHeaderRefresh).TotalSeconds -ge 1.0) {
            Show-MtfHeader
            $LastHeaderRefresh = [DateTime]::UtcNow
        }

        $TimeStr = [DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')
        $TokenLabel = if ($HasToken) { "TOKEN" } else { "IDLE" }
        $LogLine = "[$TimeStr | PEEK_AUTO_${CmdIndex}_$LocalLoopCount] [INFO] State: $TokenLabel | Resilient Bus"
        Write-Host "`r$LogLine" -NoNewline -ForegroundColor Green
        
        $IsolateString = if ($global:MeshIsolateActive) { "true" } else { "false" }
        $JsoncObject = "{ `"WindowSlot`": `"$SlotID`", `"UtilityVersion`": `"1.5.5`", `"IsolationLockActive`": $IsolateString, `"TelemetryState`": { `"LastTickTimestamp`": `"$TimeStr`", `"CommandPromptIndex`": $CmdIndex } }"
        try { $JsoncObject | Out-File -FilePath $SlotJsoncPath -Encoding ascii -Force } catch {}
        
        $LocalLoopCount++
    } catch { break }

    for ($i = 0; $i -lt ($UpdateIntervalSec * 2); $i++) {
        if ([Console]::KeyAvailable) {
            $KeyInfo = [Console]::ReadKey($true)
            if ($KeyInfo.Key -eq 'Q') { return }
            if ($KeyInfo.Key -eq 'H') { Show-HelpMenu }
            if ($KeyInfo.Key -eq 'V') { Show-ClusterMembers }
            if ($KeyInfo.Key -eq 'Spacebar') {
                if ($HasToken) { Invoke-DirectedMeshPulse -TriggerType "MANUAL" } else { Invoke-TokenPushInvite }
            }
        }
        Start-Sleep -Milliseconds 500
    }
}