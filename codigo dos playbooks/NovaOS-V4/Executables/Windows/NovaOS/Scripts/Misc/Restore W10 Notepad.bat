@echo off
reg add "HKCR\*\OpenWithList\notepad.exe" /f >nul 2>&1
reg delete "HKCR\Applications\notepad.exe" /v "NoOpenWith" /f >nul 2>&1
reg add "HKCR\.inf" /ve /t REG_SZ /d "inffile" /f >nul 2>&1
reg add "HKCR\.ini" /ve /t REG_SZ /d "inifile" /f >nul 2>&1
reg add "HKCR\.log" /ve /t REG_SZ /d "txtfilelegacy" /f >nul 2>&1
reg add "HKCR\.scp" /ve /t REG_SZ /d "txtfilelegacy" /f >nul 2>&1
reg add "HKCR\.txt\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\System32\notepad.exe,-470" /f >nul 2>&1
reg add "HKCR\.txt\ShellNew" /v "NullFile" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\.wtx" /ve /t REG_SZ /d "txtfilelegacy" /f >nul 2>&1
reg add "HKCR\Applications\notepad.exe\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\imageres.dll,-102" /f >nul 2>&1
reg add "HKCR\Microsoft.PowerShellScript.1\Shell\Edit\Command" /ve /t REG_SZ /d "\"C:\Windows\System32\notepad.exe\" \"%%1\"" /f
reg add "HKCR\inffile" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\System32\setupapi.dll,-2000" /f >nul 2>&1
reg add "HKCR\inffile" /ve /t REG_SZ /d "Setup Information" /f >nul 2>&1
reg add "HKCR\inffile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\imageres.dll,-69" /f >nul 2>&1
reg add "HKCR\inffile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\notepad.exe %%1" /f >nul 2>&1
reg add "HKCR\inifile" /v "EditFlags" /t REG_DWORD /d 2097152 /f >nul 2>&1
reg add "HKCR\inifile" /v "FriendlyTypeName" /t REG_SZ /d "@%%SystemRoot%%\System32\shell32.dll,-10151" /f >nul 2>&1
reg add "HKCR\inifile" /ve /t REG_SZ /d "Configuration Settings" /f >nul 2>&1
reg add "HKCR\inifile\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\imageres.dll,-69" /f >nul 2>&1
reg add "HKCR\inifile\Shell\Edit\Command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\notepad.exe %%1" /f >nul 2>&1
reg add "HKCR\inifile\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\notepad.exe %%1" /f >nul 2>&1
reg add "HKCR\txtfilelegacy" /v "EditFlags" /t REG_DWORD /d 2162688 /f >nul 2>&1
reg add "HKCR\txtfilelegacy" /v "FriendlyTypeName" /t REG_EXPAND_SZ /d "@%%SystemRoot%%\System32\notepad.exe,-469" /f >nul 2>&1
reg add "HKCR\txtfilelegacy" /ve /t REG_SZ /d "Text Document" /f >nul 2>&1
reg add "HKCR\txtfilelegacy\DefaultIcon" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\imageres.dll,-102" /f >nul 2>&1
reg add "HKCR\txtfilelegacy\Shell\Open\Command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\notepad.exe %%1" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Notepad" /v "ShowStoreBanner" /t REG_DWORD /d 0 /f >nul 2>&1
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.WindowsNotepad' | Remove-AppxPackage" >nul 2>&1
exit