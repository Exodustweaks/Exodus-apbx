@echo off
setlocal EnableDelayedExpansion
dism >nul 2>&1 || (echo ^<Run the script as administrator^> && pause>nul && cls&exit)

:Menu
title System Configuration Manager
color B
mode 65,22
cls
echo.
echo  [1] Network                   [6] SmartScreen
echo  [2] XHCI IMOD                 [7] Memory Integrity (HVCI)
echo  [3] Windows Updates           [8] Vulnerable Driver Blocklist
echo  [4] Wi-Fi                     [9] Hyper-V
echo  [5] Bluetooth                 [0] Exit
echo.
choice /c 1234567890 /n /m "Select an option: "
set "mchoice=%errorlevel%"

if "%mchoice%"=="1" goto :Network
if "%mchoice%"=="2" goto :IMOD
if "%mchoice%"=="3" goto :Updates
if "%mchoice%"=="4" goto :Wifi
if "%mchoice%"=="5" goto :Bluetooth
if "%mchoice%"=="6" goto :SmartScreen
if "%mchoice%"=="7" goto :HVCI
if "%mchoice%"=="8" goto :Blocklist
if "%mchoice%"=="9" goto :HyperV
if "%mchoice%"=="10" exit
goto :Menu

:Network
cls
echo [1] Default Network
echo [2] Tweaked Network Settings
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "nchoice=%errorlevel%"
if "%nchoice%"=="3" goto :Menu
if "%nchoice%"=="1" goto :NetDefault
if "%nchoice%"=="2" goto :NetTweaked
goto :Network

:NetDefault
netsh int ip reset >nul 2>&1
netsh interface ipv4 reset >nul 2>&1
netsh interface ipv6 reset >nul 2>&1
netsh interface tcp reset >nul 2>&1
netsh winsock reset >nul 2>&1
PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') { pnputil /remove-device $dev.InstanceId }" >nul 2>&1
pnputil /scan-devices >nul 2>&1
for /f %%n in ('wmic path win32_networkadapter get GUID^| findstr "{"') do (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%n" /v "TcpAckFrequency" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%n" /v "TcpDelAckTicks" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%n" /v "TCPNoDelay" /f >nul 2>&1
) >nul 2>&1
for /f "delims=" %%u in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%u" /v "NetbiosOptions" /t REG_DWORD /d "0" /f >nul 2>&1
) >nul 2>&1
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d "1" /f >nul 2>&1
echo Done.
pause
goto :Menu

:NetTweaked
netsh int ip reset >nul 2>&1
netsh interface ipv4 reset >nul 2>&1
netsh interface ipv6 reset >nul 2>&1
netsh interface tcp reset >nul 2>&1
netsh winsock reset >nul 2>&1
PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') { pnputil /remove-device $dev.InstanceId }" >nul 2>&1
pnputil /scan-devices >nul 2>&1
set TMPN=%temp%\nic_settings.txt
> "%TMPN%" (
    echo *DeviceSleepOnDisconnect:REG_SZ:0
    echo *EEE:REG_SZ:0
    echo *ModernStandbyWoLMagicPacket:REG_SZ:0
    echo *SelectiveSuspend:REG_SZ:0
    echo *WakeOnMagicPacket:REG_SZ:0
    echo *WakeOnPattern:REG_SZ:0
    echo *FlowControl:REG_SZ:0
    echo *PMNSOffload:REG_SZ:0
    echo *PMARPOffload:REG_SZ:0
    echo *NicAutoPowerSaver:REG_SZ:0
    echo *PMWiFiRekeyOffload:REG_SZ:0
    echo *EnableDynamicPowerGating:REG_SZ:0
    echo EnablePME:REG_SZ:0
    echo AutoPowerSaveModeEnabled:REG_SZ:0
    echo EEELinkAdvertisement:REG_SZ:0
    echo EeePhyEnable:REG_SZ:0
    echo EnableGreenEthernet:REG_SZ:0
    echo EnableModernStandby:REG_SZ:0
    echo GigaLite:REG_SZ:0
    echo PowerDownPll:REG_SZ:0
    echo PowerSavingMode:REG_SZ:0
    echo ReduceSpeedOnPowerDown:REG_SZ:0
    echo S5WakeOnLan:REG_SZ:0
    echo SavePowerNowEnabled:REG_SZ:0
    echo ULPMode:REG_SZ:0
    echo WakeOnLink:REG_SZ:0
    echo WakeOnSlot:REG_SZ:0
    echo WakeUpModeCap:REG_SZ:0
    echo WaitAutoNegComplete:REG_SZ:0
    echo WakeOnMagicPacketFromS5:REG_SZ:2
    echo WolShutdownLinkSpeed:REG_SZ:2
    echo EnablePowerManagement:REG_SZ:0
    echo ForceWakeFromMagicPacketOnModernStandby:REG_SZ:0
    echo WakeFromS5:REG_SZ:0
    echo WakeOn:REG_SZ:0
    echo OBFFEnabled:REG_SZ:0
    echo DMACoalescing:REG_SZ:0
    echo EnableSavePowerNow:REG_SZ:0
    echo EnableD0PHYFlexibleSpeed:REG_SZ:0
    echo EnablePHYWakeUp:REG_SZ:0
    echo EnablePHYFlexibleSpeed:REG_SZ:0
    echo AllowAllSpeedsLPLU:REG_SZ:0
    echo EnableD3ColdInS0:REG_SZ:0
    echo LatencyToleranceReporting:REG_SZ:0
    echo EnableAspm:REG_SZ:0
    echo PnPCapabilities:REG_DWORD:24
    echo LogLinkStateEvent:REG_SZ:16
)
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| find "HKEY"') do (
    for /f "usebackq tokens=1-3 delims=:" %%k in ("%TMPN%") do (
        reg query "%%a" /v "%%k" >nul 2>&1 && reg add "%%a" /v "%%k" /t %%l /d %%m /f >nul 2>&1
    )
)
del "%TMPN%" >nul 2>&1
powershell -NoProfile -Command "Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } | ForEach-Object { $pnp='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$_.PNPDeviceID; $driver=(Get-ItemProperty $pnp -Name 'Driver' -ErrorAction SilentlyContinue).Driver; $class='HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$driver; $type=(Get-ItemProperty $class -Name '*PhysicalMediaType' -ErrorAction SilentlyContinue).'*PhysicalMediaType'; if($type -eq '14' -or $type -eq '9'){Set-ItemProperty $class -Name 'PnPCapabilities' -Value 24 -Type DWord -Force >$null} }"
powershell -Command "Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID vmware_bridge,ms_lldp,ms_lltdio,ms_implat,ms_rspndr,ms_server,ms_msclient -Confirm:$false }" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0x0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "0x1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "TrackNblOwner" /t REG_DWORD /d "0x0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d "0x0" /f >nul 2>&1
for /f "tokens=*" %%B in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" 2^>nul') do (
    reg add "%%B" /v "NetbiosOptions" /t REG_DWORD /d "0x2" /f >nul 2>&1
)
powershell Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enable >nul 2>&1
powershell Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disable >nul 2>&1
echo Done.
pause
goto :Menu

:IMOD
cls
echo [1] Disable IMOD at boot
echo [2] REMOVE auto-launch
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "ichoice=%errorlevel%"
if "%ichoice%"=="3" goto :Menu
if "%ichoice%"=="1" (
    schtasks /create /tn "IMOD" /tr "C:\Windows\Misc\IMOD\IMOD.exe" /sc onlogon /rl highest /f >nul 2>&1
    echo Task created.
)
if "%ichoice%"=="2" (
    schtasks /delete /tn "IMOD" /f >nul 2>&1
    echo Task removed.
)
pause
goto :Menu

:Updates
cls
echo [1] Disable Updates
echo [2] Enable Updates
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "uchoice=%errorlevel%"
if "%uchoice%"=="3" goto :Menu
if "%uchoice%"=="1" (
    reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v TargetReleaseVersion /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -Command "$ver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion; New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'TargetReleaseVersionInfo' -Value $ver -PropertyType String -Force" >nul 2>&1
    reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v DisableDualScan /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v DontSearchWindowsUpdate /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v AutoDownloadAndUpdateMapData /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\Maps" /v AutoUpdateEnabled /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v AutoDownload /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableOSUpgrade /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v AllowSpeechModelUpdate /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAHealth /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f >nul 2>&1
    net stop wuauserv >nul 2>&1
    net stop UsoSvc >nul 2>&1
    echo Updates Disabled.
)
if "%uchoice%"=="2" (
    reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v TargetReleaseVersion /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v TargetReleaseVersionInfo /f >nul 2>&1
    reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v DisableDualScan /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
    reg delete "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v DontSearchWindowsUpdate /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" /v AutoDownloadAndUpdateMapData /f >nul 2>&1
    reg delete "HKLM\SYSTEM\Maps" /v AutoUpdateEnabled /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v AutoDownload /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableOSUpgrade /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v AllowSpeechModelUpdate /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAHealth /f >nul 2>&1
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v SetDisableUXWUAccess /f >nul 2>&1
    net start wuauserv >nul 2>&1
    net start UsoSvc >nul 2>&1
    echo Updates Enabled.
)
pause
goto :Menu

:Wifi
cls
echo [1] Disable Wi-Fi
echo [2] Enable Wi-Fi
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "wchoice=%errorlevel%"
if "%wchoice%"=="3" goto :Menu
if "%wchoice%"=="1" (
    sc stop WlanSvc >nul 2>&1
    sc stop WwanSvc >nul 2>&1
    sc stop NativeWifiP >nul 2>&1
    sc config WlanSvc start=disabled >nul 2>&1
    sc config WwanSvc start=disabled >nul 2>&1
    sc config NativeWifiP start=disabled >nul 2>&1
    echo Wi-Fi Disabled.
)
if "%wchoice%"=="2" (
    sc config WlanSvc start=auto error=ignore >nul 2>&1
    sc config WwanSvc start=auto error=ignore >nul 2>&1
    sc config NativeWifiP start=auto error=ignore >nul 2>&1
    sc start WlanSvc >nul 2>&1
    sc start WwanSvc >nul 2>&1
    sc start NativeWifiP >nul 2>&1
    echo Wi-Fi Enabled.
)
pause
goto :Menu

:Bluetooth
cls
echo [1] Disable Bluetooth
echo [2] Enable Bluetooth
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "bchoice=%errorlevel%"
if "%bchoice%"=="3" goto :Menu
if "%bchoice%"=="1" (
    for %%s in (bthserv BluetoothUserService BTAGService BthAvctpSvc HidBth Microsoft_Bluetooth_AvrcpTransport BthEnum BthHFEnum BthLEEnum BthMini BTHMODEM BTHPORT BTHUSB RFCOMM) do (
        sc config %%s start=disabled >nul 2>&1
        sc stop %%s >nul 2>&1
    )
    echo Bluetooth Disabled.
)
if "%bchoice%"=="2" (
    sc config bthserv start=auto >nul 2>&1
    sc config BluetoothUserService start=auto >nul 2>&1
    for %%s in (BTAGService BthAvctpSvc HidBth Microsoft_Bluetooth_AvrcpTransport BthEnum BthHFEnum BthLEEnum BthMini BTHMODEM BTHPORT BTHUSB RFCOMM) do (
        sc config %%s start=demand >nul 2>&1
    )
    for %%s in (bthserv BluetoothUserService BTAGService BthAvctpSvc HidBth Microsoft_Bluetooth_AvrcpTransport BthEnum BthHFEnum BthLEEnum BthMini BTHMODEM BTHPORT BTHUSB RFCOMM) do (
        sc start %%s >nul 2>&1
    )
    echo Bluetooth Enabled.
)
pause
goto :Menu

:SmartScreen
cls
echo [1] Disable SmartScreen
echo [2] Re-enable SmartScreen
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "schoice=%errorlevel%"
if "%schoice%"=="3" goto :Menu
if "%schoice%"=="1" (
    reg add "HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d "0" /f >nul 2>&1
    taskkill /f /im smartscreen.exe >nul 2>&1
    ren "C:\Windows\System32\smartscreen.exe" smartscreen.old >nul 2>&1
    echo SmartScreen Disabled.
)
if "%schoice%"=="2" (
    reg add "HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d "1" /f >nul 2>&1
    if exist "C:\Windows\System32\smartscreen.old" ren "C:\Windows\System32\smartscreen.old" smartscreen.exe >nul 2>&1
    echo SmartScreen Enabled.
)
pause
goto :Menu

:HVCI
cls
echo [1] Disable HVCI
echo [2] Enable HVCI
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "hchoice=%errorlevel%"
if "%hchoice%"=="3" goto :Menu
if "%hchoice%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f >nul 2>&1
    echo HVCI Disabled.
)
if "%hchoice%"=="2" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "1" /f >nul 2>&1
    echo HVCI Enabled.
)
pause
goto :Menu

:Blocklist
cls
echo [1] Disable Blocklist
echo [2] Enable Blocklist
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "lchoice=%errorlevel%"
if "%lchoice%"=="3" goto :Menu
if "%lchoice%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "Locked" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Locked" /t REG_DWORD /d 0 /f >nul 2>&1
    echo Blocklist Disabled.
)
if "%lchoice%"=="2" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t REG_DWORD /d 1 /f >nul 2>&1
    echo Blocklist Enabled.
)
pause
goto :Menu

:HyperV
cls
echo [1] Disable Hyper-V
echo [2] Enable Hyper-V
echo [3] Back
echo.
choice /c 123 /n /m "Choose: "
set "vchoice=%errorlevel%"
if "%vchoice%"=="3" goto :Menu
if "%vchoice%"=="1" (
    bcdedit /set {hypervisorsettings} hypervisorlaunchtype Off >nul 2>&1
    for %%v in (hypervisordebug hypervisorenforcedcodeintegrity hypervisormsrfilterpolicy hypervisormmionxpolicy hypervisordebugtype hypervisordisableslat hypervisorusevapic hypervisornumproc hypervisordebugpages hypervisoruselargevtlb hypervisoriommupolicy vsmlaunchtype) do (
        bcdedit /deletevalue {hypervisorsettings} %%v >nul 2>&1
    )
    bcdedit /deletevalue hypervisorloadoptions >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -FriendlyName 'Microsoft Hyper-V Virtualization Infrastructure Driver' -ErrorAction SilentlyContinue | Disable-PnpDevice -Confirm:$false"
    echo Hyper-V Disabled.
)
if "%vchoice%"=="2" (
    bcdedit /set hypervisorlaunchtype auto >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -FriendlyName 'Microsoft Hyper-V Virtualization Infrastructure Driver' -ErrorAction SilentlyContinue | Enable-PnpDevice -Confirm:$false"
    echo Hyper-V Enabled.
)
pause
goto :Menu