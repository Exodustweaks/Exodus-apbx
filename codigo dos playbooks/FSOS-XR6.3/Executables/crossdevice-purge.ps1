$ErrorActionPreference = 'SilentlyContinue'
try { Import-Module Dism -ErrorAction SilentlyContinue } catch {}

try { Unregister-ScheduledTask -TaskName 'FSOS-CrossDeviceClean' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
try { Unregister-ScheduledTask -TaskName 'FSOSCrossDeviceResumeKill' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
$staleClean = Join-Path $env:windir 'FSOS\Tools\crossdevice-clean.ps1'
if (Test-Path $staleClean) { Remove-Item -Path $staleClean -Force }

$pfn = 'MicrosoftWindows.CrossDevice_cw5n1h2txyewy'
$winApps = Join-Path $env:ProgramFiles 'WindowsApps'

Get-Process -Name 'CrossDeviceResume' | Stop-Process -Force
Get-Process -Name 'CrossDeviceService' | Stop-Process -Force

if (Get-Command Set-NonRemovableAppsPolicy -ErrorAction SilentlyContinue) {
    try { Set-NonRemovableAppsPolicy -Online -PackageFamilyName $pfn -NonRemovable 0 -ErrorAction SilentlyContinue | Out-Null } catch {}
}

Get-AppxPackage -AllUsers 'MicrosoftWindows.CrossDevice*' | ForEach-Object { try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {} }
Get-AppxPackage 'MicrosoftWindows.CrossDevice*' | Remove-AppxPackage
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName }

$deprov = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.CrossDevice_cw5n1h2txyewy'
if (-not (Test-Path $deprov)) { New-Item -Path $deprov -Force | Out-Null }
$storeRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
foreach ($leaf in @('Applications','InboxApplications')) {
    $base = Join-Path $storeRoot $leaf
    if (Test-Path $base) {
        Get-ChildItem -Path $base | Where-Object { $_.PSChildName -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force }
    }
}
$eol = Join-Path $storeRoot 'EndOfLife'
if (Test-Path $eol) {
    Get-ChildItem -Path $eol | ForEach-Object {
        Get-ChildItem -Path $_.PSPath | Where-Object { $_.PSChildName -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force }
    }
}
if (Test-Path $winApps) {
    Get-ChildItem -Path $winApps -Directory -Force | Where-Object { $_.Name -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object {
        $p = $_.FullName
        & takeown.exe /F $p /R /D Y 2>$null | Out-Null
        & icacls.exe $p /grant 'administrators:F' /T /C 2>$null | Out-Null
        Remove-Item -Path $p -Recurse -Force
    }
}
$appRepo = Join-Path $env:ProgramData 'Microsoft\Windows\AppRepository'
if (Test-Path $appRepo) {
    Get-ChildItem -Path $appRepo -Force | Where-Object { $_.Name -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object {
        $p = $_.FullName
        & takeown.exe /F $p /R /D Y 2>$null | Out-Null
        & icacls.exe $p /grant 'administrators:F' /T /C 2>$null | Out-Null
        Remove-Item -Path $p -Recurse -Force
    }
    $pkgRepo = Join-Path $appRepo 'Packages'
    if (Test-Path $pkgRepo) {
        Get-ChildItem -Path $pkgRepo -Directory -Force | Where-Object { $_.Name -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object {
            $p = $_.FullName
            & takeown.exe /F $p /R /D Y 2>$null | Out-Null
            & icacls.exe $p /grant 'administrators:F' /T /C 2>$null | Out-Null
            Remove-Item -Path $p -Recurse -Force
        }
    }
}
$csv = & schtasks.exe /Query /FO CSV 2>$null | ConvertFrom-Csv
foreach ($t in $csv) {
    $n = $t.TaskName
    if ($n -and ($n -match 'CrossDeviceResume')) { & schtasks.exe /Delete /TN $n /F 2>$null | Out-Null }
}
foreach ($r in @((Join-Path $env:windir 'System32\Tasks'), (Join-Path $env:windir 'SysWOW64\Tasks'))) {
    if (Test-Path $r) {
        Get-ChildItem -Path $r -Recurse -File -Force | Where-Object { $_.Name -match 'CrossDeviceResume' } | ForEach-Object { Remove-Item -Path $_.FullName -Force }
    }
}
exit 0
