@echo off
reg add "HKLM\System\CurrentControlSet\Services\spooler" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\printworkflowusersvc" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\stisvc" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\PrintNotify" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\usbprint" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\McpManagementService" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\PrintScanBrokerService" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\System\CurrentControlSet\Services\PrintDeviceConfigurationService" /v "Start" /t REG_DWORD /d 2 /f
exit
