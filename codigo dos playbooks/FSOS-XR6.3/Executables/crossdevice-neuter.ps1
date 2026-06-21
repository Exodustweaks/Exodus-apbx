$ErrorActionPreference = 'SilentlyContinue'
try { Import-Module Dism -ErrorAction SilentlyContinue } catch {}

$winApps = Join-Path $env:ProgramFiles 'WindowsApps'

Get-Process -Name 'CrossDeviceResume' | Stop-Process -Force
Get-Process -Name 'CrossDeviceService' | Stop-Process -Force

Get-AppxPackage -AllUsers 'MicrosoftWindows.CrossDevice*' | ForEach-Object { try { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {} }
Get-AppxPackage 'MicrosoftWindows.CrossDevice*' | Remove-AppxPackage
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName }
$deprov = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\MicrosoftWindows.CrossDevice_cw5n1h2txyewy'
if (-not (Test-Path $deprov)) { New-Item -Path $deprov -Force | Out-Null }
if (Test-Path $winApps) {
    Get-ChildItem -Path $winApps -Directory -Force | Where-Object { $_.Name -like 'MicrosoftWindows.CrossDevice*' } | ForEach-Object {
        $p = $_.FullName
        & takeown.exe /F $p /R /D Y 2>$null | Out-Null
        & icacls.exe $p /grant 'administrators:F' /T /C 2>$null | Out-Null
        Remove-Item -Path $p -Recurse -Force
    }
}

$stub = $null
$cands = @()
if ($PSScriptRoot) { $cands += (Join-Path $PSScriptRoot 'cdr-stub.exe') }
$cands += (Join-Path (Get-Location).Path 'cdr-stub.exe')
$cands += '.\cdr-stub.exe'
foreach ($c in $cands) { if ($c -and (Test-Path $c)) { $stub = (Resolve-Path $c).Path; break } }
if ($stub) {
    $roots = @((Join-Path $env:windir 'SystemApps'), (Join-Path $env:windir 'System32'))
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem -Path $root -Recurse -File -Force -Filter 'CrossDeviceResume.exe' -ErrorAction SilentlyContinue | ForEach-Object {
            $f = $_.FullName
            try {
                & takeown.exe /F $f 2>$null | Out-Null
                & icacls.exe $f /grant 'administrators:F' /C 2>$null | Out-Null
                Copy-Item -Path $stub -Destination $f -Force -ErrorAction SilentlyContinue
            } catch {}
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
        Get-ChildItem -Path $r -Recurse -Directory -Force | Where-Object { $_.Name -eq 'Resume' } | ForEach-Object { if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) { Remove-Item -LiteralPath $_.FullName -Recurse -Force } }
    }
}
exit 0
