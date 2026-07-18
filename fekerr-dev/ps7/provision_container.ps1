<#
.SYNOPSIS
    Deploys a clean, isolated Ubuntu 26.04 WSL2 environment from a base rootfs.
.DESCRIPTION
    Imports the tarball, bootstraps essential OS utilities (sudo, systemd, dbus), 
    configures isolation user fekerr (UID/GID 1005), and sets up dynamic sudo 
    privileges and default shell startup profiles.
.PARAMETER InstanceName
    The targeted register name for the new WSL2 container.
.PARAMETER TarPath
    The local path to your base Ubuntu 26.04 rootfs .tar or .tar.gz file.
.PARAMETER InstallDir
    The path where the virtual disk file (.vhdx) will be anchored.
.PARAMETER EnablePasswordlessSudo
    Boolean switch to toggle sudo password requirements on/off.
.PARAMETER Force
    Unregisters and deletes any existing WSL distro sharing the same target name.
.NOTES
    File Name      : provision_container.ps1
    Version        : 1.5.1
    Created        : 260715_2005 (July 15, 2026)
    Target Shell   : PowerShell 7.4+ (Cross-Platform)
================================================================================
#>
[CmdletBinding()]
param (
    [string]$InstanceName = "Ubuntu-26.04-Sandbox",
    [string]$TarPath = "C:\wsl_backups\ubuntu-26.04-rootfs.tar.gz",
    [string]$InstallDir = "C:\WSL\instances\Ubuntu-26.04-Sandbox",
    [bool]$EnablePasswordlessSudo = $true,
    [switch]$Force
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             WSL2 CONTAINER PROVISIONER: INITIATING COLD BOOT"
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Directory Scaffolding & Validation Checks
if (-not (Test-Path $TarPath)) {
    throw "[!] Error: Source tarball not found at path: $TarPath"
}

# 2. Handle pre-existing distribution conflicts
$ExistingDistros = (wsl.exe --list --quiet) -split "`r`n" -split "`n" | Where-Object { $_.Trim() -eq $InstanceName }
if ($ExistingDistros) {
    if ($Force) {
        Write-Host "[!] Warning: Distro '$InstanceName' already exists. -Force active, unregistering..." -ForegroundColor Yellow
        wsl.exe --unregister $InstanceName
        Start-Sleep -Seconds 2
    } else {
        throw "[!] Error: A WSL distribution named '$InstanceName' already exists. Use the -Force switch to overwrite it."
    }
}

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 3. Import base WSL2 system
Write-Host "[*] Importing base OS tarball to register target '$InstanceName'..." -ForegroundColor Yellow
wsl.exe --import $InstanceName $InstallDir $TarPath --version 2

# Verify import integrity before moving forward
if ($LASTEXITCODE -ne 0) {
    throw "[!] Error: WSL import failed. Aborting provisioning sequence to prevent state contamination."
}

# 4. Inject User 1005 and Sudo Rule Configuration
Write-Host "[*] Configuring system users and bootstrapping OS packages..." -ForegroundColor Yellow

$SudoRule = if ($EnablePasswordlessSudo) {
    "fekerr ALL=(ALL) NOPASSWD:ALL"
} else {
    "fekerr ALL=(ALL) ALL"
}

# Construct setup payload block to run natively as root inside the imported instance
$InitPayload = @"
set -eu
export DEBIAN_FRONTEND=noninteractive

# Ensure package repositories are updated and install vital base utilities and D-Bus sockets
apt-get update
apt-get install -y --no-install-recommends sudo systemd systemd-sysv ca-certificates dbus dbus-user-session

# Ensure target group 'sudo' exists
groupadd -f sudo

# Create user private group 'fekerr' with GID 1005
if ! getent group fekerr >/dev/null 2>&1; then
    groupadd -g 1005 fekerr
fi

# Safely create the fekerr user with UID 1005, primary group fekerr (1005), and secondary group sudo
if ! id "fekerr" >/dev/null 2>&1; then
    useradd -u 1005 -g 1005 -G sudo -m -s /bin/bash fekerr
fi

echo 'fekerr:fekerr1005!' | chpasswd

# Ensure the /etc/sudoers.d folder exists
mkdir -p /etc/sudoers.d
echo '$SudoRule' > /etc/sudoers.d/99-fekerr-dev
chmod 0440 /etc/sudoers.d/99-fekerr-dev

# Configure SSH scaffolds
mkdir -p /home/fekerr/.ssh
chmod 0700 /home/fekerr/.ssh
touch /home/fekerr/.ssh/authorized_keys
chmod 0600 /home/fekerr/.ssh/authorized_keys
chown -R fekerr:fekerr /home/fekerr

# Register default WSL user boot settings
cat << 'CONF' > /etc/wsl.conf
[user]
default=fekerr

[boot]
systemd=true
CONF
"@

# Clean the string of any BOM and force pure Linux LF line endings
$LinuxPayload = $InitPayload.Trim([char]0xFEFF).Replace("`r`n", "`n").Replace("`r", "`n")

# Encode the payload to Base64 to bypass the PS7 pipeline re-encoding trap entirely
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($LinuxPayload)
$Base64Payload = [Convert]::ToBase64String($Bytes)

# Feed the Base64 stream cleanly through bash
wsl.exe -d $InstanceName -u root bash -c "echo '$Base64Payload' | base64 -d | bash"

Write-Host "[*] Registering local SSH key profiles..." -ForegroundColor Yellow
$WindowsSshKey = "$env:USERPROFILE\.ssh\id_rsa.pub"
if (Test-Path $WindowsSshKey) {
    $KeyContent = (Get-Content $WindowsSshKey -Raw).Trim()
    # Base64 encode the SSH key payload for clean transport
    $Base64Key = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($KeyContent))
    wsl.exe -d $InstanceName -u fekerr bash -c "echo '$Base64Key' | base64 -d >> ~/.ssh/authorized_keys"
    Write-Host "[+] Public host keys injected into guest sandbox." -ForegroundColor Green
}

Write-Host "[+] WSL2 container '$InstanceName' successfully established and provisioned." -ForegroundColor Green
Write-Host "    Launch via: wsl -d $InstanceName"
Write-Host "================================================================================" -ForegroundColor Cyan
# end of file: provision_container.ps1

# Integrity-Hash: 7e3a3dd40630a8a87f9a990611450721ca485b2720a86aa127353cba1bb3565c