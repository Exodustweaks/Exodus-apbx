@echo off
setlocal EnableDelayedExpansion

:: Request Administrator privileges
openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Applying Nvidia Dwords...

:: --- Global Keys ---

:: Hide NVIDIA Tray Icon
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v "StartOnLogin" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "HideXGpuTrayIcon" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v "ShowTrayIcon" /t REG_DWORD /d 0 /f

:: Disable Display Power Savings (Global)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 0 /f
reg add "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 0 /f

:: Disable Logging (Global Parameters)
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogWarningEntries" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogPagingEntries" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogEventEntries" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogErrorEntries" /t REG_DWORD /d 0 /f


:: --- Instance Specific Keys ---

set "base=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
set "found_gpu=0"

for /f "tokens=*" %%A in ('reg query "%base%" /k /f "*" ^| findstr /r "\\....$"') do (
    reg query "%%A" /v "ProviderName" 2>nul | find /i "NVIDIA" >nul
    if !errorlevel! equ 0 (
        set "target=%%A"
        set "found_gpu=1"
        echo Found Nvidia GPU at: !target!
        
        :: Disable Runtime Power Management
        reg add "!target!" /v "EnableRuntimePowerManagement" /t REG_DWORD /d 0 /f
        
        :: Disable Logging
        reg add "!target!" /v "RmRcWatchdog" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RmLogonRC" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RMIntrDetailedLogs" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RMCtxswLog" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RMNvLog" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RMSuppressGPIOIntrErrLog" /t REG_DWORD /d 0 /f
        
        :: Disable ASPM
        reg add "!target!" /v "RmOverrideSupportChipsetAspm" /t REG_DWORD /d 1 /f
        reg add "!target!" /v "RMEnableASPMDT" /t REG_DWORD /d 1 /f
        reg add "!target!" /v "RMDisableGpuASPMFlags" /t REG_DWORD /d 3 /f
        reg add "!target!" /v "RMEnableASPMAtLoad" /t REG_DWORD /d 0 /f
        reg add "!target!" /v "RMEnableASPMPublicBits" /t REG_DWORD /d 0 /f
        
        :: Disable Event Tracer
        reg add "!target!" /v "RMEnableEventTracer" /t REG_DWORD /d 0 /f
        
        :: Disable Error Checks
        reg add "!target!" /v "SkipSwStateErrChecks" /t REG_DWORD /d 1 /f
        
        :: Disable Advanced Error Reporting
        reg add "!target!" /v "RMAERRForceDisable" /t REG_DWORD /d 1 /f
        
        :: Force never power off the MIOs
        reg add "!target!" /v "RmMIONoPowerOff" /t REG_DWORD /d 1 /f
        
        :: Force Highest NVLink Link Power States
        reg add "!target!" /v "RMNvLinkControlLinkPM" /t REG_DWORD /d 0xaa /f
        
        :: Disable Noise Aware Pll
        reg add "!target!" /v "RmEnableNoiseAwarePll" /t REG_DWORD /d 0 /f
        
        :: Disable Optimal Power For Padlink Pll
        reg add "!target!" /v "RMDisableOptimalPowerForPadlinkPll" /t REG_DWORD /d 1 /f
        
        :: Disable Pex Power Savings features
        reg add "!target!" /v "RMPexPowerSavings" /t REG_DWORD /d 0 /f
        
        :: Disable CLKREQ and DEEP L1
        reg add "!target!" /v "RM2779240" /t REG_DWORD /d 5 /f
        
        :: Disable the power-off-dram-pll-when-unused feature
        reg add "!target!" /v "RmClkPowerOffDramPllWhenUnused" /t REG_DWORD /d 0 /f
        
        :: Disable 6 Power Savings
        reg add "!target!" /v "RMOPSB" /t REG_DWORD /d 0x2aa2 /f
        
        :: Disable Async P-States
        reg add "!target!" /v "DisableAsyncPstates" /t REG_DWORD /d 1 /f
    )
)

if "!found_gpu!"=="0" (
    echo No Nvidia GPU found, but global keys were applied.
) else (
    echo Finished applying Nvidia Dwords.
)
