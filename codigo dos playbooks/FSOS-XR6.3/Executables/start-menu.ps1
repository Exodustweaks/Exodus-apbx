$ErrorActionPreference = 'SilentlyContinue'

$personalizationMarker = Join-Path $env:windir 'FSOS\.personalization-applied'
if (Test-Path $personalizationMarker) {
    $global:LASTEXITCODE = 0
    exit 0
}

Get-Process -Name 'StartMenuExperienceHost' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$liveUserKeys = @()
try {
    $liveUserKeys = Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | Where-Object {
        ($_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$') -or $_.PSChildName -match '^AME_UserHive_'
    }
} catch {}

foreach ($userKey in $liveUserKeys) {
    $sid = $userKey.PSChildName
    $hivePath = "Registry::HKU\$sid"
    $isDefault = $sid -match '^AME_UserHive_'

    try {
        $runOnce = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        if (-not (Test-Path $runOnce)) {
            New-Item -Path $runOnce -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $cleanupCmd = 'cmd.exe /c del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml" 2>nul'
        Set-ItemProperty -Path $runOnce -Name 'FSOSTaskbarLayoutCleanup' -Value $cleanupCmd -Type String -Force -ErrorAction SilentlyContinue
    } catch {}

    if (-not $isDefault) {
        try {
            $cloudStore = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"
            if (Test-Path $cloudStore) {
                Get-ChildItem -Path $cloudStore -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'start\.tilegrid' } | ForEach-Object {
                    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {}
    }

    try {
        $startKey = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\Start"
        if (Test-Path $startKey) {
            Remove-ItemProperty -Path $startKey -Name 'Config' -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}
