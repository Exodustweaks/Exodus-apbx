@echo off

dism >nul 2>&1 || (echo ^<Run the script as administrator^> && pause>nul && cls&exit)
title Configure HDCP
color B

for /L %%i in (0,1,9) do (
    for /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000%%i" /v "ProviderName" 2^>nul') do (
	if /i "%%b"=="NVIDIA" (
		set G=000%%i
		)
	)
)

choice -c 12 -n -m "[1] Disable HDCP | [2] Enable HDCP"
if %errorlevel% equ 1 (
	cls
	@echo Disable HDCP
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f > nul 2>&1
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHdcp22" /t REG_DWORD /d "1" /f > nul 2>&1
	@echo.
	@echo Disabled HDCP
	pause
)
if %errorlevel% equ 2 (
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RMHdcpKeyglobZero" /f > nul 2>&1
	reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\%G%" /v "RmDisableHdcp22" /f > nul 2>&1

)

exit