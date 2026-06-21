param (
    [switch]$enable_av,
    [switch]$disable_av,
    [switch]$delayedRestart,
    [switch]$silent
)

$interactiveMode = (!$enable_av -and !$disable_av) -and !$silent

$arg = ( 
    ($PSBoundParameters.GetEnumerator() | % {
        if ($_.Value -is [switch] -and $_.Value.IsPresent) {"-$($_.Key)"}
        elseif ($_.Value -isnot [switch]) {"-$($_.Key) `"$($_.Value -replace '"','""')`""}
    }) + 
    ($args | % {"`"$($_ -replace '"','""')`""})
) -join ' '

# === Prerequisite ===
if ($silent) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@
    $hwnd = [Win]::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) {[Win]::ShowWindow($hwnd, 0) *>$null}
}

if (!(whoami /user | findstr "S-1-5-18").Length -gt 0) {
    $exe = if ($PSVersionTable.PSVersion.Major -gt 5) {'pwsh.exe'} else {'powershell.exe'}
    $script = if ($MyInvocation.PSCommandPath) {$MyInvocation.PSCommandPath} else {$PSCommandPath}
    RunAsTI $exe "-EP Bypass -File `"$script`" $arg"
    exit
}

& (Join-Path $env:WinDir 'RapidScripts\EnvSetup.ps1')

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class ConsoleManager {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll")] public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
    [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CONSOLE_FONT_INFO_EX {
        public uint cbSize; public uint nFont; public COORD dwFontSize; public int FontFamily; public int FontWeight;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string FaceName;
    }
    [StructLayout(LayoutKind.Sequential)] public struct COORD {public short X; public short Y;}
    [StructLayout(LayoutKind.Sequential)] public struct RECT {public int Left; public int Top; public int Right; public int Bottom;}

    public const int STD_OUTPUT_HANDLE = -11;
    public static void ResizeWindow(int w, int h) {MoveWindow(GetConsoleWindow(), 0, 0, w, h, true);}
    public static void SetConsoleFont(string name, short size) {
        CONSOLE_FONT_INFO_EX info = new CONSOLE_FONT_INFO_EX();
        info.cbSize = (uint)Marshal.SizeOf(typeof(CONSOLE_FONT_INFO_EX));
        info.FaceName = name; info.dwFontSize = new COORD {X = size, Y = size}; info.FontFamily = 54; info.FontWeight = 400;
        SetCurrentConsoleFontEx(GetStdHandle(STD_OUTPUT_HANDLE), false, ref info);
    }
    public static void QuickEditOFF() {IntPtr hConIn = GetStdHandle(-10); uint m; if(GetConsoleMode(hConIn, out m)) SetConsoleMode(hConIn, (m | 0x80U) & ~0x40U);}
    public static void QuickEditON() {IntPtr hConIn = GetStdHandle(-10); uint m; if(GetConsoleMode(hConIn, out m)) SetConsoleMode(hConIn, (m | 0x40U) & ~0x80U);}
}
"@

function AdjustDesign {
    Add-Type -AssemblyName System.Windows.Forms
    $host.PrivateData.WarningBackgroundColor = "Black"
    $host.PrivateData.ErrorBackgroundColor = "Black"
    $host.PrivateData.VerboseBackgroundColor = "Black"
    $host.PrivateData.DebugBackgroundColor = "Black"
    $host.UI.RawUI.BackgroundColor = [ConsoleColor]::Black
    $host.UI.RawUI.ForegroundColor = [ConsoleColor]::White

    [ConsoleManager]::QuickEditOFF()
    [ConsoleManager]::ResizeWindow(850, 550)
    [ConsoleManager]::SetConsoleFont("Consolas", 16)
    $hwnd = [ConsoleManager]::GetConsoleWindow()
    $rect = New-Object ConsoleManager+RECT
    [ConsoleManager]::GetWindowRect($hwnd, [ref]$rect) *>$null

    $sw = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $sh = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    $ww = $rect.Right - $rect.Left
    $wh = $rect.Bottom - $rect.Top
    $newX = [Math]::Max(0, [Math]::Round(($sw - $ww) / 2))
    $newY = [Math]::Max(0, [Math]::Round(($sh - $wh) / 2))
    [ConsoleManager]::MoveWindow($hwnd, $newX, $newY, $ww, $wh, $true) *>$null
}

function Write-Block {
    [CmdletBinding()]
    param (
        [int]$Indent = 0,
        [string]$Content = '',
        [string]$Title = '',
        [string]$Description = '',
        [int]$TitleWidth = 24,
        [string]$LeftBracket = '[',
        [string]$RightBracket = ']',
        [string]$Separator = ' | ',
        [string]$BracketColor = 'Green',
        [string]$ContentColor = 'White',
        [string]$TextColor = 'White',
        [switch]$NoNewLine
    )
    if (!$Content) {return}

    $spaces = ' ' * $Indent
    $line = if ($Description) {"{0,-$TitleWidth}" -f $Title + $Separator + $Description} else {$Title}
    $prefix = if ($NoNewLine) {"`r$spaces"} else {"$spaces"}

    $ansi = @{
        'Black' = 30; 'DarkBlue' = 34; 'DarkGreen' = 32; 'DarkCyan' = 36; 'DarkRed' = 31; 'DarkMagenta' = 35; 'DarkYellow' = 33; 'Gray' = 37
        'DarkGray' = 90; 'Blue' = 94; 'Green' = 92; 'Cyan' = 96; 'Red' = 91; 'Magenta' = 95; 'Yellow' = 93; 'White' = 97
    }
    
    $e = [char]27
    $cB = if ($ansi.ContainsKey($BracketColor)) {"$e[$($ansi[$BracketColor])m"} else {"$e[97m"}
    $cC = if ($ansi.ContainsKey($ContentColor)) {"$e[$($ansi[$ContentColor])m"} else {"$e[97m"}
    $cT = if ($ansi.ContainsKey($TextColor)) {"$e[$($ansi[$TextColor])m"} else {"$e[97m"}
    $rst = "$e[0m"

    Write-Host "$prefix$cB$LeftBracket$cC$Content$cB$RightBracket $cT$line$rst"

    if (!$interactiveMode -and $global:ProgressLog) {
        $cleanMsg = if ($Description) {"$Title $Description"} else {$Title}
        $ts = Get-Date -Format "HH:mm:ss"
        Add-Content -Path $global:ProgressLog -Value "[$ts] $cleanMsg" -Force
    }
}

function Init-Logger {
    $baseLogDir = Join-Path $env:WinDir 'RapidScripts\DefenderSwitcher'
    $RapidOS = "HKLM:\SOFTWARE\RapidOS"
    
    if (!(Test-Path $baseLogDir)) {mkdir -Force -Path $baseLogDir *>$null}

    $regLogDir = (Get-ItemProperty -Path $RapidOS -Name "CurrentLogDir" -EA 0).CurrentLogDir
    
    if ($regLogDir -and (Test-Path $regLogDir)) {
        $global:CurrentLogDir = $regLogDir
    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $global:CurrentLogDir = Join-Path $baseLogDir $timestamp
        mkdir -Force -Path $global:CurrentLogDir *>$null
        
        if (!(Test-Path $RapidOS)) {New-Item -Path $RapidOS -Force *>$null}
        Set-RegistryValue -Path $RapidOS -Name "CurrentLogDir" -Type String -Value $global:CurrentLogDir *>$null
    }

    $global:MainLog = Join-Path $global:CurrentLogDir "DefenderSwitcher.log"
    $global:ProgressLog = Join-Path $global:CurrentLogDir "Progress.log"
    
    Start-Transcript -Path $global:MainLog -Append -Force -EA 0 | Out-Null
}

function DefenderStatus {
    $packageResult = (Get-WindowsPackage -Online | ? {$_.PackageName -like "*AntiBlocker*" -or $_.PackageName -like "*Defender*"})
    $svcResult = (Get-Service -Name WinDefend -EA 0 | Select -ExpandProperty StartType)
    $svcResult = $svcResult -replace "`r`n", ""

    if ($packageResult -or $svcResult -eq "Disabled") {
        $global:status = "disabled"
    } else {
        $global:status = "enabled"
    }
}

function MainMenu {
    cls
    DefenderStatus
    Write-Host "`n`n`n`n"
    Write-Host "         ______________________________________________________________" -F DarkGray
    Write-Host
    Write-Host "                               Defender Switcher"
    Write-Host
    Write-Host "                                Current Status:" -F Yellow
    if ($status -eq "enabled")
    {Write-Host "                          Windows Defender is ENABLED" -F Green}
else{Write-Host "                          Windows Defender's DISABLED" -F Red}
    Write-Host "               __________________________________________________" -F DarkGray
    Write-Host
    Write-Host "                               Choose an option:" -F Yellow
    Write-Block -Content "1" -Title "Enable Windows Defender" -Description "Restore Protection" -Indent 15 -TitleWidth 24
    Write-Block -Content "2" -Title "Disable Windows Defender" -Description "Turn Off Protection" -Indent 15 -TitleWidth 24
    Write-Block -Content "3" -Title "Information" -Description "Useful Information" -Indent 15 -TitleWidth 24
    Write-Block -Content "4" -Title "Exit" -Description "Close Program" -Indent 15 -TitleWidth 24
    Write-Host
    Write-Host "               __________________________________________________" -F DarkGray
    Write-Host
    Write-Host "              Choose a menu option using your keyboard [1,2,3,4] :" -F Green
    Write-Host
    Write-Host "         ______________________________________________________________" -F DarkGray
    Write-Host

    [ConsoleManager]::QuickEditOFF()
    $host.UI.RawUI.KeyAvailable >$null 2>&1
    $choice = $host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown').Character
    switch ($choice) {
        '1' {EnableDefender}
        '2' {DisableDefender}
        '3' {ShowInformation}
        '4' {Start-Sleep -s 1; exit}
        default {MainMenu}
    }
}

function ShowInformation {
    cls
    Write-Host "`n`n`n"
    Write-Host "         ______________________________________________________________" -F DarkGray
    Write-Host
    Write-Host "                               Defender Switcher"
    Write-Host
    Write-Host "               Credits:" -F Yellow
    Write-Host
    Write-Block -Content "1" -Title "Achilles Script" -Indent 15
    Write-Block -Content "2" -Title "AveYo's TI elevation" -Indent 15
    Write-Block -Content "3" -Title "MAS-based design" -Indent 15
    Write-Host
    Write-Host "               __________________________________________________" -F DarkGray
    Write-Host
    Write-Host "               Our links:" -F Yellow
    Write-Host
    Write-Block -Content "4" -Title "GitHub" -Indent 15
    Write-Block -Content "5" -Title "Discord" -Indent 15
    Write-Block -Content "6" -Title "Website" -Indent 15
    Write-Host
    Write-Host "               __________________________________________________" -F DarkGray
    Write-Host
    Write-Host "           Choose a menu option using your keyboard [1,2,3,4,5,6,q] :" -F Green
    Write-Host
    Write-Host "         ______________________________________________________________" -F DarkGray
    $choice = ""
    while ($choice -ne 'q') {
        $choice = $host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown').Character
        switch ($choice) {
            '1' {Start-Process "https://github.com/lostzombie/AchillesScript"}
            '2' {Start-Process "https://github.com/AveYo/LeanAndMean"}
            '3' {Start-Process "https://github.com/massgravel/Microsoft-Activation-Scripts"}
            '4' {Start-Process "https://github.com/instead1337/Defender-Switcher"}
            '5' {Start-Process "https://discord.rapid-community.ru"}
            '6' {Start-Process "https://rapid-community.ru"}
            'q' {MainMenu}
        }
    }
}

function EnableDefender {
    cls
    DefenderStatus
    switch ($status) {
        "enabled" {
            Write-Block -Content "INFO" -Title "Defender is already enabled."
        }
        default {
            [ConsoleManager]::QuickEditON()
            Safeboot -Enable $true
        }
    }
    if ($interactiveMode) {
        pause
        MainMenu
    } else {
        exit
    }
}

function DisableDefender {
    cls
    DefenderStatus
    switch ($status) {
        "disabled" {
            Write-Block -Content "INFO" -Title "Defender is already disabled."
        }
        default {
            [ConsoleManager]::QuickEditON()
            Safeboot -Enable $false
        }
    }
    if ($interactiveMode) {
        pause
        MainMenu
    } else {
        exit
    }
}

function Safeboot {
    param (
        [Parameter(Mandatory=$true)]
        [bool]$Enable
    )

    Init-Logger
    $workDir = Join-Path $env:WinDir 'RapidScripts\DefenderSwitcher'

    if ($Enable) {
        $av_param = "-enable_av"
        $verb_ing = "Enabling"
        $verb_ed = "enabled"
        $verb_base = "enable"
    } else {
        $av_param = "-disable_av"
        $verb_ing = "Disabling"
        $verb_ed = "disabled"
        $verb_base = "disable"
    }

    $RapidOS = "HKLM:\SOFTWARE\RapidOS"
    $inSafeMode = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option"

    if (!$inSafeMode) {
        Write-Block -Content "INFO" -Title "Prepairing..."

        # === Configuration ===
        if (!(Test-Path $RapidOS)) {New-Item -Path $RapidOS -Force -EA 0 *>$null}
        if (!(Test-Path $workDir)) {mkdir $workDir -Force *>$null}

        $timeout = (cmd /c "bcdedit /enum {bootmgr}" | Select-String -Pattern 'timeout' -SimpleMatch | Select -First 1 | % {($_ -replace '.*timeout\s+','').Trim()}) -join ''
        $displaybootmenu = (cmd /c "bcdedit /enum {bootmgr}" | Select-String -Pattern 'displaybootmenu' -SimpleMatch | Select -First 1 | % {($_ -replace '.*displaybootmenu\s+','').Trim()}) -join ''
        $defaultGuid = (bcdedit /v | Select-String -Pattern 'default\s+({[a-f0-9-]+})' | Select -First 1 | % {$_.Matches[0].Groups[1].Value}) -join ''

        if ($timeout) {Set-RegistryValue -Path $RapidOS -Name "Timeout" -Type DWORD -Value $timeout} else {Set-RegistryValue -Path $RapidOS -Name "Timeout" -Type DWORD -Value 30}
        if ($displaybootmenu) {Set-RegistryValue -Path $RapidOS -Name "DisplayBootMenu" -Type String -Value $displaybootmenu} else {Set-RegistryValue -Path $RapidOS -Name "DisplayBootMenu" -Type String -Value "DELETE"}
        Set-RegistryValue -Path $RapidOS -Name "DefaultGuid" -Type String -Value $defaultGuid

        # === BCD setup ===
        $guid = (cmd /c "bcdedit /copy {current} /d `"Safe Mode"`" 2>$null | Select-String "{[a-f0-9-]+}") -replace ".*{([a-f0-9-]+)}.*", '{${1}}'
        if (!$guid) {
            $guid = (cmd /c "bcdedit /copy {default} /d `"Safe Mode"`" 2>$null | Select-String "{[a-f0-9-]+}") -replace ".*{([a-f0-9-]+)}.*", '{${1}}'
            if (!$guid) {
                Write-Block -Content "ERROR" -Title "Safe boot configuration failed." -ContentColor "Red"
                if ($interactiveMode) {pause; MainMenu} else {exit}
            }
        } else {
            Set-RegistryValue -Path $RapidOS -Name "SafeBootGuid" -Type String -Value $guid
        }

        bcdedit /set $guid safeboot minimal | Out-Null
        if ($LASTEXITCODE -ne 0) {bcdedit /set safeboot minimal | Out-Null}
        if ($LASTEXITCODE -ne 0) {
            Write-Block -Content "ERROR" -Title "Failed to enable safe boot." -ContentColor "Red"
            if ($interactiveMode) {pause; MainMenu} else {exit}
        }

        bcdedit /set $guid bootmenupolicy Legacy | Out-Null
        bcdedit /set $guid hypervisorlaunchtype off | Out-Null
        bcdedit /default $guid | Out-Null

        bcdedit /timeout 2 | Out-Null
        bcdedit /set {bootmgr} displaybootmenu Yes | Out-Null

        # === Scripts & Service ===
        $scriptPath = $PSCommandPath
        $path = ("-EP Bypass -File ""$scriptPath"" $av_param").Replace('"', '""')

        $progressPath = Join-Path $workDir 'Progress.bat'
        $progressContent = @"
@echo off
cd /d "$global:CurrentLogDir"
chcp 65001
:loop
cls
echo $verb_ing Microsoft Defender...
echo.
if exist Progress.log (type Progress.log) else (echo Initializing logs...)
timeout /t 1 >nul
goto :loop
"@
        Set-Content -Path $progressPath -Value $progressContent -Force

        $startupPath = Join-Path $workDir 'Startup.bat'
        $fallback = @"
@echo off
reg query "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Option" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (exit)

set "attempts=0"

:wait
set /a attempts+=1
reg query "HKLM\SOFTWARE\RapidOS" /v Executed >nul 2>&1
if %ERRORLEVEL% EQU 0 (exit)

if %attempts% GEQ 10 (
    powershell.exe $path
    exit
)

timeout /t 3 >nul
goto :wait
"@
        Set-Content -Path $startupPath -Value $fallback -Force

        $vbsPath = Join-Path $workDir 'RapidOS.vbs'
        $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """$progressPath""", 1, False
WshShell.Run """$startupPath""", 0, False
"@
        Set-Content -Path $vbsPath -Value $vbsContent -Force

        $winlogonPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        $originalUserinit = (Get-ItemProperty -Path $winlogonPath -Name 'Userinit' -EA 0).Userinit
        Set-RegistryValue -Path $RapidOS -Name 'OriginalUserinit' -Type String -Value $originalUserinit

        $newUserinit = "$originalUserinit,wscript.exe ""$vbsPath"","
        Set-RegistryValue -Path $winlogonPath -Name 'Userinit' -Type String -Value $newUserinit

        $serviceName = "RapidOS"
        $assemblyPath = Join-Path $workDir 'RapidOS.exe'

        $service = @'
using System; using System.Runtime.InteropServices; using System.ServiceProcess;
namespace RapidOS
{
    public class Service : ServiceBase
    {
        public Service() {ServiceName = "RapidOS"; AutoLog = true;}
        protected override void OnStart(string[] args) {while (System.Diagnostics.Process.GetProcessesByName("logonui").Length == 0) System.Threading.Thread.Sleep(500); ShellExecuteW(IntPtr.Zero, "open", "powershell.exe", @"{{path}}", null, 0); Stop();}
        protected override void OnStop() {}
        public static void Main() {ServiceBase.Run(new Service());}

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        static extern IntPtr ShellExecuteW(IntPtr hwnd, string op, string file, string param, string dir, int show);
    }
}
'@
        $code = $service -replace '{{path}}', $path

        try {
            Add-Type -TypeDefinition $code -Language CSharp -OutputAssembly $assemblyPath -ReferencedAssemblies 'System', 'System.ServiceProcess' -EA 1
            sc.exe delete $serviceName *>$null
            sc.exe create $serviceName type= own start= auto error= ignore obj= "LocalSystem" binPath= "$assemblyPath" | Out-Null
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal\$serviceName" /ve /t REG_SZ /d "Service" /f *>$null
        } catch {
            Write-Block -Content "ERROR" -Title "Failed to compile service. Aborting safe boot." -ContentColor "Red"
            if ($displaybootmenu -eq "DELETE") {bcdedit /deletevalue {bootmgr} displaybootmenu | Out-Null} else {bcdedit /set {bootmgr} displaybootmenu $displaybootmenu | Out-Null}
            bcdedit /timeout $timeout | Out-Null
            bcdedit /default $defaultGuid | Out-Null
            bcdedit /delete $guid /f | Out-Null
            if ($interactiveMode) {pause; MainMenu} else {exit}
        }

        if ($interactiveMode -and !$delayedRestart) {
            Write-Block -Content "INFO" -Title "Rebooting in 5 sec..."
            Start-Sleep -s 5
        }

        if (!$delayedRestart) {
            shutdown /r /f /t 0
        } else {
            Write-Block -Content "INFO" -Title "$verb_ing Microsoft Defender will take effect after restart."
            Start-Sleep -s 2
            if ($interactiveMode) {pause; MainMenu} else {exit}
        }
    }
    else {
        # === Cleanup & Restore ===
        reg add "HKLM\SOFTWARE\RapidOS" /v Executed /t REG_SZ /d "1" /f *>$null
        
        Write-Block -Content "INFO" -Title "Restoring boot configuration..."
        bcdedit /deletevalue safeboot | Out-Null
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal\RapidOS" /f *>$null 2>&1

        sc.exe delete RapidOS | Out-Null
        del "$workDir\RapidOS.exe" -Force *>$null
        del "$workDir\RapidOS.vbs" -Force *>$null

        Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "Cleanup" -Type String -Value "cmd.exe /c del /q /f `"$workDir\RapidOS.exe`" >nul 2>&1 & del /q /f `"$workDir\RapidOS.vbs`" >nul 2>&1 & del /q /f `"$workDir\Startup.bat`" >nul 2>&1 & del /q /f `"$workDir\Progress.bat`" >nul 2>&1"

        if (Test-Path $RapidOS) {
            $backup = Get-ItemProperty -Path $RapidOS

            bcdedit /timeout $backup.Timeout | Out-Null
            bcdedit /default $backup.DefaultGuid | Out-Null
            bcdedit /delete $backup.SafeBootGuid /f | Out-Null
            if ($backup.DisplayBootMenu -eq "DELETE") {
                bcdedit /deletevalue {bootmgr} displaybootmenu | Out-Null
            } else {
                bcdedit /set {bootmgr} displaybootmenu $backup.DisplayBootMenu | Out-Null
            }
            if ($backup.OriginalUserinit) {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'Userinit' -Type String -Value $backup.OriginalUserinit
            } else {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'Userinit' -Type String -Value "$($env:WinDir)\system32\userinit.exe,"
            }

            del -Path $RapidOS -Recurse -Force -EA 0
        } else {
            bcdedit /timeout 15 | Out-Null
            bcdedit /deletevalue {bootmgr} displaybootmenu | Out-Null
            Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name 'Userinit' -Type String -Value "$($env:WinDir)\system32\userinit.exe,"
        }
        
        if ($Enable) {
            ProcessDefender -Enable $true
        } else {
            ProcessDefender -Disable $true
        }

        DefenderStatus
        switch ($status) {
            "$verb_ed" {
                Write-Block -Content "INFO" -Title "Defender has been $verb_ed."
            }
            default {
                Write-Block -Content "ERROR" -Title "Failed to $verb_base Defender." -ContentColor "Red"
            }
        }

        Write-Block -Content "INFO" -Title "Rebooting..."
        Start-Sleep -s 1
        shutdown /r /f /t 0
    }
}

function ProcessDefender {
    param ([switch]$Enable, [switch]$Disable)

    $config = [PSCustomObject]@{
        defenderPath = Join-Path $env:ProgramFiles 'Windows Defender'
        svc = 'wscsvc'
        proc = 'MsMpEng.exe'
        exe = 'MpCmdRun.exe'
        backupExe = 'off.exe'
        services = @{
            'WinDefend' = 2; 'MDCoreSvc' = 2; 'WdNisSvc' = 3; 'Sense' = 3;
            'webthreatdefsvc' = 3; 'webthreatdefusersvc' = 2; 'WdNisDrv' = 3;
            'WdBoot' = 0; 'WdDevFlt' = 1; 'WdFilter' = 0
        }
        regSettings = @{
            'ServiceKeepAlive' = 0; 'PreviousRunningMode' = 0; 'IsServiceRunning' = 0;
            'DisableAntiSpyware' = 1; 'DisableAntiVirus' = 1; 'PassiveMode' = 1
        }
    }

    Write-Block -Content "INFO" -Title "Stopping services and processes..."
    Stop-Service $config.svc -Force -EA 0
    taskkill /f /im $config.backupExe 2>&1 | Out-Null
    taskkill /f /im $config.exe 2>&1 | Out-Null
    taskkill /f /im $config.proc 2>&1 | Out-Null

    if ($Enable) {
        Write-Block -Content "INFO" -Title "Restoring Defender executables..."
        $svcImagePath = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name ImagePath -EA 0).ImagePath.Trim('"')
        $svcPath = Split-Path $svcImagePath
        if (Test-Path (Join-Path $svcPath $config.backupExe)) {
            Rename-Item (Join-Path $svcPath $config.backupExe) $config.exe -Force -EA 0
        }

        Write-Block -Content "INFO" -Title "Enabling services and resetting policies..."
        foreach ($svc in $config.services.GetEnumerator()) {
            $regKey = "HKLM\SYSTEM\CurrentControlSet\Services\$($svc.Key)"
            reg add $regKey /v "Start" /t REG_DWORD /d $($svc.Value) /f | Out-Null
        }

        foreach ($entry in $config.regSettings.GetEnumerator()) {
            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v $($entry.Key) /f *>$null 2>&1
        }

        Write-Block -Content "INFO" -Title "Registering security libraries..."
        regsvr32.exe "$($config.defenderPath)\shellext.dll" /s
        regsvr32.exe "$($config.defenderPath)\AMMonitoringProvider.dll" /s
        regsvr32.exe "$($config.defenderPath)\DefenderCSP.dll" /s
        regsvr32.exe "$($config.defenderPath)\MpOAV.dll" /s
        regsvr32.exe "$($config.defenderPath)\MpProvider.dll" /s
        regsvr32.exe "$($config.defenderPath)\MpUxAgent.dll" /s
        regsvr32.exe "$($config.defenderPath)\MsMpCom.dll" /s
        regsvr32.exe "$($config.defenderPath)\ProtectionManagement.dll" /s

        $wdAtpPath = "${env:ProgramFiles}\Windows Defender Advanced Threat Protection\Classification"
        if (Test-Path $wdAtpPath) {
            regsvr32.exe "$wdAtpPath\cmicarabicwordbreaker.dll" /s
            regsvr32.exe "$wdAtpPath\korwbrkr.dll" /s
            regsvr32.exe "$wdAtpPath\mce.dll" /s
            regsvr32.exe "$wdAtpPath\upe.dll" /s
        }

        regsvr32.exe "$env:WinDir\System32\sppc.dll" /s
        regsvr32.exe "$env:WinDir\System32\ieapfltr.dll" /s
        regsvr32.exe "$env:WinDir\System32\ThreatResponseEngine.dll" /s
        regsvr32.exe "$env:WinDir\System32\webthreatdefsvc.dll" /s

        reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter\Instances\WdFilter Instance" /v "Altitude" /t REG_SZ /d 328010 /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 1 /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtectionSource" /t REG_DWORD /d 5 /f *>$null

        Write-Block -Content "INFO" -Title "Enabling SmartScreen..."
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /f *>$null 2>&1
        reg delete "HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled" /ve /f *>$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f *>$null
        reg delete "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_EdgeSmartScreenOff" /f *>$null 2>&1
        reg delete "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_StoreAppsSmartScreenOff" /f *>$null 2>&1
        reg delete "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_PuaSmartScreenOff" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" /v "ServiceEnabled" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe" /v "Debugger" /f *>$null 2>&1

        Write-Block -Content "INFO" -Title "Enabling tasks in the scheduler..."
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable *>$null 2>&1

        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Virus and threat protection" /v "UILockdown" /f *>$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /t REG_EXPAND_SZ /d "%WinDir%\System32\SecurityHealthSystray.exe" /f *>$null

        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SecurityHealthService.exe\PerfOptions" /f *>$null 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SecurityHealthSystray.exe\PerfOptions" /f *>$null 2>&1
    }

    if ($Disable) {
        Write-Block -Content "INFO" -Title "Disabling services and applying registry settings..."
        reg delete "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter\Instances\WdFilter Instance" /v "Altitude" /f *>$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 4 /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtectionSource" /t REG_DWORD /d 2 /f *>$null

        foreach ($entry in $config.regSettings.GetEnumerator()) {
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v $entry.Key /t REG_DWORD /d $entry.Value /f *>$null
        }

        $svcImagePath = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name ImagePath -EA 0).ImagePath.Trim('"')
        $svcPath = Split-Path $svcImagePath
        if (Test-Path (Join-Path $svcPath $config.exe)) {
            Rename-Item (Join-Path $svcPath $config.exe) $config.backupExe -Force -EA 0
        }

        foreach ($svc in $config.services.GetEnumerator()) {
            $regKey = "HKLM\SYSTEM\CurrentControlSet\Services\$($svc.Key)"
            reg add $regKey /v "Start" /t REG_DWORD /d 4 /f | Out-Null
        }

        Write-Block -Content "INFO" -Title "Unregistering security libraries..."
        regsvr32.exe /u "$($config.defenderPath)\shellext.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\AMMonitoringProvider.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\DefenderCSP.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\MpOAV.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\MpProvider.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\MpUxAgent.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\MsMpCom.dll" /s
        regsvr32.exe /u "$($config.defenderPath)\ProtectionManagement.dll" /s

        $wdAtpPath = "${env:ProgramFiles}\Windows Defender Advanced Threat Protection\Classification"
        if (Test-Path $wdAtpPath) {
            regsvr32.exe /u "$wdAtpPath\cmicarabicwordbreaker.dll" /s
            regsvr32.exe /u "$wdAtpPath\korwbrkr.dll" /s
            regsvr32.exe /u "$wdAtpPath\mce.dll" /s
            regsvr32.exe /u "$wdAtpPath\upe.dll" /s
        }

        regsvr32.exe /u "$env:WinDir\System32\sppc.dll" /s
        regsvr32.exe /u "$env:WinDir\System32\ieapfltr.dll" /s
        regsvr32.exe /u "$env:WinDir\System32\ThreatResponseEngine.dll" /s
        regsvr32.exe /u "$env:WinDir\System32\webthreatdefsvc.dll" /s

        Write-Block -Content "INFO" -Title "Disabling SmartScreen..."
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f *>$null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled" /ve /t REG_DWORD /d 0 /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_EdgeSmartScreenOff" /t REG_DWORD /d 1 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_StoreAppsSmartScreenOff" /t REG_DWORD /d 1 /f *>$null
        reg add "HKCU\SOFTWARE\Microsoft\Windows Security Health\State" /v "AppAndBrowser_PuaSmartScreenOff" /t REG_DWORD /d 1 /f *>$null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components" /v "ServiceEnabled" /t REG_DWORD /d 0 /f *>$null

        Write-Block -Content "INFO" -Title "Disabling tasks in the scheduler..."
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable *>$null 2>&1
        schtasks /change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable *>$null 2>&1
        
        Write-Block -Content "INFO" -Title "Cleaning up Defender data..."
        reg delete "HKLM\SOFTWARE\Microsoft\Windows Security Health\State\Persist" /f *>$null 2>&1
        del (Join-Path $env:ProgramData 'Microsoft\Windows Defender\Scans\mpenginedb.db') -Force *>$null 2>&1
        del (Join-Path $env:ProgramData 'Microsoft\Windows Defender\Scans\History\Service') -Recurse -Force *>$null 2>&1

        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v "DisableNotifications" /t REG_DWORD /d 1 /f *>$null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Virus and threat protection" /v "UILockdown" /t REG_DWORD /d 1 /f *>$null
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /f *>$null 2>&1

        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SecurityHealthService.exe\PerfOptions" /v "CpuPriorityClass" /t REG_SZ /d "1" /f *>$null
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SecurityHealthSystray.exe\PerfOptions" /v "CpuPriorityClass" /t REG_SZ /d "1" /f *>$null
    }
}

if ($enable_av) {EnableDefender}
elseif ($disable_av) {DisableDefender}
elseif ($interactiveMode) {AdjustDesign; MainMenu}