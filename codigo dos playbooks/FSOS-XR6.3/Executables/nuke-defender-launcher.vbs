Set sh = CreateObject("WScript.Shell")
winDir = sh.ExpandEnvironmentStrings("%WINDIR%")
sh.Run "powershell.exe -NoP -EP Bypass -WindowStyle Hidden -File """ & winDir & "\FSOS\Tools\nuke-defender-files.ps1""", 0, False
