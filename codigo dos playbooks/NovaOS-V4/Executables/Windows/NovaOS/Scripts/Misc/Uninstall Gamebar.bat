@echo off
Powershell.exe -command "& {Get-AppxPackage *Microsoft.XboxApp* | Remove-AppxPackage} >nul 2>&1
Powershell.exe -command "& {Get-AppxPackage *Microsoft.XboxGamingOverlay* | Remove-AppxPackage} >nul 2>&1
Powershell.exe -command "& {Get-AppxPackage *Microsoft.XboxIdentityProvider* | Remove-AppxPackage} >nul 2>&1
Powershell.exe -command "& {Get-AppxPackage *Microsoft.Xbox.TCUI* | Remove-AppxPackage} >nul 2>&1
Powershell.exe -command "& {Get-AppxPackage *Microsoft.GamingApp* | Remove-AppxPackage} >nul 2>&1
Powershell.exe -command "& {Get-AppxPackage *Microsoft.GamingServices* | Remove-AppxPackage} >nul 2>&1
echo Xbox Game Bar has been uninstalled
EXIT