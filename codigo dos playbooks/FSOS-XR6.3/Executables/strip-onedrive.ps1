$ErrorActionPreference = 'SilentlyContinue'
$paths = @("$env:SystemRoot\System32\OneDriveSetup.exe","$env:SystemRoot\SysWOW64\OneDriveSetup.exe")
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
Get-ChildItem 'HKU:\' | ForEach-Object {
    $k = $_.PSChildName
    if (Test-Path "HKU:\$k\Volatile Environment") {
        $reg = "HKU:\$k\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
        $str = (Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue).UninstallString
        if ($str) { $paths = @([IO.Path]::GetDirectoryName($str)) + $paths }
        Remove-ItemProperty -Path "HKU:\$k\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKU:\$k\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" -ErrorAction SilentlyContinue
        Remove-Item -Path $reg -Force -ErrorAction SilentlyContinue
    }
}
$paths | Select-Object -Unique | Where-Object { Test-Path $_ } | ForEach-Object {
    Start-Process -FilePath $_ -ArgumentList "/uninstall" -Wait -NoNewWindow
}
Get-ChildItem "$env:SystemDrive\Users" -Directory -Force | ForEach-Object {
    Remove-Item (Join-Path $_.FullName "AppData\Local\Microsoft\OneDrive") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $_.FullName "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk") -Force -ErrorAction SilentlyContinue
}
[Microsoft.Win32.Registry]::SetValue("HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}","System.IsPinnedToNameSpaceTree",0,[Microsoft.Win32.RegistryValueKind]::DWord)
@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers') | ForEach-Object {
    if (Test-Path $_) {
        Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match 'OneDrive' } | ForEach-Object {
            Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
