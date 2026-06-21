$ErrorActionPreference = 'SilentlyContinue'

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

function Stop-WebView2Processes {
    foreach ($pname in @('msedgewebview2','identity_helper','msedge_proxy','setup')) {
        Get-Process -Name $pname -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

Stop-WebView2Processes
Start-Sleep -Seconds 1
Stop-WebView2Processes

$systemSetups = @()
foreach ($base in @("${env:ProgramFiles(x86)}\Microsoft\EdgeWebView\Application", "$env:ProgramFiles\Microsoft\EdgeWebView\Application")) {
    if ($base -and (Test-Path $base)) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.' } | ForEach-Object {
            $s = Join-Path $_.FullName 'Installer\setup.exe'
            if (Test-Path $s) { $systemSetups += $s }
        }
    }
}
foreach ($s in $systemSetups) {
    Invoke-Silent -FilePath $s -Arguments '--uninstall --msedgewebview --system-level --verbose-logging --force-uninstall' | Out-Null
    Stop-WebView2Processes
    Start-Sleep -Seconds 1
}

foreach ($unKey in @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView'
)) {
    if (Test-Path $unKey) {
        $us = (Get-ItemProperty -Path $unKey -ErrorAction SilentlyContinue).UninstallString
        if ($us) {
            $exe = $null
            $rest = ''
            if ($us -match '^"([^"]+)"\s*(.*)$') {
                $exe = $matches[1]
                $rest = $matches[2]
            } else {
                $tok = $us.Split(' ', 2)
                $exe = $tok[0]
                if ($tok.Count -gt 1) { $rest = $tok[1] }
            }
            if ($exe -and (Test-Path $exe)) {
                if ($rest -notmatch 'force-uninstall') { $rest = ($rest + ' --force-uninstall').Trim() }
                Invoke-Silent -FilePath $exe -Arguments $rest | Out-Null
                Stop-WebView2Processes
            }
        }
    }
}

$userDirs = Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notin @('Public','Default','Default User','All Users','WDAGUtilityAccount')
}
foreach ($u in $userDirs) {
    $base = Join-Path $u.FullName 'AppData\Local\Microsoft\EdgeWebView\Application'
    if (Test-Path $base) {
        Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.' } | ForEach-Object {
            $s = Join-Path $_.FullName 'Installer\setup.exe'
            if (Test-Path $s) {
                Invoke-Silent -FilePath $s -Arguments '--uninstall --msedgewebview --user-level --verbose-logging --force-uninstall' | Out-Null
                Stop-WebView2Processes
            }
        }
    }
}

foreach ($d in @(
    "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView",
    "$env:ProgramFiles\Microsoft\EdgeWebView"
)) {
    if ($d -and (Test-Path $d)) {
        Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    }
}
foreach ($u in $userDirs) {
    $p = Join-Path $u.FullName 'AppData\Local\Microsoft\EdgeWebView'
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($k in @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\ClientState\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedgewebview2.exe'
)) {
    if (Test-Path $k) {
        Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($pn in @('StartMenuExperienceHost','SearchHost','SearchApp')) {
    Get-Process -Name $pn -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
$shellProfiles = @('C:\Users\Default')
Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notin @('Default User','Public','All Users','Default','WDAGUtilityAccount')
} | ForEach-Object { $shellProfiles += $_.FullName }
foreach ($sp in $shellProfiles) {
    foreach ($pkg in @('Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy','MicrosoftWindows.Client.CBS_cw5n1h2txyewy','Microsoft.Windows.Search_cw5n1h2txyewy')) {
        $pkgBase = Join-Path $sp ('AppData\Local\Packages\' + $pkg)
        foreach ($sub in @('LocalState','TempState','LocalCache')) {
            $d = Join-Path $pkgBase $sub
            if (Test-Path $d) {
                Get-ChildItem -Path $d -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

$global:LASTEXITCODE = 0
