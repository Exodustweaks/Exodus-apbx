@echo off

dism >nul 2>&1 || (echo ^<Run the script as administrator^> && pause>nul && cls&exit)
title Configure RMPowerFeature
color B

for /L %%i in (0,1,9) do (
    for /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000%%i" /v "ProviderName" 2^>nul') do (
	if /i "%%b"=="NVIDIA" (
		set G=000%%i
		)
	)
)

choice -c 12 -n -m "[1] Add PowerFeature | [2] Remove PowerFeature"
if %errorlevel% equ 1 (
	cls
	@echo Disable Software Slowdown
	@echo Disable Peak Power Slowdown
	@echo Disable Engine Level Clock Gating
	@echo Disable Engine Level Power Gating
	@echo Disable PCIE Deep L1
	@echo Disable PCIE CLKREQ
	@echo Disable Deep Idle
	@echo Disable FB ACPD
	@echo Disable Dual Pixel
	@echo Disable Block Level Clock Gating 2
	@echo Disable Adaptive Power
	@echo Disable Power Rail Gating
	@echo Disable Power Rail Gating Predictive
	@echo Disable Floorsweep Power Gating
	@echo Disable Floorsweep Power Gating 2
	@echo Disable Operation Mode
	@echo Disable Second Level Clock Gating
	@echo Disable NDIV Sliding
	@echo Disable NVVDD PSI
	@echo Disable GC6 ROMLESS
	@echo Disable GC6 ROM
	@echo Disable DIDLE SSC
	@echo Disable DIDLE OS
	@echo Disable PCIE L1 Substates
	@echo Disable Low Power Oneshot
	@echo Disable RP Power Gating
	@echo Disable IST Clock Gating
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPowerFeature" /t REG_DWORD /d "1430607189" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPowerFeature2" /t REG_DWORD /d "89478485" /f > nul 2>&1
	@echo.
	@echo Watch Temps!!!!
	pause
	exit
)
if %errorlevel% equ 2 (
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPowerFeature" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmPowerFeature2" /f > nul 2>&1
	exit
)

exit