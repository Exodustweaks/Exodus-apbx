@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnhancedPowerManagementEnabled" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "AllowIdleIrpInD3" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "AllowIdleIrpInD3" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnableSelectiveSuspend" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "EnableSelectiveSuspend" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "DeviceSelectiveSuspended" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "DeviceSelectiveSuspended" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "SelectiveSuspendEnabled" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "SelectiveSuspendEnabled" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "SelectiveSuspendOn" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "SelectiveSuspendOn" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnumerationRetryCount" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "EnumerationRetryCount" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "ExtPropDescSemaphore" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "ExtPropDescSemaphore" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "WaitWakeEnabled" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "WaitWakeEnabled" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "D3ColdSupported" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "D3ColdSupported" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "WdfDirectedPowerTransitionEnable" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "WdfDirectedPowerTransitionEnable" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "EnableIdlePowerManagement" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "EnableIdlePowerManagement" /t REG_DWORD /d "0" /f
for /f %%a in ('Reg.exe query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "IdleInWorkingState" ^| findstr "HKEY"') do Reg.exe add "%%a" /v "IdleInWorkingState" /t REG_DWORD /d "0" /f
powercfg /h off
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d "0" /f

:: ===== CONFIG =====
set "POWERPLAN_GUID=55555555-5555-5555-5555-555555555555"
set "POWERPLAN_FILE=%~dp0..\..\Power\PeakOS.pow"
:: ==================


:: Check if power plan file exists
if not exist "%POWERPLAN_FILE%" (
    echo [ERROR] Power plan file not found at: %POWERPLAN_FILE%
    exit /b 1
)

:: Switch to Balanced temporarily to allow deletion of the custom plan if it's currently active
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1

:: Delete existing custom plan to ensure a fresh import
powercfg -delete %POWERPLAN_GUID% >nul 2>&1

:: Import the new power plan
powercfg -import "%POWERPLAN_FILE%" %POWERPLAN_GUID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to import power plan.
    exit /b 1
)

:: Activate the power plan
powercfg -setactive %POWERPLAN_GUID%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to activate power plan.
    exit /b 1
)

:: Verify the power plan is active
for /f "tokens=4" %%a in ('powercfg -getactivescheme') do (
    if "%%a" equ "%POWERPLAN_GUID%" (
        echo [SUCCESS] PeakOS Power Plan applied successfully.
    ) else (
        echo [WARNING] Active power plan GUID does not match. Please checks manually.
    )
)

