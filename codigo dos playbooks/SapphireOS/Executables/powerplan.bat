@echo off

for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command ^
    "(Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes[0]"`) do set "CHASSIS=%%a"

set "DEVICE_TYPE=PC"
for %%a in (8 9 10 11 12 13 14 18 21 30 31 32) do if "%CHASSIS%"=="%%a" set "DEVICE_TYPE=LAPTOP"

if /I "%DEVICE_TYPE%"=="LAPTOP" (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
    powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000
    powercfg /setdcvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000
    cls
) else (
    powercfg -import %SYSTEMROOT%\SapphireOS.pow 3669b9e3-17ce-4e11-9c13-6e9e0724b157
    powercfg -setactive 3669b9e3-17ce-4e11-9c13-6e9e0724b157
	del %SYSTEMROOT%\SapphireOS.pow
    cls
)
