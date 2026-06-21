$ErrorActionPreference = 'SilentlyContinue'

$personalizationMarker = Join-Path $env:windir 'FSOS\.personalization-applied'
if (Test-Path $personalizationMarker) {
    $global:LASTEXITCODE = 0
    exit 0
}

$updRoot = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'

function Invoke-Silent {
    param([string]$FilePath, [string]$Arguments)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit()
        return $p.ExitCode
    } catch {
        return -1
    }
}

function Stop-EdgeProcesses {
    foreach ($pname in @('msedge','MicrosoftEdgeUpdate','MicrosoftEdge','msedgewebview2','setup','identity_helper','msedge_proxy','MicrosoftEdgeUpdateBroker','MicrosoftEdgeUpdateOnDemand','MicrosoftEdgeUpdateComRegisterShell64','msedgeupdate')) {
        Get-Process -Name $pname -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

foreach ($task in @(
    '\MicrosoftEdgeUpdateTaskMachineCore',
    '\MicrosoftEdgeUpdateTaskMachineUA',
    '\MicrosoftEdgeUpdateBrowserReplacementTask',
    '\MicrosoftEdgeUpdateTaskMachineCoreSystem'
)) {
    try { Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null } catch {}
    try { Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue } catch {}
}

foreach ($svc in @('edgeupdate','edgeupdatem','MicrosoftEdgeElevationService')) {
    try { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue } catch {}
    & sc.exe config $svc start= disabled 2>&1 | Out-Null
    & sc.exe delete $svc 2>&1 | Out-Null
}

Stop-EdgeProcesses
Start-Sleep -Seconds 2
Stop-EdgeProcesses

[Microsoft.Win32.Registry]::SetValue('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev', 'AllowUninstall', 1, [Microsoft.Win32.RegistryValueKind]::DWord)
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge' -Name 'NoRemove' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update' -Name 'NoRemove' -ErrorAction SilentlyContinue

$edgePkg = Get-AppxPackage -AllUsers -Name 'Microsoft.MicrosoftEdge*' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*WebView*' }
foreach ($pkg in $edgePkg) {
    try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {}
}

$edgeDirs = @(
    "$env:ProgramFiles\Microsoft\Edge",
    "${env:ProgramFiles(x86)}\Microsoft\Edge"
)
foreach ($d in $edgeDirs) {
    if ($d -and (Test-Path $d)) {
        $appDir = Join-Path $d 'Application'
        if (Test-Path $appDir) {
            $ver = Get-ChildItem $appDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.' } | Select-Object -First 1
            if ($ver) {
                $setupExe = Join-Path $ver.FullName 'Installer\setup.exe'
                if (Test-Path $setupExe) {
                    Invoke-Silent -FilePath $setupExe -Arguments '--uninstall --system-level --verbose-logging --force-uninstall' | Out-Null
                    Stop-EdgeProcesses
                    Start-Sleep -Seconds 1
                }
            }
        }
    }
}

$csPath = "$updRoot\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
if (Test-Path $csPath) {
    Remove-ItemProperty -Path $csPath -Name 'experiment_control_labels' -ErrorAction SilentlyContinue
    $fakeDir = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    New-Item -ItemType Directory -Path $fakeDir -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType File -Path "$fakeDir\MicrosoftEdge.exe" -Force -ErrorAction SilentlyContinue | Out-Null
    $prevWinDir = $env:windir; $env:windir = ''
    $exe = (Get-ItemProperty -Path $csPath -ErrorAction SilentlyContinue).UninstallString
    $uargs = (Get-ItemProperty -Path $csPath -ErrorAction SilentlyContinue).UninstallArguments
    if ($exe -and $uargs -and (Test-Path $exe)) {
        Invoke-Silent -FilePath $exe -Arguments "$uargs --force-uninstall --delete-profile" | Out-Null
    }
    $env:windir = $prevWinDir
    Stop-EdgeProcesses
}

$unCmd = (Get-ItemProperty -Path $updRoot -ErrorAction SilentlyContinue).UninstallCmdLine
if ($unCmd) {
    $parts = $unCmd -split '"', 3
    if ($parts.Count -ge 3 -and $parts[1]) {
        $uExe = $parts[1]
        $uArgs = $parts[2].Trim()
        if (Test-Path $uExe) {
            Invoke-Silent -FilePath $uExe -Arguments $uArgs | Out-Null
        }
    } else {
        $tokens = $unCmd.Split(' ', 2)
        if ($tokens.Count -ge 1 -and (Test-Path $tokens[0])) {
            $uArgs = if ($tokens.Count -gt 1) { $tokens[1] } else { '' }
            Invoke-Silent -FilePath $tokens[0] -Arguments $uArgs | Out-Null
        }
    }
    Stop-EdgeProcesses
}

$desktopPaths = @("$env:ProgramData\Microsoft\Windows\Start Menu\Programs","$env:PUBLIC\Desktop")
Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notin @('Public','Default','Default User','All Users','WDAGUtilityAccount')
} | ForEach-Object {
    $desktopPaths += (Join-Path $_.FullName 'Desktop')
}
foreach ($p in $desktopPaths) {
    Remove-Item (Join-Path $p 'Microsoft Edge.lnk') -Force -ErrorAction SilentlyContinue
}

foreach ($d in $edgeDirs) {
    if ($d -and (Test-Path $d)) {
        Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$edgeUpdateDirs = @(
    "$env:ProgramFiles\Microsoft\EdgeUpdate",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate",
    "$env:ProgramFiles\Microsoft\EdgeCore",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeCore"
)
foreach ($d in $edgeUpdateDirs) {
    if ($d -and (Test-Path $d)) {
        Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$ldata = $env:LOCALAPPDATA
if (-not $ldata) { $ldata = "$env:USERPROFILE\AppData\Local" }
foreach ($u in (Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Public','Default','Default User','All Users','WDAGUtilityAccount') })) {
    foreach ($sub in @('Microsoft\Edge','Microsoft\EdgeUpdate','Microsoft\EdgeCore')) {
        $p = Join-Path $u.FullName "AppData\Local\$sub"
        if (Test-Path $p) {
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

foreach ($k in @(
    'HKLM:\SOFTWARE\Microsoft\Edge',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update'
)) {
    if (Test-Path $k) {
        Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($task in @(
    '\MicrosoftEdgeUpdateTaskMachineCore',
    '\MicrosoftEdgeUpdateTaskMachineUA',
    '\MicrosoftEdgeUpdateBrowserReplacementTask'
)) {
    $tn = $task.TrimStart('\')
    $tf = "$env:windir\System32\Tasks\$tn"
    if (Test-Path $tf) {
        & takeown.exe /F $tf /A 2>&1 | Out-Null
        & icacls.exe $tf /grant Administrators:F 2>&1 | Out-Null
        Remove-Item -Path $tf -Force -ErrorAction SilentlyContinue
    }
}

$liveUserKeys = @()
try {
    $liveUserKeys = Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | Where-Object {
        ($_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$') -or $_.PSChildName -match '^AME_UserHive_'
    }
} catch {}

foreach ($userKey in $liveUserKeys) {
    $sid = $userKey.PSChildName
    $hivePath = "Registry::HKU\$sid"
    $appData = $null
    if ($sid -match '^AME_UserHive_') {
        $appData = "$env:SystemDrive\Users\Default\AppData\Roaming"
    } else {
        try {
            $sf = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            $appData = (Get-ItemProperty -Path $sf -Name 'AppData' -ErrorAction SilentlyContinue).AppData
        } catch {}
        if ([string]::IsNullOrEmpty($appData) -or -not (Test-Path $appData)) {
            try {
                $profileList = "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
                $profPath = (Get-ItemProperty -Path $profileList -Name 'ProfileImagePath' -ErrorAction SilentlyContinue).ProfileImagePath
                if ($profPath -and (Test-Path $profPath)) {
                    $appData = Join-Path $profPath 'AppData\Roaming'
                }
            } catch {}
        }
    }
    if (-not [string]::IsNullOrEmpty($appData) -and (Test-Path $appData)) {
        $taskBarDir = Join-Path $appData 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
        if (Test-Path $taskBarDir) {
            Get-ChildItem -Path $taskBarDir -File -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '^Microsoft Edge.*\.lnk$' -or $_.Name -ieq 'Edge.lnk'
            } | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $implicitDir = Join-Path $taskBarDir 'ImplicitAppShortcuts'
        if (Test-Path $implicitDir) {
            Get-ChildItem -Path $implicitDir -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '^Microsoft Edge.*\.lnk$' -or $_.Name -ieq 'Edge.lnk'
            } | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    $taskband = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
    if (Test-Path $taskband) {
        try { Remove-ItemProperty -Path $taskband -Name 'Favorites' -Force -ErrorAction SilentlyContinue } catch {}
        try { Remove-ItemProperty -Path $taskband -Name 'FavoritesResolve' -Force -ErrorAction SilentlyContinue } catch {}
        try { Remove-ItemProperty -Path $taskband -Name 'Pinned' -Force -ErrorAction SilentlyContinue } catch {}
        try { Set-ItemProperty -Path $taskband -Name 'FavoritesChanges' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    }
    $auxPins = "$taskband\AuxilliaryPins"
    if (Test-Path $auxPins) {
        try { Set-ItemProperty -Path $auxPins -Name 'EdgePin' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    }
}

try {
    $sig = '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);'
    $type = Add-Type -MemberDefinition $sig -Name 'FSOSEdgeShellRefresh' -Namespace 'FSOS' -PassThru -ErrorAction SilentlyContinue
    if ($type) {
        $type::SHChangeNotify(0x08000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)
    }
} catch {}
