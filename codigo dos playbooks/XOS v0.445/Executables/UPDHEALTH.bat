@echo off
setlocal EnableDelayedExpansion

for /f "usebackq tokens=7 delims=\" %%e in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /d /f "Update Health Tools" /s 2^>nul ^| findstr /i /c:"CurrentVersion\Uninstall\\"`) do set "GUID=%%e"
for /f "usebackq tokens=4 delims=\" %%e in (`reg query "HKCR\Installer\Products" /d /f "Update Health Tools" /s 2^>nul ^| findstr /i /c:"Installer\Products\\"`) do set "ProdID=%%e"

if "!GUID!"=="" goto :Prod
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\!GUID!" /f 2>nul

:Prod
if "!ProdID!"=="" exit /b 0

for /f "usebackq delims=" %%e in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes" /d /f "!ProdID!" /s ^| findstr /i /c:"Installer\UpgradeCodes\\"`) do reg delete "%%e" /f 2>nul
reg delete "HKCR\Installer\Products\!ProdID!" /f 2>nul
reg delete "HKCR\Installer\Features\!ProdID!" /f 2>nul
for /f "usebackq delims=" %%e in (`reg query "HKCR\Installer\UpgradeCodes" /d /f "!ProdID!" /s ^| findstr /i /c:"Installer\UpgradeCodes\\"`) do reg delete "%%e" /f 2>nul
for /f "usebackq delims=" %%e in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" /d /f "!ProdID!" /s ^| findstr /i /c:"S-1-5-18\Components\\"`) do reg delete "%%e" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\!ProdID!" /f 2>nul

exit /b 0
