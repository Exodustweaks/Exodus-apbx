@echo off

>nul fltmc || (
    powershell -c "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -c "$f='%~f0'; $lines=Get-Content $f; $idx=$lines.IndexOf(':PS'); iex ($lines[($idx+1)..($lines.Length-1)] -join [Environment]::NewLine)"
exit /b

:PS
Import-RegState -JsonPath "$env:WinDir\RapidScripts\MMCSS.json" *>$null;
$mmcss = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile";
Set-RegistryValue -Path $mmcss -Name "SystemResponsiveness" -Type DWORD -Value 10;
        
Set-RegistryValue -Path "$mmcss\Tasks\Audio" -Name "Scheduling Category" -Type String -Value "Medium";
Set-RegistryValue -Path "$mmcss\Tasks\Audio" -Name "Priority" -Type DWORD -Value 1;
Set-RegistryValue -Path "$mmcss\Tasks\Audio" -Name "Priority When Yielded" -Type DWORD -Value 1;

Set-RegistryValue -Path "$mmcss\Tasks\Pro Audio" -Name "Scheduling Category" -Type String -Value "Medium";
Set-RegistryValue -Path "$mmcss\Tasks\Pro Audio" -Name "Priority" -Type DWORD -Value 1;
Set-RegistryValue -Path "$mmcss\Tasks\Pro Audio" -Name "Priority When Yielded" -Type DWORD -Value 1;

Set-RegistryValue -Path "$mmcss\Tasks\Games" -Name "Scheduling Category" -Type String -Value "High";

if (!(Test-Laptop)) {
    Set-RegistryValue -Path $mmcss -Name "NetworkThrottlingIndex" -Type DWORD -Value 4294967295;
    Set-RegistryValue -Path $mmcss -Name "SchedulerPeriod" -Type DWORD -Value 1000000;
    Set-RegistryValue -Path $mmcss -Name "LazyModeTimeout" -Type DWORD -Value 25000
}

Write-Host "MMCSS has been successfully configured."
pause
exit