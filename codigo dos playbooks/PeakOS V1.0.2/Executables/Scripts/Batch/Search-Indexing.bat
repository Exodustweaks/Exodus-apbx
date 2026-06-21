reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v PreventIndexOnBattery /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex" /v RespectPowerModes /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" /v WholeFileSystem /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" /v SystemFolders /t REG_DWORD /d 0 /f
::reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" /v AutoWildCard /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" /v EnableNaturalQuerySyntax /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences" /v ArchivedFiles /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\PrimaryProperties\UnindexedLocations" /v SearchOnly /t REG_DWORD /d 1 /f
sc stop wsearch
sc config wsearch start=disabled