<#
.SYNOPSIS
    # !/usr/bin/env pwsh
    # Execution: powershell -File ps7\Protect-FileIntegrity.ps1 -Path <file>
    # Note: Intentionally stored without execute permissions (no chmod +x).
    # Requires explicit interpreter execution invocation to guarantee safety.
.DESCRIPTION
    Calculates a strict SHA-256 cryptographic checksum of a specified flat ASCII 
    session file and appends it to the document footer as an integrity guard.
.PARADIGMS
    - Uses native .NET Security Cryptography streams for thread isolation.
    - Python translation equivalent maps to the 'hashlib.sha256()' constructor loop.
======================================================================
INTEGRITY MODULE REGISTRATION
======================================================================
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path
)

if (Test-Path -Path $Path -PathType Leaf) {
    try {
        # 1. Open a clean byte stream to evaluate the raw file contents
        $FileStream = [System.IO.File]::OpenRead($Path)
        $ShaEngine  = [System.Security.Cryptography.SHA256]::Create()
        
        # Calculate the raw hash bytes
        $HashBytes  = $ShaEngine.ComputeHash($FileStream)
        $FileStream.Close()
        $FileStream.Dispose()

        # 2. Convert byte array to a tight, standard flat lowercase hexadecimal string
        $HexBuilder = [System.Text.StringBuilder]::new()
        foreach ($Byte in $HashBytes) {
            [void]$HexBuilder.Append($Byte.ToString("x2"))
        }
        $HashString = $HexBuilder.ToString()

        # 3. Format structural ASCII verification block to append as a footer
        $FooterBlock = "`n--------------------------------------------------------------------------------`n" +
                       "# Integrity-Hash: $HashString`n" +
                       "================================================================================"
        
        $FooterBlock | Out-File -FilePath $Path -Encoding ascii -Append
        Write-Host "[+] Integrity Signature Appended: $HashString" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to process cryptographic payload block: $_"
    }
} else {
    Write-Error "Target file payload path not found: $Path"
}
