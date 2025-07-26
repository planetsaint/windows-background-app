@echo off
title MyBackgroundApp
echo Starting MyBackgroundApp...
echo.

REM Create temp directory for logs if it doesn't exist
if not exist "C:\temp" mkdir "C:\temp"

REM Run the application
MyBackgroundApp.exe

echo.
echo Application stopped.
pause
