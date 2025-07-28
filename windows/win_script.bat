@echo off
setlocal enabledelayedexpansion

REM Check system architecture (32-bit or 64-bit)
echo Detecting system architecture...

set "arch=32"
if exist "%ProgramFiles(x86)%" set "arch=64"

REM More precise detection method
for /f "tokens=*" %%a in ('wmic os get osarchitecture /value ^| findstr "="') do (
    set "%%a"
)

if "%osarchitecture%"=="64-bit" set "arch=64"
if "%osarchitecture%"=="32-bit" set "arch=32"

echo Detected system architecture: %arch%-bit

REM Set download URL
if "%arch%"=="64" (
    set "download_url=https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-windows-amd64.exe"
) else (
    set "download_url=https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-windows-386.exe"
)

echo Download URL: %download_url%

REM Download GitLab Runner
set "output_file=gitlab-runner.exe"

echo Downloading GitLab Runner...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%download_url%' -OutFile '%output_file%'"

if not exist "%output_file%" (
    echo ERROR: Download failed!
    pause
    exit /b 1
)

echo Download successful! Saved as: %output_file%

REM Install GitLab Runner with admin privileges
echo Attempting to install GitLab Runner with administrator privileges...

REM Create temporary PowerShell script
set "ps_script=%temp%\install_runner.ps1"
(
    echo $exePath = Join-Path -Path (Get-Location) -ChildPath "gitlab-runner.exe"
    echo $process = Start-Process -FilePath $exePath -ArgumentList "install" -PassThru -Verb RunAs -Wait
    echo exit $process.ExitCode
) > "%ps_script%"

REM Execute PowerShell script
powershell -ExecutionPolicy Bypass -File "%ps_script%"
set "exit_code=%errorlevel%"

REM Cleanup temporary file
del "%ps_script%" >nul 2>&1

if %exit_code% equ 0 (
    echo GitLab Runner installed successfully!
) else (
    echo GitLab Runner installation failed, exit code: %exit_code%
)

REM Completion
echo.
echo Operation completed.
pause
