@echo off
echo Uninstalling MyBackgroundService...

REM Stop the service
sc stop MyBackgroundService
echo Waiting for service to stop...
timeout /t 5 /nobreak >nul

REM Delete the service
sc delete MyBackgroundService
if %ERRORLEVEL% neq 0 (
    echo Failed to delete service
    pause
    exit /b 1
)

echo Service uninstalled successfully!
pause
