<#
.SYNOPSIS
    Host-side environment provisioner for IrisLime engineering sessions.
.DESCRIPTION
    Automates the installation of Windows development tools (Neovim, ripgrep, fd)
    and registers persistent workspace shortcuts and aliases in the active $PROFILE.
.PARAMETER SkipWinget
    If true, bypasses the winget installation steps.
#>
[CmdletBinding()]
param (
    [switch]$SkipWinget
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             IRISLIME COLD BOOT: HOST POWERSHELL 7 PROVISIONER"
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Elevate Execution Policy for the session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# 2. Deploy Winget Prerequisites
if (-not $SkipWinget) {
    Write-Host "[*] Auditing host development utilities (winget)..." -ForegroundColor Yellow
    
    $Apps = @(
        @{ ID = "Neovim.Neovim"; Name = "Neovim" },
        @{ ID = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
        @{ ID = "sharkdp.fd"; Name = "fd" }
    )

    foreach ($App in $Apps) {
        Write-Host "    - Checking: $($App.Name)" -ForegroundColor Gray
        $Check = Get-Command $App.Name -ErrorAction SilentlyContinue
        if (-not $Check) {
            Write-Host "      -> Installing $($App.Name) via Winget..." -ForegroundColor Yellow
            winget install $App.ID --silent --accept-source-agreements --accept-package-agreements | Out-Null
        } else {
            Write-Host "      -> Verified: Already resident." -ForegroundColor Green
        }
    }
}

# 3. Align and Register Environment Profile Shortcuts
Write-Host "[*] Auditing PowerShell profile configuration..." -ForegroundColor Yellow
$ProfilePath = $PROFILE

if (-not (Test-Path $ProfilePath)) {
    Write-Host "    - Profile file missing. Creating a clean profile..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

$ProfileContent = [System.IO.File]::ReadAllText($ProfilePath)

# Standard workspace shortcut payload block to append if missing
$ShortcutsBlock = @(
    "",
    "# ==============================================================================",
    "# FEKERR-DEV WORKSPACE SHORTCUTS",
    "# ==============================================================================",
    "function sign { & `\"C:\Users\feker\src\fekerr-dev\ps7\Protect-FileIntegrity.ps1`\" -Action Sign -Path `$args[0] }",
    "function verify { & `\"C:\Users\feker\src\fekerr-dev\ps7\Protect-FileIntegrity.ps1`\" -Action Verify -Path `$args[0] }",
    "function log-session { & `\"C:\Users\feker\src\fekerr-dev\ps7\Record-Session.ps1`\" -Module `$args[0] -Action `$args[1] }",
    "function p2c { `$input | Out-String | & `\"C:\Users\feker\src\fekerr-dev\ps7\pipe2clip.ps1`\" }",
    "function sync-tars { & `\"C:\Users\feker\src\fekerr-dev\ps7\Backup-AndVerifyTars.ps1`\" }",
    "function vi { & `\"nvim`\" `$args }",
    "function vim { & `\"nvim`\" `$args }"
) -join [System.Environment]::NewLine

if ($ProfileContent -notmatch "FEKERR-DEV WORKSPACE SHORTCUTS") {
    Write-Host "    -> Appending shortcuts to active profile..." -ForegroundColor Green
    Add-Content -Path $ProfilePath -Value $ShortcutsBlock
    # Force reload of profile in the running session
    . $PROFILE
} else {
    Write-Host "    -> Profile is already optimized and aligned." -ForegroundColor Green
}

Write-Host "[+] Host environment provisioning cycle verified complete." -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan

# Integrity-Hash: e53007bbefca0ee9d9f626eec22bb6dabe8ef04966b469db7065553e0dfd4390