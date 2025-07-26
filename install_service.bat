@echo off
echo Installing MyBackgroundService with Plugin System...

REM Create temp directory for logs if it doesn't exist
if not exist "C:\temp" mkdir "C:\temp"

REM Install the service
sc create MyBackgroundService binPath= "%~dp0MyBackgroundService.exe" start= auto
if %ERRORLEVEL% neq 0 (
    echo Failed to create service
    pause
    exit /b 1
)

REM Start the service
sc start MyBackgroundService
if %ERRORLEVEL% neq 0 (
    echo Failed to start service
    pause
    exit /b 1
)

echo Service installed and started successfully!
echo.
echo Log files:
echo - Service: C:\temp\MyService.log
echo - Sample Plugin: C:\temp\SamplePlugin.log
echo.
echo To add more plugins, place DLL files in the "plugins" folder
pause
