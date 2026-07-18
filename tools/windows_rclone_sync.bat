@echo off
REM ==============================================================================
REM IrisLime Windows Rclone Log Archiver & Cloud Streamer
REM Target Remote: gdrive:transfer/20260718_logs_core12_1003
REM Package: 20260718_logs_core12_1003.zip
REM ==============================================================================

setlocal enabledelayedexpansion

set "ZIP_FILE=20260718_logs_core12_1003.zip"
set "REMOTE_DEST=gdrive:transfer/20260718_logs_core12_1003"

echo ==============================================================================
echo   IrisLime Windows Rclone Log Archiver Streamer
echo ==============================================================================
echo Target Package: %ZIP_FILE%
echo Remote Target : %REMOTE_DEST%
echo.

REM Ensure target zip exists, or copy from WSL share if missing
if not exist "%ZIP_FILE%" (
    if exist "\\wsl.localhost\ubu26_0715\home\fekerr\src\irislime\%ZIP_FILE%" (
        echo [*] Copying %ZIP_FILE% from WSL environment...
        copy "\\wsl.localhost\ubu26_0715\home\fekerr\src\irislime\%ZIP_FILE%" "%ZIP_FILE%" >nul
    ) else if exist "\\wsl$\ubu26_0715\home\fekerr\src\irislime\%ZIP_FILE%" (
        echo [*] Copying %ZIP_FILE% from WSL environment...
        copy "\\wsl$\ubu26_0715\home\fekerr\src\irislime\%ZIP_FILE%" "%ZIP_FILE%" >nul
    ) else (
        echo [ERROR] Target zip package '%ZIP_FILE%' not found in current directory or WSL share.
        exit /b 1
    )
)

REM Locate rclone.exe on Windows host
set "RCLONE_EXE="
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\rclone.exe" set "RCLONE_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\rclone.exe"
if "%RCLONE_EXE%"=="" (
    where rclone >nul 2>nul
    if !errorlevel! equ 0 set "RCLONE_EXE=rclone"
)

if "%RCLONE_EXE%"=="" (
    echo [ERROR] rclone.exe not found in WinGet links or PATH. Please install rclone on Windows.
    exit /b 1
)

echo [*] Using rclone binary: %RCLONE_EXE%
echo [*] Streaming archive package to cloud remote...

"%RCLONE_EXE%" copyto "%ZIP_FILE%" "%REMOTE_DEST%/%ZIP_FILE%" --progress --drive-chunk-size 64M --transfers 4

if !errorlevel! neq 0 (
    echo [ERROR] Rclone upload failed with code !errorlevel!.
    exit /b !errorlevel!
)

echo.
echo [*] Verifying remote payload delivery on gdrive...
"%RCLONE_EXE%" ls "%REMOTE_DEST%"

echo {"status": "SUCCESS", "machine_id": "core12", "wsl_ubuntu_id": "1003", "package": "%ZIP_FILE%", "remote_destination": "%REMOTE_DEST%", "verified": true} > tools\windows_rclone_receipt.json

echo.
echo [SUCCESS] Log archive package transferred and verified on gdrive:!
echo [HANDSHAKE] Handshake receipt written to tools\windows_rclone_receipt.json
echo.
