reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-BackgroundTaskInfrastructure/Diagnostic" /v Enabled /t REG_DWORD /d 0 /f


::reg add "HKLM\SOFTWARE\Microsoft\wbem\Tracing" /v Task logging /t REG_DWORD /d 0 /f