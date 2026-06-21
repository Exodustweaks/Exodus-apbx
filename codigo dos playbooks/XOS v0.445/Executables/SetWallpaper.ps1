param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Desktop", "LockScreen")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$ImagePath
)

$resolvedPath = (Resolve-Path $ImagePath -ErrorAction Stop).Path

if (-not (Test-Path $resolvedPath)) {
    Write-Error "Image not found: $resolvedPath"
    exit 1
}

switch ($Mode) {
    "Desktop" {
        # Write wallpaper path to all user hives (including .DEFAULT for new profiles)
        Get-ChildItem -Path "Registry::HKU" | ForEach-Object {
            [Microsoft.Win32.Registry]::SetValue("$($_.Name)\Control Panel\Desktop", "WallPaper", $resolvedPath, [Microsoft.Win32.RegistryValueKind]::String)
        }

        # Apply immediately via SystemParametersInfo
        if (-not ([System.Management.Automation.PSTypeName]'XOS.WallpaperHelper').Type) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;

namespace XOS {
    public static class WallpaperHelper {
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);

        public static void Apply(string path) {
            SystemParametersInfo(0x0014, 0, path, 0x01 | 0x02);
        }
    }
}
"@
        }
        [XOS.WallpaperHelper]::Apply($resolvedPath)
    }

    "LockScreen" {
        # Copy image to a persistent location that survives reboots
        $lockDir = Join-Path $env:SystemRoot 'Web\Screen'
        if (-not (Test-Path $lockDir)) { New-Item -ItemType Directory -Path $lockDir -Force | Out-Null }
        $lockImg = Join-Path $lockDir 'lockscreen.jpg'
        Copy-Item -Path $resolvedPath -Destination $lockImg -Force

        # Set lock screen via Group Policy registry (works on all Win10/Win11 builds)
        $polPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
        if (-not (Test-Path $polPath)) { New-Item -Path $polPath -Force | Out-Null }
        Set-ItemProperty -Path $polPath -Name 'LockScreenImage' -Value $lockImg -Type String -Force
        Set-ItemProperty -Path $polPath -Name 'NoChangingLockScreen' -Value 1 -Type DWord -Force
    }
}
