@echo off

dism >nul 2>&1 || (echo ^<Run the script as administrator^> && pause>nul && cls&exit)
title Configure Nvidia
color B

Set "BinaryMask=00ffff0f01ffff0f02ffff0f03ffff0f04ffff0f05ffff0f06ffff0f07ffff0f08ffff0f09ffff0f0affff0f0bffff0f0cffff0f0dffff0f0effff0f0fffff0f10ffff0f11ffff0f12ffff0f13ffff0f14ffff0f15ffff0f16ffff0f00ffff1f01ffff1f02ffff1f03ffff1f04ffff1f05ffff1f06ffff1f07ffff1f08ffff1f09ffff1f0affff1f0bffff1f0cffff1f0dffff1f0effff1f0fffff1f00ffff2f01ffff2f02ffff2f03ffff2f04ffff2f05ffff2f06ffff2f07ffff2f08ffff2f09ffff2f0affff2f0bffff2f0cffff2f0dffff2f0effff2f0fffff2f00ffff3f01ffff3f02ffff3f03ffff3f04ffff3f05ffff3f06ffff3f07ffff3f" 

for /L %%i in (0,1,9) do (
    for /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000%%i" /v "ProviderName" 2^>nul') do (
	if /i "%%b"=="NVIDIA" (
		set G=000%%i
		)
	)
)

choice -c 12 -n -m "[1] Add Nvidia | [2] Remove Nvidia"
if %errorlevel% equ 1 (
	cls
	@echo Disable DLSS Indicator
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v "ShowDlssIndicator" /t REG_DWORD /d 0 /f

	@echo Add Nvidia Container Toggle to Context Menu
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v Icon /t REG_SZ /d "C:\Windows\Misc\nvidiaprofileinspector.exe,0" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v MUIVerb /t REG_SZ /d "Nvidia Container" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v Position /t REG_SZ /d "Bottom" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer" /v SubCommands /t REG_SZ /d "" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer" /v HasLUAShield /t REG_SZ /d "" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer" /v MUIVerb /t REG_SZ /d "Enable Container" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\EnableNvContainer\command" /ve /t REG_SZ /d "C:\Windows\Misc\NvContainerON.bat" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer" /v HasLUAShield /t REG_SZ /d "" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer" /v MUIVerb /t REG_SZ /d "Disable Container" /f
	reg add "HKCR\DesktopBackground\Shell\NvidiaContainer\Shell\DisableNvContainer\command" /ve /t REG_SZ /d "C:\Windows\Misc\NvContainerOFF.bat" /f

	@echo Disable NVIDIA Driver Notification
	reg add "HKCU\SOFTWARE\NVIDIA Corporation\Global\GFExperience" /v "NotifyNewDisplayUpdates" /t REG_DWORD /d 0 /f

	@echo Enable NVIDIA Control Panel Developer Settings
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d 1 /f

	@echo Hide NVIDIA Tray Icon
	reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v "StartOnLogin" /t REG_DWORD /d 0 /f
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "HideXGpuTrayIcon" /t REG_DWORD /d 1 /f
	reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v "ShowTrayIcon" /t REG_DWORD /d 0 /f

	@echo Disable Display Power Savings
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 0 /f
	reg add "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 0 /f

	@echo Disable Runtime Power Management
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableRuntimePowerManagement" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo GPU Performance Counters for All Users
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmProfilingAdminOnly" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "0" /f

	@echo Disable DLSS Indicator
	reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v "ShowDlssIndicator" /t REG_DWORD /d 0 /f

	@echo Disable HD Audio D3Cold
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "EnableHDAudioD3Cold" /t REG_DWORD /d 0 /f

	@echo Disable Hardware Fault Buffer
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHwFaultBuffer" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Per Intr DPC Queueing
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePerIntrDPCQueueing" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Engine Gatings
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElcg" /t reg_DWORD /d "1431655765" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMBlcg" /t reg_DWORD /d "286331153" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpg" /t reg_DWORD /d "4095" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSlcg" /t reg_DWORD /d "262131" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMFspg" /t reg_DWORD /d "15" /f > nul 2>&1

	@echo Disable GC6
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Feature" /t reg_DWORD /d "699050" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Parameters" /t reg_DWORD /d "85" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDidleFeatureGC5" /t reg_DWORD /d "44731050" /f > nul 2>&1

	@echo Disable Hot Plug Support
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHotPlugSupportDisable" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable the Paged DMA mode for FBSR
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrPagedDMA" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Post L2 Compression
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePostL2Compression" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Logging
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmRcWatchdog" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLogonRC" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMIntrDetailedLogs" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMCtxswLog" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvLog" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSuppressGPIOIntrErrLog" /t reg_DWORD /d "0" /f > nul 2>&1

	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v "LogDisableMasks" /t REG_BINARY /d "%BinaryMask%" /f >Nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogWarningEntries" /t REG_DWORD /d "0" /f >Nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogPagingEntries" /t REG_DWORD /d "0" /f >Nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogEventEntries" /t REG_DWORD /d "0" /f >Nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogErrorEntries" /t REG_DWORD /d "0" /f >Nul 2>&1

	@echo Disables USB-C PMU event logging in RM
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMUsbcDebugMode" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable feature disablement
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableFeatureDisablement" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable breakpoint on DEBUG resource manager on RC errors
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmBreakonRC" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable SMC on a specific GPU
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDebugSetSMCMode" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable LRC coalescing
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableLRCCoalescing" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Turn off I2C Nanny
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmEnableI2CNanny" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Latency Tolerance
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrOverride" /t reg_DWORD /d "1" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrL12ThresholdOverride" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDeepL1EntryLatencyUsec" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Pre OS Apps
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisablePreosapps" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo RmPerfLimitsOverride
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPerfLimitsOverride" /t reg_DWORD /d "21" /f > nul 2>&1

	@echo RMGCOffFeature
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGCOffFeature" /t reg_DWORD /d "2" /f > nul 2>&1

	@echo Disable ASPM
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideSupportChipsetAspm" /t reg_DWORD /d "1" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMDT" /t reg_DWORD /d "1" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableGpuASPMFlags" /t reg_DWORD /d "3" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMAtLoad" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable Event Tracer
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableEventTracer" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable Error Checks
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SkipSwStateErrChecks" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Advanced Error Reporting
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMAERRForceDisable" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable OPSB Feature
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM580312" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable WAR
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmWar1760398" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Configure Low Power Features
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMLpwrArch" /t reg_DWORD /d "349525" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrGrPgSwFilterFunction" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCtrlMsDifrSwAsrParameters" /t reg_DWORD /d "5461" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCacheStatsOnD3" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Configure Paging Features
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPgCtrlParameters" /t reg_DWORD /d "1431655765" /f > nul 2>&1

	@echo Disable MSCG from RM side
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDwbMscg" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable BBX Inform
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableInforomBBX" /t reg_DWORD /d "15" /f > nul 2>&1

	@echo Prefer System Memory Contiguous
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PreferSystemMemoryContiguous" /t reg_DWORD /d "1" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "PreferSystemMemoryContiguous" /t REG_DWORD /d "1" /f

	@echo Configure SEC2 to not use profile with APM task enabled
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmSec2EnableApm" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable Slowdowns
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideIdleSlowdownSettings" /t reg_DWORD /d "0" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMClkSlowDown" /t reg_DWORD /d "71303168" /f > nul 2>&1

	@echo Disable bunch of Power features as WAR for Bug
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM2644249" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable 10 types of ACPI calls from the Resource Manager to the SBIOS.
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableACPI" /t reg_DWORD /d "1023" /f > nul 2>&1

	@echo Disable Native PCIE L1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNativePcieL1WarFlags" /t reg_DWORD /d "16" /f > nul 2>&1

	@echo Force Disable Clear perfmon and reset level when entering D4 state
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMResetPerfMonD4" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable the WDDM power saving mode for FBSR
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrWDDMMode" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable the File based power saving mode for Linux
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrFileMode" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable EDC replay
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PerfLevelSrc" /t reg_DWORD /d "8738" /f > nul 2>&1

	@echo Disable LPWR FSMs On Init
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpgStateOnInit" /t reg_DWORD /d "3" /f > nul 2>&1

	@echo Force never power off the MIOs
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmMIONoPowerOff" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Optimal Power For Padlink Pll
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableOptimalPowerForPadlinkPll" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable the power-off-dram-pll-when-unused feature
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmClkPowerOffDramPllWhenUnused" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable 6 Power Savings
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMOPSB" /t reg_DWORD /d "10914" /f > nul 2>&1

	@echo Force P0 State
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableDynamicPstate" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Async P-States
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableAsyncPstates" /t reg_DWORD /d "1" /f > nul 2>&1

	@echo Disable Slides MCLK
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SlideMCLK" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable UPHY Init sequence
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvlinkUPHYInitControl" /t reg_DWORD /d "16" /f > nul 2>&1

	@echo Disable Genoa System Power Controller
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmGpsGenoa" /t reg_DWORD /d "0" /f > nul 2>&1

	@echo Disable Control Panel Telemetry
	reg add "HKLM\Software\Nvidia Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t reg_DWORD /D 0 /f > nul 2>&1

	@echo Dont send Telemetry Data
	reg add "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t reg_DWORD /D 0 /f > nul 2>&1

	@echo Disable Registry Caching
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableRegistryCaching" /t REG_DWORD /d 15 /f >nul 2>&1

	@echo Enable D3 PC Latency
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "D3PCLatency" /t REG_DWORD /d 1 /f >nul 2>&1

	@echo Disable MS Hybrid
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableMsHybrid" /t REG_DWORD /d 0 /f >nul 2>&1

	@echo Disable Illegal Compstat Access
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableIntrIllegalCompstatAccess" /t REG_DWORD /d 1 /f >nul 2>&1

	@echo Set Panel Refresh Rate
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SetPanelRefreshRate" /t REG_DWORD /d 0 /f >nul 2>&1

	@echo Disable Non-Contiguous Allocation
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableNoncontigAlloc" /t REG_DWORD /d 1 /f >nul 2>&1

	@echo Unrestricted Application Clock Permissions
	nvidia-smi.exe -acp 0 > nul 2>&1

	@echo.
	@echo Successfully applied Nvidia Tweaks
	pause
	exit
)
if %errorlevel% equ 2 (
	@echo Revert DLSS Indicator
	reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v "ShowDlssIndicator" /t REG_DWORD /d 0 /f

	@echo Revert Nvidia Container Toggle to Context Menu
	reg delete "HKCR\DesktopBackground\Shell\NvidiaContainer" /f >nul 2>&1

	@echo Revert NVIDIA Driver Notification
	reg delete "HKCU\SOFTWARE\NVIDIA Corporation\Global\GFExperience" /v "NotifyNewDisplayUpdates" /t REG_DWORD /d 1 /f

	@echo Revert NVIDIA Control Panel Developer Settings
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "NvDevToolsVisible" /t REG_DWORD /d 0 /f

	@echo Revert NVIDIA Tray Icon
	reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvTray" /v "StartOnLogin" /t REG_DWORD /d 1 /f
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "HideXGpuTrayIcon" /t REG_DWORD /d 0 /f
	reg delete "HKLM\SOFTWARE\NVIDIA Corporation\Global\CoProcManager" /v "ShowTrayIcon" /t REG_DWORD /d 1 /f

	@echo Revert Display Power Savings
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 1 /f
	reg delete "HKLM\Software\NVIDIA Corporation\Global\NVTweak" /v "DisplayPowerSaving" /t REG_DWORD /d 1 /f

	@echo Revert Runtime Power Management
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableRuntimePowerManagement" /f > nul 2>&1

	@echo Revert GPU Performance Counters for All Users
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmProfilingAdminOnly" /t REG_DWORD /d "1" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "RmProfilingAdminOnly" /t REG_DWORD /d "1" /f > nul 2>&1

	@echo Revert DLSS Indicator
	reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NGXCore" /v "ShowDlssIndicator" /t REG_DWORD /d 1 /f > nul 2>&1

	@echo Revert HD Audio D3Cold
	reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "EnableHDAudioD3Cold" /t REG_DWORD /d 1 /f > nul 2>&1

	@echo Revert Hardware Fault Buffer
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHwFaultBuffer" /f > nul 2>&1

	@echo Revert Per Intr DPC Queueing
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePerIntrDPCQueueing" /f > nul 2>&1

	@echo Revert Engine Gatings
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElcg" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMBlcg" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpg" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSlcg" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMFspg" /f > nul 2>&1

	@echo Revert GC6
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Feature" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGC6Parameters" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDidleFeatureGC5" /f > nul 2>&1

	@echo Revert Hot Plug Support
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHotPlugSupportDisable" /f > nul 2>&1

	@echo Revert the Paged DMA mode for FBSR
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrPagedDMA" /f > nul 2>&1

	@echo Revert Post L2 Compression
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisablePostL2Compression" /f > nul 2>&1

	@echo Revert Logging
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmRcWatchdog" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLogonRC" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMIntrDetailedLogs" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMCtxswLog" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvLog" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMSuppressGPIOIntrErrLog" /f > nul 2>&1

	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" /v "LogDisableMasks" /f >Nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogWarningEntries" /f >Nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogPagingEntries" /f >Nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogEventEntries" /f >Nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\services\nvlddmkm\Parameters" /v "LogErrorEntries" /f >Nul 2>&1

	@echo Revert USB-C PMU event logging in RM
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMUsbcDebugMode" /f > nul 2>&1

	@echo Revert feature disablement
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableFeatureDisablement" /f > nul 2>&1

	@echo Revert breakpoint on DEBUG resource manager on RC errors
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmBreakonRC" /f > nul 2>&1

	@echo Revert SMC on a specific GPU
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDebugSetSMCMode" /f > nul 2>&1

	@echo Revert LRC coalescing
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableLRCCoalescing" /f > nul 2>&1

	@echo Revert I2C Nanny
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmEnableI2CNanny" /f > nul 2>&1

	@echo Revert Latency Tolerance
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrOverride" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMPcieLtrL12ThresholdOverride" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDeepL1EntryLatencyUsec" /f > nul 2>&1

	@echo Revert Pre OS Apps
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisablePreosapps" /f > nul 2>&1

	@echo Revert RmPerfLimitsOverride
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPerfLimitsOverride" /f > nul 2>&1

	@echo Revert RMGCOffFeature
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMGCOffFeature" /f > nul 2>&1

	@echo Revert ASPM
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideSupportChipsetAspm" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMDT" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableGpuASPMFlags" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableASPMAtLoad" /f > nul 2>&1

	@echo Revert Event Tracer
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMEnableEventTracer" /f > nul 2>&1

	@echo Revert Error Checks
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SkipSwStateErrChecks" /f > nul 2>&1

	@echo Revert Advanced Error Reporting
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMAERRForceDisable" /f > nul 2>&1

	@echo Revert OPSB Feature
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM580312" /f > nul 2>&1

	@echo Revert WAR
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmWar1760398" /f > nul 2>&1

	@echo Revert Low Power Features
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMLpwrArch" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrGrPgSwFilterFunction" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCtrlMsDifrSwAsrParameters" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmLpwrCacheStatsOnD3" /f > nul 2>&1

	@echo Revert Paging Features
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPgCtrlParameters" /f > nul 2>&1

	@echo Revert MSCG from RM side
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDwbMscg" /f > nul 2>&1

	@echo Revert BBX Inform
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableInforomBBX" /f > nul 2>&1

	@echo Revert Prefer System Memory Contiguous
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PreferSystemMemoryContiguous" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "PreferSystemMemoryContiguous" /f > nul 2>&1

	@echo Revert SEC2 to not use profile with APM task enabled
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmSec2EnableApm" /f > nul 2>&1

	@echo Revert Slowdowns
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmOverrideIdleSlowdownSettings" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMClkSlowDown" /f > nul 2>&1

	@echo Revert bunch of Power features as WAR for Bug
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RM2644249" /f > nul 2>&1

	@echo Revert 10 types of ACPI calls from the Resource Manager to the SBIOS.
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableACPI" /f > nul 2>&1

	@echo Revert Native PCIE L1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNativePcieL1WarFlags" /f > nul 2>&1

	@echo Revert Clear perfmon and reset level when entering D4 state
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMResetPerfMonD4" /f > nul 2>&1

	@echo Revert the WDDM power saving mode for FBSR
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrWDDMMode" /f > nul 2>&1

	@echo Revert the File based power saving mode for Linux
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmFbsrFileMode" /f > nul 2>&1

	@echo Revert EDC replay
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "PerfLevelSrc" /f > nul 2>&1

	@echo Revert LPWR FSMs On Init
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMElpgStateOnInit" /f > nul 2>&1

	@echo Revert Force never power off the MIOs
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmMIONoPowerOff" /f > nul 2>&1

	@echo Revert Optimal Power For Padlink Pll
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableOptimalPowerForPadlinkPll" /f > nul 2>&1

	@echo Revert the power-off-dram-pll-when-unused feature
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmClkPowerOffDramPllWhenUnused" /f > nul 2>&1

	@echo Revert 6 Power Savings
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMOPSB" /f > nul 2>&1

	@echo Revert P0 State
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableDynamicPstate" /f > nul 2>&1

	@echo Revert Async P-States
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "DisableAsyncPstates" /f > nul 2>&1

	@echo Revert Slides MCLK
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SlideMCLK" /f > nul 2>&1

	@echo Revert UPHY Init sequence
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMNvlinkUPHYInitControl" /f > nul 2>&1

	@echo Revert Genoa System Power Controller
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmGpsGenoa" /f > nul 2>&1

	@echo Revert Control Panel Telemetry
	reg delete "HKLM\Software\Nvidia Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /f > nul 2>&1

	@echo Revert Telemetry Data
	reg delete "HKLM\System\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t reg_DWORD /D 1 /f > nul 2>&1

	@echo Revert Registry Caching
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableRegistryCaching" /f >nul 2>&1

	@echo Revert D3 PC Latency
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "D3PCLatency" /f >nul 2>&1

	@echo Revert MS Hybrid
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "EnableMsHybrid" /f >nul 2>&1

	@echo Revert Illegal Compstat Access
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableIntrIllegalCompstatAccess" /f >nul 2>&1

	@echo Revert Panel Refresh Rate
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "SetPanelRefreshRate" /f >nul 2>&1

	@echo Revert Non-Contiguous Allocation
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMDisableNoncontigAlloc" /f >nul 2>&1

	@echo Revert Unrestricted Application Clock Permissions
	nvidia-smi.exe -acp 1 > nul 2>&1

	@echo.
	@echo Successfully applied Nvidia Tweaks
	pause
	exit
)