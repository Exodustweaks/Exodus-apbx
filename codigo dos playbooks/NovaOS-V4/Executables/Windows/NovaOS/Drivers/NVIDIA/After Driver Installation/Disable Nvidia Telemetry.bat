@echo off
Color B

@echo Dont Send Telemetry Data
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID44231 /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID64640 /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v EnableRID66610 /t REG_DWORD /d 0 /f
reg delete "HKLM\System\CurrentControlSet\Services\nvlddmkm\NvCamera" /f
sc config NvTelemetryContainer start=disabled >nul 2>&1

For %%C in (Display.3DVision Display.Audio Ansel) Do (
Rundll32.exe "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.dll",UninstallPackage %%C >Nul 2>&1
)

@echo Disable Telemetry and Data Collection
Reg.exe Add "HKLM\Software\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d "0" /f >Nul 2>&1

@echo Remove NvBackend From Startup
Reg.exe Delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >Nul 2>&1

@echo Disable NVIDIA Tasks
For %%i in (NvTmRep_CrashReport1 NvTmRep_CrashReport2 NvTmRep_CrashReport3 NvTmRep_CrashReport4) Do Schtasks /Change /Disable /Tn "%%i_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" >Nul 2>&1
For %%i in (NvTmMon NvTmRep NvProfile NvNodeLauncher NvDriverUpdateCheckDaily NvBatteryBoostCheckOnLogon "NVIDIA GeForce Experience SelfUpdate") Do Schtasks /Change /Tn "%%i" /Disable >Nul 2>&1

@echo Remove Telemetry and Camera Files
del /s /q "%SystemRoot%\System32\DriverStore\FileRepository\NvTelemetry64.dll"
rd /s /q "%SystemRoot%\System32\DriverStore\FileRepository\nv*\NvCamera"
del /s /q "%SystemRoot%\System32\DriverStore\FileRepository\nv*\Display.NvContainer\plugins\LocalSystem\_DisplayDriverRAS.dll"

@echo Delete NVIDIA Corporation Folders
Takeown /F "C:\Windows\System32\drivers\NVIDIA Corporation" /R /D Y >Nul 2>&1
Icacls "C:\Windows\System32\drivers\NVIDIA Corporation" /Grant %Username%:F /T >Nul 2>&1
Rmdir /S /Q "C:\Windows\System32\drivers\NVIDIA Corporation" >Nul 2>&1
cd /d "%systemdrive%\Windows\System32\DriverStore\FileRepository\" >nul 2>&1
dir NvTelemetry64.dll /a /b /s >nul 2>&1
del NvTelemetry64.dll /a /s >nul 2>&1
cd /d "%systemdrive%\Windows\System32\DriverStore\FileRepository\nv_dispig.inf_amd64_20ea7d0c917cde22" >nul 2>&1
del NvTelemetry64.dll /a /s >nul 2>&1

@echo Delete other NVIDIA Folders
rd /s /q "%systemdrive%\Program Files\NVIDIA Corporation\Display.NvContainer\plugins\LocalSystem\DisplayDriverRAS" >nul 2>&1
rd /s /q "%systemdrive%\Program Files\NVIDIA Corporation\DisplayDriverRAS" >nul 2>&1
rd /s /q "%systemdrive%\ProgramData\NVIDIA Corporation\DisplayDriverRAS" >nul 2>&1

@echo.
@echo Nvidia Telemetry Disabled!
pause
