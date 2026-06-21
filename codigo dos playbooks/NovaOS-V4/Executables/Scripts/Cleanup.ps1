Get-ChildItem -Path "$env:TEMP" | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Force -Recurse
Remove-Item -Path "$([Environment]::GetFolderPath('Windows'))\Temp\*" -Force -Recurse
vssadmin delete shadows /all /quiet
wevtutil el | ForEach-Object {wevtutil cl "$_"} 2>&1 | Out-Null