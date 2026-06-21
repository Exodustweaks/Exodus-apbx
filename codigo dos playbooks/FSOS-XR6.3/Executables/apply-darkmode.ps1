$ErrorActionPreference = 'SilentlyContinue'

$personalizationMarker = Join-Path $env:windir 'FSOS\.personalization-applied'
if (Test-Path $personalizationMarker) {
    $global:LASTEXITCODE = 0
    exit 0
}

$sids = @('.DEFAULT')
try {
    $sids += (Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' } |
        ForEach-Object { $_.PSChildName })
} catch {}

foreach ($sid in $sids) {
    $key = 'Registry::HKEY_USERS\' + $sid + '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -Path $key -Name 'AppsUseLightTheme'    -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $key -Name 'SystemUsesLightTheme' -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $key -Name 'ColorPrevalence'      -Value 0 -PropertyType DWord -Force | Out-Null
}

if (-not ('Win32.NativeMethods' -as [type])) {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern System.IntPtr SendMessageTimeout(
    System.IntPtr hWnd, uint Msg, System.IntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out System.IntPtr lpdwResult);
'@
}

$HWND_BROADCAST   = [IntPtr]0xffff
$WM_SETTINGCHANGE = 0x001A
$SMTO_ABORTIFHUNG = 0x0002
$result = [IntPtr]::Zero

[void][Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [IntPtr]::Zero, 'ImmersiveColorSet', $SMTO_ABORTIFHUNG, 5000, [ref]$result)
[void][Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [IntPtr]::Zero, 'Environment',       $SMTO_ABORTIFHUNG, 5000, [ref]$result)
