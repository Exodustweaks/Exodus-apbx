reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\FTH\State" /f
Rundll32.exe fthsvc.dll,FthSysprepSpecialize