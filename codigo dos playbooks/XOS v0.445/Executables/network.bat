@echo off
SETLOCAL EnableDelayedExpansion

for /F "tokens=*" %%c in ('powershell -Command " (Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes -join ',' "') do set "ChassisTypeString=%%c"
for /F "tokens=1 delims=," %%t in ("%ChassisTypeString%") do set "PrimaryChassisType=%%t"
set /A ChassisType=%PrimaryChassisType% 2>NUL

if not defined ChassisType (
    goto :EOF
)

if %ChassisType% LEQ 7 (
    goto DESKTOP
) else (
    goto LAPTOP
)

:DESKTOP

Reg.exe add "HKLM\System\CurrentControlSet\Services\Dnscache\Parameters" /v "DisableCoalescing" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\Local" /v "fDisablePowerManagement" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v "fDisablePowerManagement" /t REG_DWORD /d "1" /f

rem Disable Nagle's Algorithm on all TCP interfaces
for /f %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr "HKEY"') do (
    Reg.exe add "%%i" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f >nul 2>&1
    Reg.exe add "%%i" /v "TCPNoDelay" /t REG_DWORD /d "1" /f >nul 2>&1
)

for /f %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s ^| findstr "HKEY"') do (

    reg query "%%a" /v "*PhyType" >nul 2>&1
    if !errorlevel! equ 0 (
        rem Wi-Fi adapter, skip
    ) else (
        for %%v in (
            EnablePME
            *DeviceSleepOnDisconnect
            *EEE
            AdvancedEEE
            *SipsEnabled
            EnableAspm
            ASPM
            *ModernStandbyWoLMagicPacket
            *SelectiveSuspend
            EnableGigaLite
            GigaLite
            *WakeOnMagicPacket
            *WakeOnPattern
            AutoPowerSaveModeEnabled
            EEELinkAdvertisement
            EeePhyEnable
            EnableGreenEthernet
            EnableModernStandby
            PowerDownPll
            PowerSavingMode
            ReduceSpeedOnPowerDown
            S5WakeOnLan
            SavePowerNowEnabled
            ULPMode
            WakeOnLink
            WakeOnSlot
            WakeOnLinkChg
            WakeOnLinkUp
            WakeUpModeCap
            *NicAutoPowerSaver
            PowerSaveEnable
            EnablePowerManagement
            ForceWakeFromMagicPacketOnModernStandby
            WakeFromS5
            WakeOn
            EnableSavePowerNow
            *EnableDynamicPowerGating
            DynamicPowerGating
            EnableD3ColdInS0
            WakeFromPowerOff
            LogLinkStateEvent
        ) do (
            reg query "%%a" /v "%%v" >nul 2>&1 && Reg.exe add "%%a" /v "%%v" /t REG_SZ /d "0" /f >nul 2>&1
        )
        rem Values that need non-zero data
        reg query "%%a" /v "PnPCapabilities" >nul 2>&1 && Reg.exe add "%%a" /v "PnPCapabilities" /t REG_DWORD /d "24" /f >nul 2>&1
        reg query "%%a" /v "WakeOnMagicPacketFromS5" >nul 2>&1 && Reg.exe add "%%a" /v "WakeOnMagicPacketFromS5" /t REG_SZ /d "2" /f >nul 2>&1
        reg query "%%a" /v "WolShutdownLinkSpeed" >nul 2>&1 && Reg.exe add "%%a" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f >nul 2>&1
    )
) >nul 2>&1

goto :END

:LAPTOP
goto :END

:END
exit /b 0