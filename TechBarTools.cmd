@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  TECH BAR TOOLS
::  Main launcher script. Place this file at the ROOT of the
::  USB drive. Drive letter is detected automatically.
:: ============================================================

:: Capture the drive/path this script was launched from
set "ROOT=%~dp0"

::  Set your organization's domain below before use
set "DOMAIN=YOUR_DOMAIN"

:MENU
cls
echo.
echo  =============================================
echo        T E C H  B A R  T O O L S
echo  =============================================
echo.
echo   User Management
echo   ---------------
echo   [1]  Add Local Administrator
echo   [2]  Delete Local Administrator
echo   [3]  Remove Hello PIN (English)
echo.
echo   Device Management
echo   -----------------
echo   [4]  Get Hardware ID (Autopilot HWID + Group Tag)
echo   [5]  Clear Completed CSV Imports
echo   [6]  Check Driver Versions
echo   [7]  Return Device to OOBE (Preserve Hostname)
echo.
echo   Application Management
echo   ----------------------
echo   [8]  Remove Application
echo.
:: -------------------------------------------------------
::  TO ADD A NEW MENU ITEM:
::    1. Add a new echo line above with a number and label
::       grouped under a relevant section heading.
::    2. Scroll down to the "DISPATCH" section and copy
::       one of the existing "if" blocks, then update the
::       number and call the matching :SUB_* label below.
::    3. Write the new subscript under a clearly named
::       :SUB_YourScriptName label at the bottom of this
::       file, ending with "goto MENU" or "exit /b".
:: -------------------------------------------------------
echo   =============================================
echo   [0]  Exit
echo   =============================================
echo.
set /p "choice=  Enter selection: "


:: ============================================================
::  DISPATCH  –  Route the user's choice to a subscript
:: ============================================================

if "%choice%"=="0" goto EXIT
if "%choice%"=="1" goto SUB_AddLocalAdmin
if "%choice%"=="2" goto SUB_DeleteLocalAdmin
if "%choice%"=="3" goto SUB_RemoveHelloPIN
if "%choice%"=="4" goto SUB_GetHWID
if "%choice%"=="5" goto SUB_ClearCompleted
if "%choice%"=="6" goto SUB_DriverVersion
if "%choice%"=="7" goto SUB_ReturnToOOBE
if "%choice%"=="8" goto SUB_RemoveApplication

:: Invalid input handler
echo.
echo   [!] Invalid selection. Please try again.
timeout /t 2 /nobreak >nul
goto MENU


:: ============================================================
::  EXIT
:: ============================================================
:EXIT
cls
echo.
echo   Goodbye.
echo.
timeout /t 1 /nobreak >nul
exit /b


:: ############################################################
:: #                                                          #
:: #   S U B S C R I P T S                                   #
:: #                                                          #
:: #   Each subscript begins with :SUB_<Name> and should     #
:: #   end with "pause" (so the user can read output)        #
:: #   followed by "goto MENU" to return to the menu.        #
:: #                                                          #
:: ############################################################


:: ============================================================
::  [1]  ADD LOCAL ADMINISTRATOR
:: ============================================================
:SUB_AddLocalAdmin
cls
echo.
echo  =============================================
echo       ADD LOCAL ADMINISTRATOR
echo  =============================================
echo.

set /p "username=  Enter the user's email address to add as administrator: "

echo.
net localgroup Administrators %DOMAIN%\%username% /add

echo.
echo  --- Current Administrators ---
net localgroup Administrators

echo.
pause
goto MENU


:: ============================================================
::  [2]  DELETE LOCAL ADMINISTRATOR
:: ============================================================
:SUB_DeleteLocalAdmin
cls
echo.
echo  =============================================
echo       DELETE LOCAL ADMINISTRATOR
echo  =============================================
echo.

echo  --- Current Administrators ---
net localgroup Administrators

echo.
set /p "username=  Enter the user's email address to remove as administrator: "

echo.
net localgroup Administrators %DOMAIN%\%username% /delete

echo.
echo  --- Updated Administrators ---
net localgroup Administrators

echo.
pause
goto MENU


:: ============================================================
::  [3]  REMOVE HELLO PIN  (English)
::
::  Takes ownership of the NGC folder, grants Administrators
::  full control, then deletes the folder contents to clear
::  the Windows Hello for Business PIN.
::
::  The NGC folder itself is preserved — only its contents
::  are removed.
::
::  IMPORTANT: Run this script as Administrator.
:: ============================================================
:SUB_RemoveHelloPIN
cls
echo.
echo  =============================================
echo       REMOVE HELLO PIN  (English)
echo  =============================================
echo.

set "NGC_DIR=%windir%\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"

:: --- Step 1: Take ownership of the NGC folder ---
echo  Step 1 of 3: Taking ownership of NGC folder...
echo.
takeown /f "%NGC_DIR%" /r /d y
echo.

:: --- Check for failure ---
if errorlevel 1 (
    echo  [ERROR] takeown reported a failure. Review output above.
    echo          Ownership may be partial. Proceed with caution.
    echo.
    pause
    goto MENU
)
echo  [OK] Ownership step completed successfully.
echo.

:: --- Step 2: Grant Administrators full control ---
echo  Step 2 of 3: Granting Administrators full control...
echo.
icacls "%NGC_DIR%" /grant administrators:F /t
echo.

if errorlevel 1 (
    echo  [ERROR] icacls reported a failure. Review output above.
    echo.
    pause
    goto MENU
)
echo  [OK] Permissions granted successfully.
echo.

:: --- Step 3: Delete contents of NGC folder (not the folder itself) ---
echo  Step 3 of 3: Deleting contents of NGC folder...
echo.
del /f /s /q "%NGC_DIR%\*" >nul 2>&1
for /d %%D in ("%NGC_DIR%\*") do rd /s /q "%%D" >nul 2>&1
echo.

:: --- Confirm NGC folder is now empty ---
echo  Verifying NGC folder is empty...
dir "%NGC_DIR%" /a | findstr /v "Volume\|File(s)\|Dir(s)\| \.\| \.\." >nul 2>&1
if errorlevel 1 (
    echo  [OK] NGC folder is empty.
) else (
    echo  [WARNING] NGC folder may still contain items. Verify manually:
    echo            %NGC_DIR%
)

echo.
pause
goto MENU


:: ============================================================
::  [4]  GET HARDWARE ID  (Autopilot HWID + Group Tag)
::
::  Requires:  Scripts\Custom-Autopilot_HWID_GroupTags.ps1
::             placed in the Scripts\ folder on this USB drive.
::
::  Output:    A CSV file saved to the ROOT of this USB drive,
::             named after the device serial number.
::             e.g.  D:\ABC1234567.csv
::
::  NOTE:  PowerShell execution is temporarily set to Bypass
::         for this process only. It does NOT change the
::         machine's permanent execution policy.
:: ============================================================
:SUB_GetHWID
cls
echo.
echo  =============================================
echo       GET HARDWARE ID  (Autopilot)
echo  =============================================
echo.

:: --- Resolve paths relative to this script's drive/folder ---
set "PS_SCRIPT=%ROOT%Scripts\Custom-Autopilot_HWID_GroupTags.ps1"

:: --- Verify the PS1 file actually exists before proceeding ---
if not exist "%PS_SCRIPT%" (
    echo  [ERROR] Script not found:
    echo          %PS_SCRIPT%
    echo.
    echo  Make sure Custom-Autopilot_HWID_GroupTags.ps1 is in
    echo  the Scripts\ folder on this USB drive.
    echo.
    pause
    goto MENU
)

:: --- Grab serial number to use as the output CSV filename ---
for /f "tokens=2 delims==" %%a in ('wmic bios get serialnumber /format:value') do set "SERIAL=%%a"

:: Strip any stray whitespace from serial number
set "SERIAL=%SERIAL: =%"

:: Output CSV goes to the ROOT of the USB drive, named by serial
set "OUTPUT_CSV=%ROOT%%SERIAL%.csv"

echo  Device Serial : %SERIAL%
echo  Output CSV    : %OUTPUT_CSV%
echo.
echo  A Group Tag selection window will appear shortly...
echo.

:: --- Launch PS1 with execution policy bypassed for this call only ---
PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -OutputFile "%OUTPUT_CSV%"

echo.
echo  Done. CSV saved to: %OUTPUT_CSV%
echo.
pause
goto MENU


:: ============================================================
::  [5]  CLEAR COMPLETED CSV IMPORTS
::
::  Moves all .csv files from the USB root into a
::  "Completed Imports" subfolder, then confirms the root
::  is clear so it is ready for the next HWID capture run.
:: ============================================================
:SUB_ClearCompleted
cls
echo.
echo  =============================================
echo       CLEAR COMPLETED CSV IMPORTS
echo  =============================================
echo.

set "COMPLETED_DIR=%ROOT%Completed Imports"

:: --- Create destination folder if it does not yet exist ---
if not exist "%COMPLETED_DIR%" (
    mkdir "%COMPLETED_DIR%"
    echo  Created folder: %COMPLETED_DIR%
    echo.
)

:: --- Check whether there is anything to move ---
set "FOUND_CSV=0"
for %%F in ("%ROOT%*.csv") do set "FOUND_CSV=1"

if "%FOUND_CSV%"=="0" (
    echo  No .csv files found in the USB root. Nothing to move.
    echo.
    pause
    goto MENU
)

:: --- Move all CSVs and report results ---
echo  Moving files...
echo.
move "%ROOT%*.csv" "%COMPLETED_DIR%\"
echo.

:: --- Confirm the root is now clear ---
echo  Verifying USB root is clear of .csv files:
dir "%ROOT%*.csv" 2>nul | findstr /i ".csv" >nul
if errorlevel 1 (
    echo  [OK] No .csv files remain in the USB root.
) else (
    echo  [WARNING] Some .csv files could not be moved. Check for open files.
)

echo.
pause
goto MENU


:: ============================================================
::  [6]  CHECK DRIVER VERSIONS
::
::  Requires the following PS1 scripts in Scripts\ folder:
::    Scripts\1-DriverVersion.ps1  (Before Fresh Start)
::    Scripts\2-DriverVersion.ps1  (After Fresh Start, Before Updates)
::    Scripts\3-DriverVersion.ps1  (After Fresh Start, After Updates)
::    Scripts\4-DriverVersion.ps1  (After AutoPilot)
::
::  NOTE:  PowerShell execution is temporarily set to Bypass
::         for this process only.
:: ============================================================
:SUB_DriverVersion
cls
echo.
echo  =============================================
echo       CHECK DRIVER VERSIONS
echo  =============================================
echo.
echo   When would you like to check drivers?
echo.
echo   [1]  Before Fresh Start
echo   [2]  After Fresh Start, Before Updates
echo   [3]  After Fresh Start, After Updates
echo   [4]  After AutoPilot
echo.
echo   [0]  Back to Main Menu
echo.
set /p "dvchoice=  Enter selection: "

if "%dvchoice%"=="0" goto MENU
if "%dvchoice%"=="1" set "DV_SCRIPT=%ROOT%Scripts\1-DriverVersion.ps1"
if "%dvchoice%"=="2" set "DV_SCRIPT=%ROOT%Scripts\2-DriverVersion.ps1"
if "%dvchoice%"=="3" set "DV_SCRIPT=%ROOT%Scripts\3-DriverVersion.ps1"
if "%dvchoice%"=="4" set "DV_SCRIPT=%ROOT%Scripts\4-DriverVersion.ps1"

if not defined DV_SCRIPT (
    echo.
    echo  [!] Invalid selection. Please try again.
    timeout /t 2 /nobreak >nul
    goto SUB_DriverVersion
)

:: --- Verify the PS1 file actually exists before proceeding ---
if not exist "%DV_SCRIPT%" (
    echo.
    echo  [ERROR] Script not found:
    echo          %DV_SCRIPT%
    echo.
    echo  Make sure the DriverVersion PS1 scripts are in
    echo  the Scripts\ folder on this USB drive.
    echo.
    set "DV_SCRIPT="
    pause
    goto MENU
)

echo.
echo  Running: %DV_SCRIPT%
echo.
PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%DV_SCRIPT%"

set "DV_SCRIPT="
echo.
pause
goto MENU


:: ============================================================
::  [7]  RETURN DEVICE TO OOBE  (Preserve Hostname)
::
::  Runs Sysprep /oobe /reboot to return a pre-provisioned
::  device to the Out-of-Box Experience screen.
::
::  HOSTNAME PRESERVATION:
::  By default, Sysprep resets the computer name to a random
::  DESKTOP-XXXXXXX value. This subscript captures the current
::  hostname first and writes a minimal unattend.xml that pins
::  the computer name, so it survives the Sysprep cycle.
::
::  The temporary unattend.xml is written to the Sysprep
::  folder and cleaned up automatically after use.
::
::  IMPORTANT: Run this script as Administrator.
:: ============================================================
:SUB_ReturnToOOBE
cls
echo.
echo  =============================================
echo       RETURN DEVICE TO OOBE
echo  =============================================
echo.

:: --- Capture current hostname before Sysprep wipes it ---
for /f "tokens=2 delims==" %%H in ('wmic computersystem get name /format:value') do set "CURRENT_HOSTNAME=%%H"
set "CURRENT_HOSTNAME=%CURRENT_HOSTNAME: =%"

echo  Current hostname : %CURRENT_HOSTNAME%
echo  This name will be preserved through the OOBE cycle.
echo.

:: --- Rotate any existing Sysprep log to avoid conflicts ---
set "SYSPREP_DIR=%WINDIR%\System32\Sysprep"
set "LOGFILE=%SYSPREP_DIR%\Panther\setupact.log"

if exist "%LOGFILE%" (
    for /f %%T in ('wmic os get LocalDateTime ^| find "."') do set "LDT=%%T"
    setlocal enabledelayedexpansion
    set "TIMESTAMP=!LDT:~0,4!-!LDT:~4,2!-!LDT:~6,2!-!LDT:~8,2!!LDT:~10,2!"
    ren "%LOGFILE%" "setupact_!TIMESTAMP!.log"
    echo  Rotated existing setupact.log  ^(setupact_!TIMESTAMP!.log^)
    endlocal
) else (
    echo  No existing setupact.log found. Continuing...
)
echo.

:: --- Abort if Sysprep is already running ---
tasklist | find /i "sysprep.exe" >nul
if not errorlevel 1 (
    echo  [ERROR] Sysprep is already running. Exiting.
    echo.
    pause
    goto MENU
)

:: --- Write a minimal unattend.xml that locks in the hostname ---
set "UNATTEND=%SYSPREP_DIR%\TechBar-unattend.xml"

(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo   ^<settings pass="specialize"^>
echo     ^<component name="Microsoft-Windows-Shell-Setup"
echo                processorArchitecture="amd64"
echo                publicKeyToken="31bf3856ad364e35"
echo                language="neutral"
echo                versionScope="nonSxS"
echo                xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
echo       ^<ComputerName^>%CURRENT_HOSTNAME%^</ComputerName^>
echo     ^</component^>
echo   ^</settings^>
echo ^</unattend^>
) > "%UNATTEND%"

echo  Unattend written : %UNATTEND%
echo.

:: --- Clear the ReserveManager ActiveScenario flag ---
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v ActiveScenario /t REG_DWORD /d 0 /f >nul

:: --- Run Sysprep with the unattend to preserve hostname ---
echo  Launching Sysprep... the device will reboot to OOBE.
echo.
start "" /D "%SYSPREP_DIR%" sysprep.exe /oobe /reboot /unattend:"%UNATTEND%"

:: Sysprep will reboot the machine; script ends naturally here
exit /b


:: ============================================================
::  [8]  REMOVE APPLICATION
::
::  Sub-menu for uninstalling known applications.
::  Each entry calls a dedicated PS1 script in Scripts\.
::
::  TO ADD A NEW APPLICATION:
::    1. Add a new echo line below with the next letter and
::       the application name.
::    2. Add a matching "if" line in the DISPATCH block below.
::    3. Add a matching :UNSUB_* label at the bottom of this
::       section that calls the PS1 and returns to this menu.
::    4. Drop the PS1 uninstaller into the Scripts\ folder.
:: ============================================================
:SUB_RemoveApplication
cls
echo.
echo  =============================================
echo       REMOVE APPLICATION
echo  =============================================
echo.
echo   Select an application to uninstall:
echo.
echo   [A]  HP Audio Control
echo.
echo   =============================================
echo   [0]  Back to Main Menu
echo   =============================================
echo.
set /p "appchoice=  Enter selection: "

if /i "%appchoice%"=="0" goto MENU
if /i "%appchoice%"=="A" goto UNSUB_HPAudioControl

:: Invalid input handler
echo.
echo   [!] Invalid selection. Please try again.
timeout /t 2 /nobreak >nul
goto SUB_RemoveApplication


:: ------------------------------------------------------------
::  [A]  HP AUDIO CONTROL
::
::  Requires:  Scripts\Uninstall-HPAudioControl.ps1
:: ------------------------------------------------------------
:UNSUB_HPAudioControl
cls
echo.
echo  =============================================
echo       REMOVE APPLICATION  ^>  HP Audio Control
echo  =============================================
echo.

set "APP_SCRIPT=%ROOT%Scripts\Uninstall-HPAudioControl.ps1"

if not exist "%APP_SCRIPT%" (
    echo  [ERROR] Script not found:
    echo          %APP_SCRIPT%
    echo.
    echo  Make sure Uninstall-HPAudioControl.ps1 is in
    echo  the Scripts\ folder on this USB drive.
    echo.
    pause
    goto SUB_RemoveApplication
)

echo  Running uninstaller for HP Audio Control...
echo.
PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%APP_SCRIPT%"

echo.
pause
goto SUB_RemoveApplication