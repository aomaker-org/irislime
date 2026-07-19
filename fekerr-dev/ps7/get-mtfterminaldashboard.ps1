# get-mtfterminaldashboard.ps1 - Interop forwarding script to Get-TerminalDashboard.ps1
$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Get-TerminalDashboard.ps1"
if (Test-Path -Path $ScriptPath) {
    & $ScriptPath @args
} else {
    Write-Error "[-] Target dashboard script not found at $ScriptPath"
}
