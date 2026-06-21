@echo off
netsh int ip reset >nul 2>&1
netsh interface ipv4 reset >nul 2>&1
netsh interface ipv6 reset >nul 2>&1
netsh interface tcp reset >nul 2>&1
netsh winsock reset >nul 2>&1
PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') { pnputil /remove-device $dev.InstanceId }" >nul 2>&1
pnputil /scan-devices >nul 2>&1

setlocal

set TMP=%temp%\nic_settings.txt
> "%TMP%" (
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
)

for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| find "HKEY"') do (
  for /f "usebackq tokens=1-3 delims=:" %%k in ("%TMP%") do (
    reg query "%%a" /v "%%k" >nul 2>&1 && reg add "%%a" /v "%%k" /t %%l /d %%m /f >nul 2>&1
  )
)

del "%TMP%" >nul 2>&1
endlocal

powershell -NoProfile -Command "Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.PNPDeviceID -like 'PCI\VEN_*' } | ForEach-Object { $pnp='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$_.PNPDeviceID; $driver=(Get-ItemProperty $pnp -Name 'Driver' -ErrorAction SilentlyContinue).Driver; $class='HKLM:\SYSTEM\CurrentControlSet\Control\Class\'+$driver; $type=(Get-ItemProperty $class -Name '*PhysicalMediaType' -ErrorAction SilentlyContinue).'*PhysicalMediaType'; if($type -eq '14' -or $type -eq '9'){Set-ItemProperty $class -Name 'PnPCapabilities' -Value 24 -Type DWord -Force >$null} }"

powershell -Command "Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID vmware_bridge,ms_lldp,ms_lltdio,ms_implat,ms_rspndr,ms_server,ms_msclient -Confirm:$false } >$null"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0x0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "0x1" /f >nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "TrackNblOwner" /t REG_DWORD /d "0x0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "EnableLMHOSTS" /t REG_DWORD /d "0x0" /f >nul 2>&1

for /f "tokens=*" %%B in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" 2^>nul') do (
	reg add "%%B" /v "NetbiosOptions" /t REG_DWORD /d "0x2" /f >nul 2>&1
)

powershell Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enable >nul 2>&1
powershell Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disable >nul 2>&1