@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: clear pinned taskbar shortcuts
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar*"

:: clear taskband registry
Reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f 

powershell -ExecutionPolicy bypass "Disable-MMAgent -MemoryCompression" 

:: configure boot settings
bcdedit /set useplatformtick No
bcdedit /set useplatformclock No
bcdedit /set disabledynamictick Yes
bcdedit /set isolatedcontext No
bcdedit /set allowedinmemorysettings 0x0
bcdedit /set loadoptions "DISABLE-LSA-ISO,DISABLE-VBS"
bcdedit /set disableelamdrivers Yes
bcdedit /set nx OptOut
bcdedit /set hypervisorlaunchtype Off
bcdedit /set bootmenupolicy Legacy
bcdedit /set bootux Disabled
bcdedit /set quietboot Yes
bcdedit /set uselegacyapicmode Yes
bcdedit /set usefirmwarepcisettings No

:: disable DMA remapping
for /f %%i in ('Reg.exe query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /f DmaRemappingCompatible ^| find /i "Services\" ') do (
	Reg.exe add "%%i" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)

:: configure mmcss
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Latency Sensitive" /t REG_SZ /d "True" /f

Reg.exe add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f
Reg.exe add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 1500 /f
Reg.exe add "HKCU\Control Panel\Desktop" /v WaitToKillTimeout /t REG_SZ /d 2500 /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2500 /f




for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI" ^| findstr "HKEY"') do (
    for /f "tokens=*" %%a in ('reg query "%%i" ^| findstr "HKEY"') do (
        Reg.exe add "%%a\Device Parameters\Disk" /v CacheIsPowerProtected /t REG_DWORD /d 1 /f
        Reg.exe add "%%a\Device Parameters\Disk" /v UserWriteCacheSetting /t REG_DWORD /d 1 /f
    )
)


:: disable NVME and SATA DMA remapping
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\storahci\Parameters" /v DmaRemappingCompatible /t REG_DWORD /d 0 /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v DmaRemappingCompatible /t REG_DWORD /d 0 /f


:: configure NTFS settings
fsutil behavior set disableLastAccess 1 >NUL 2>nul
fsutil behavior set disable8dot3 1 >NUL 2>nul

setx POWERSHELL_TELEMETRY_OPTOUT 1

:: Get the version number from the `ver` command
for /f "tokens=3 delims=[]. " %%a in ('ver') do set version=%%a

:: Check if the version is greater than or equal to 10.0.22000 (which is the version for Windows 11)
if %version% geq 22000 (
    set w11=true
) else (
    set w11=false
)
if not defined w11 (
	bcdedit /set description "PeakOS 10" >NUL 2>nul
  Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Model"  /t REG_SZ /d "PeakOS 10" /f >NUL 2>nul
  Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "PeakOS 10" /f >NUL 2>nul
) else (
	bcdedit /set description "PeakOS 11" >NUL 2>nul
  Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Model"  /t REG_SZ /d "PeakOS 11" /f >NUL 2>nul
  Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "PeakOS 11" /f >NUL 2>nul
)

:: add new batch file to context menu
Reg.exe add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6002" /f 
Reg.exe add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f 

:: add  new reg file to context menu
Reg.exe add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\regedit.exe,-309" /f 
Reg.exe add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f 




:: clear desktop shortcuts
del /f /q "%USERPROFILE%\Desktop\*.lnk"
del /f /q "C:\Users\Public\Desktop\*.lnk"
