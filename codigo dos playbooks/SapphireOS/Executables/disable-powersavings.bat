@echo off
setlocal EnableDelayedExpansion

for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command ^
    "(Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes[0]"`) do set "CHASSIS=%%a"

set "DEVICE_TYPE=PC"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do (
    if "%CHASSIS%"=="%%a" set "DEVICE_TYPE=LAPTOP"
)

if /I "%DEVICE_TYPE%"=="LAPTOP" (
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "0" /f >nul 2>&1
    cls
) else (
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\serenum" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\sermouse" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\serial" /v "Start" /t REG_DWORD /d "4" /f >nul 2>&1
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wmiacpi" /v "Start" /t REG_DWORD /d "2" /f >nul 2>&1
    echo Disabling power-saving features...
    for %%a in (
        EnhancedPowerManagementEnabled
        AllowIdleIrpInD3
        EnableSelectiveSuspend
        DeviceSelectiveSuspended
        SelectiveSuspendEnabled
        SelectiveSuspendOn
        WaitWakeEnabled
        D3ColdSupported
        WdfDirectedPowerTransitionEnable
        EnableIdlePowerManagement
        IdleInWorkingState
    ) do (
        for /f "delims=" %%b in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum" /s /f "%%a" ^| findstr "HKEY"') do (
            Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f >nul 2>&1
        )
    )
    Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f >nul 2>&1
    cls
)
Echo "Disabling HIPM, DIPM and HDDParking"
for %%a in (EnableHIPM EnableDIPM EnableHDDParking) do for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%a" ^| findstr "HKEY"') do Reg.exe add "%%b" /v "%%a" /t REG_DWORD /d "0" /f >nul 2>&1
cls

Echo "Disabling StorPort Idle"
for /f "tokens=*" %%s in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "StorPort" ^| findstr /e "StorPort"') do Reg.exe add "%%s" /v "EnableIdlePowerManagement" /t REG_DWORD /d "0" /f >nul 2>&1
cls
%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | ForEach-Object { $_.enable = $false; $_.psbase.put(); }"