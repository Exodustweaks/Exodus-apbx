@echo off
SETLOCAL EnableDelayedExpansion

taskkill /f /im OneDrive.exe > nul 2>&1
for %%a in (
	"%windir%\System32\OneDriveSetup.exe"
	"%windir%\SysWOW64\OneDriveSetup.exe"
) do (
	if exist "%%a" (
		"%%a" /uninstall > nul 2>&1
	)
)


taskkill /f /im OneDrive.App.exe > nul 2>&1
rmdir /q /s "%ProgramData%\Microsoft OneDrive" > nul 2>&1
rmdir /q /s "%ProgramFiles%\Microsoft OneDrive" > nul 2>&1
rmdir /q /s "%LOCALAPPDATA%\Microsoft\OneDrive" > nul 2>&1

for /f "usebackq delims=" %%a in (`dir /b /a:d "%SystemDrive%\Users"`) do (
	rmdir /q /s "%SystemDrive%\Users\%%a\AppData\Local\Microsoft\OneDrive" > nul 2>&1
	rmdir /q /s "%SystemDrive%\Users\%%a\OneDrive" > nul 2>&1
	del /q /f "%SystemDrive%\Users\%%a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" > nul 2>&1
	del /q /f "%SystemDrive%\Users\%%a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive*.lnk" > nul 2>&1
)
del /q /f "%ProgramData%\Microsoft\Windows\Start Menu\Programs\OneDrive*.lnk" > nul 2>&1

for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager" ^| findstr /i /c:"OneDrive"`) do reg delete "%%a" /f > nul 2>&1

for /f "tokens=2 delims=\" %%a in ('schtasks /query /fo list /v ^| findstr /c:"\OneDrive Reporting Task" /c:"\OneDrive Standalone Update Task"') do (
	schtasks /delete /tn "%%a" /f > nul 2>&1
)

for /f "usebackq delims=" %%s in (`reg query HKU 2^>nul ^| findstr /r "S-1-5-21-[0-9]*-[0-9]*-[0-9]*$"`) do (
	for /f "usebackq delims=" %%a in (`reg query "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
		reg delete "%%a" /f > nul 2>&1
	)
	for /f "usebackq delims=" %%a in (`reg query "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
		reg delete "%%a" /f > nul 2>&1
	)
	for /f "usebackq delims=" %%a in (`reg query "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
		reg delete "%%a" /f > nul 2>&1
	)
	for /f "usebackq delims=" %%a in (`reg query "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
		reg delete "%%a" /f > nul 2>&1
	)
	reg add "%%s\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f > nul 2>&1
	reg add "%%s\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f > nul 2>&1
	reg delete "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
	reg delete "%%s\Environment" /v "OneDrive" /f > nul 2>&1
	reg delete "%%s\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f > nul 2>&1
)

exit /b