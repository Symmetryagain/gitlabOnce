@echo off
setlocal enabledelayedexpansion

REM get download path
REM Check if GITLAB_RUNNER_HOME is already set
if defined GITLAB_RUNNER_HOME (
    echo Found GITLAB_RUNNER_HOME environment variable: !GITLAB_RUNNER_HOME!
    if exist "!GITLAB_RUNNER_HOME!\gitlab-runner.exe" (
        echo Using existing GitLab Runner executable
        set "runner_path=!GITLAB_RUNNER_HOME!"
        goto runner_ready
    ) else (
        echo GitLab Runner executable not found in GITLAB_RUNNER_HOME directory
    )
)

REM Get download path from user
:get_path
set /p "runner_path=Enter download path for GitLab Runner (e.g., C:\GitLab-Runner): "
if "!runner_path!"=="" (
    echo Path cannot be empty!
    goto get_path
)

REM Create directory if it doesn't exist
if not exist "!runner_path!" (
    mkdir "!runner_path!" >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Failed to create directory: !runner_path!
        goto get_path
    )
)

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
REM Set environment variables
set "output_file=gitlab-runner.exe"
set "full_path=!runner_path!\!output_file!"

REM Download GitLab Runner if it doesn't exist
if exist "!full_path!" (
    echo Using existing GitLab Runner executable
) else (
    echo Download URL: %download_url%
    echo Downloading GitLab Runner...
    
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%download_url%' -OutFile '!full_path!'"
    
    if not exist "!full_path!" (
        echo ERROR: Download failed!
        pause
        exit /b 1
    )
    echo Download successful! Saved as: !full_path!
)

REM Set environment variables
setx GITLAB_RUNNER_HOME "!runner_path!" >nul
set "GITLAB_RUNNER_HOME=!runner_path!"
echo GITLAB_RUNNER_HOME environment variable set to: !runner_path!

:runner_ready
echo Using GitLab Runner from: !runner_path!

REM Install GitLab Runner with admin privileges
echo Attempting to install GitLab Runner with administrator privileges...

"%full_path%" install

REM Collect registration information
:input_url
set /p "gitlab_url=Enter GitLab URL: "
if "!gitlab_url!"=="" (
    echo URL cannot be empty!
    goto input_url
)

:input_token
set /p "registration_token=Enter registration token (must start with 'glrt-'): "
if "!registration_token!"=="" (
    echo Token cannot be empty!
    goto input_token
)
if not "!registration_token:~0,5!"=="glrt-" (
    echo Token must start with 'glrt-'!
    goto input_token
)

:input_desc
set /p "runner_desc=Enter runner description: "
if "!runner_desc!"=="" (
    echo Description cannot be empty!
    goto input_desc
)

:input_executor
set /p "executor_type=Select executor type (shell/docker): "
if /i "!executor_type!"=="shell" goto register_shell
if /i "!executor_type!"=="docker" goto input_docker_image
echo Invalid executor type. Please enter 'shell' or 'docker'
goto input_executor

:input_docker_image
set /p "docker_image=Enter Docker container name (e.g. alpine:latest): "
if "!docker_image!"=="" (
    echo Container name cannot be empty!
    goto input_docker_image
)

REM Execute registration based on executor type
if /i "!executor_type!"=="shell" (
    echo Registering Shell executor...
    "%full_path%" register ^
      --non-interactive ^
      --url "!gitlab_url!" ^
      --registration-token "!registration_token!" ^
      --description "!runner_desc!" ^
      --executor "!executor_type!"
    
    if !errorlevel! equ 0 (
        echo Successfully registered Shell executor
    ) else (
        echo Registration failed. Exit code: !errorlevel!
    )
    goto end
)

if /i "!executor_type!"=="docker" (
    echo Registering Docker executor...
    "%full_path%" register ^
      --non-interactive ^
      --url "!gitlab_url!" ^
      --registration-token "!registration_token!" ^
      --description "!runner_desc!" ^
      --executor "!executor_type!" ^
      --docker-image "!docker_image!" ^
    
    if !errorlevel! equ 0 (
        echo Successfully registered Docker executor with image: !docker_image!
    ) else (
        echo Registration failed. Exit code: !errorlevel!
    )
    goto end
)

:end
echo Registration process completed
pause

