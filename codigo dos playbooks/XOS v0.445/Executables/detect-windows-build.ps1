if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please right-click and 'Run as Administrator'."
    Break
}

function Set-RegistryBatch {
    param (
        [string]$Path,
        [hashtable]$Properties,
        [string]$Hive = "HKCU"
    )
    
    $fullPath = "$Hive`:$Path"
    if (!(Test-Path $fullPath)) {
        New-Item -Path $fullPath -Force | Out-Null
    }

    foreach ($name in $Properties.Keys) {
        $data = $Properties[$name]
        $value = $data
        $type = "DWord"
        if ($data -is [Array] -and $data.Count -eq 2 -and $data[1] -in @("String","DWord","Binary","ExpandString","MultiString","QWord")) {
            $value = $data[0]
            $type = $data[1]
        }
        elseif ($data -is [byte[]]) {
            $type = "Binary"
        }
        elseif ($data -is [String]) {
            $type = "String"
        }

        Set-ItemProperty -Path $fullPath -Name $name -Value $value -Type $type -Force | Out-Null
    }
}

$currentBuild = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
$isWin11 = $currentBuild -ge 22000

$isServer = $false
$serverCheckValues = @("CompositionEditionID", "EditionID", "InstallationType", "ProductName", "SoftwareType", "System")
$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

foreach ($value in $serverCheckValues) {
    try {
        $regValue = Get-ItemPropertyValue -Path $regPath -Name $value -ErrorAction SilentlyContinue
        if ($regValue -and $regValue.ToString().ToLower().Contains("server")) {
            $isServer = $true
            break
        }
    } catch {
        continue
    }
}

if ($isServer) {
    Set-RegistryBatch -Hive "HKLM" -Path "\Software\Policies\Microsoft\Windows\Server\InitialConfigurationTasks" -Properties @{
        "DoNotOpenAtLogon" = 1
    }
    try {
        Disable-ScheduledTask -TaskName "ServerManager" -TaskPath "\Microsoft\Windows\Server Manager\" -ErrorAction Stop
    } catch {
        Write-Warning "  Could not disable Server Manager task: $_"
    }
    try {
        $trkService = Get-Service -Name "MSDTC" -ErrorAction SilentlyContinue
        if ($trkService) {
            if ($trkService.Status -eq "Running") {
                Stop-Service -Name "MSDTC" -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name "MSDTC" -StartupType Disabled -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "  Could not disable MSDTC service: $_"
    }
    $azureArcPath = "C:\Windows\AzureArcSetup\Systray"
    if (Test-Path $azureArcPath) {
        try {
            $uninstaller = Get-ChildItem -Path $azureArcPath -Filter "*.exe" -Recurse | 
                          Where-Object { $_.Name -match "uninstall|remove" -or $_.FullName -match "uninstall" } |
                          Select-Object -First 1
            
            if ($uninstaller) {
                Start-Process -FilePath $uninstaller.FullName -ArgumentList "/quiet /norestart" -Wait -NoNewWindow
            }
            $runRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            if (Test-Path $runRegPath) {
                $azureRunValue = Get-ItemProperty -Path $runRegPath -Name "AzureArcSetup" -ErrorAction SilentlyContinue
                if ($azureRunValue) {
                    Remove-ItemProperty -Path $runRegPath -Name "AzureArcSetup" -Force -ErrorAction SilentlyContinue
                }
            }
            Start-Sleep -Seconds 2
            Remove-Item -Path $azureArcPath -Recurse -Force -ErrorAction SilentlyContinue
            $azureArcTask = Get-ScheduledTask -TaskName "*Azure*Arc*" -ErrorAction SilentlyContinue
            if ($azureArcTask) {
                Unregister-ScheduledTask -TaskName $azureArcTask.TaskName -Confirm:$false -ErrorAction SilentlyContinue
            }
            
        } catch {
            Write-Warning "  Could not fully remove Azure Arc Setup: $_"
        }
    } else {
        try {
            $runRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            if (Test-Path $runRegPath) {
                $azureRunValue = Get-ItemProperty -Path $runRegPath -Name "AzureArcSetup" -ErrorAction SilentlyContinue
                if ($azureRunValue) {
                    Remove-ItemProperty -Path $runRegPath -Name "AzureArcSetup" -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Write-Warning "  Could not remove AzureArcSetup registry entry: $_"
        }
    }
    
}

# Desktop & Window Metrics
Set-RegistryBatch -Path "\Control Panel\Desktop" -Properties @{
    "DragFullWindows"     = @("0", "String")
    "UserPreferencesMask" = @([byte[]](0x90, 0x12, 0x03, 0x80, 0x12, 0x00, 0x00, 0x00), "Binary")
}

Set-RegistryBatch -Path "\Control Panel\Desktop\WindowMetrics" -Properties @{
    "MinAnimate" = @("0", "String")
}

Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Properties @{
    "ListviewAlphaSelect" = 0
    "ListviewShadow"      = 0
    "TaskbarAnimations"   = 0
}

Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Properties @{
    "VisualFXSetting" = 3
}

Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Properties @{
    "SystemUsesLightTheme" = 0
    "AppsUseLightTheme"    = 0
}

Set-RegistryBatch -Path "\Software\Microsoft\Windows\DWM" -Properties @{
    "EnableAeroPeek" = 0
}

Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Properties @{
    "PenWorkspaceButtonDesiredVisibility" = 0
}

if ($isWin11) {
    # Classic context menu
    Set-RegistryBatch -Path "\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Properties @{ "(Default)" = @("", "String") }
    Set-RegistryBatch -Path "\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Properties @{ "(Default)" = @("", "String") }

    # GPU Scheduling & DirectX
    Set-RegistryBatch -Path "\Software\Microsoft\DirectX\UserGpuPreferences" -Properties @{
        "DirectXUserGlobalSettings" = @("SwapEffectUpgradeEnable=1;VRROptimizeEnable=0;", "String")
    }
    Set-RegistryBatch -Hive "HKLM" -Path "\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Properties @{
        "HwSchMode" = 2
    }

    # Taskbar Alignment (0 = Left) & Widgets
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Properties @{
        "TaskbarAl"          = 0
        "ShowTaskViewButton" = 0
    }

    # Search Box (Icon Only)
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Search" -Properties @{
        "SearchboxTaskbarMode" = 1
    }

    # Additional Win11 Visuals
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Properties @{ "EnableTransparency" = 0 }
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\DWM" -Properties @{ "AlwaysHibernateThumbnails" = 0 }

    # Enable Taskbar End Task (Build 22631+)
    if ($currentBuild -ge 22631) {
        Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Properties @{
            "TaskbarEndTask" = 1
        }
    }

    # Disable Cross-Device Resume
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" -Properties @{
        "IsResumeAllowed" = 0
    }

    # Restart Explorer safely to apply Taskbar/Visual changes
    if (-not $isServer) {  # Optional: skip on server if not needed
        try {
            Stop-Process -Name "explorer" -Force -ErrorAction Stop
        } catch {
            # Ignore if explorer wasn't running
        } finally {
			   
            Start-Sleep -Seconds 1
            if (!(Get-Process explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer
            }
        }
    }

} else {
    # VRR disable (supported from build 18362 / W10 1903)
    if ($currentBuild -ge 18362) {
        Set-RegistryBatch -Path "\Software\Microsoft\DirectX\UserGpuPreferences" -Properties @{
            "DirectXUserGlobalSettings" = @("VRROptimizeEnable=0;", "String")
        }
    }

    # Tablet Mode & People Band
    Set-RegistryBatch -Path "\SOFTWARE\Microsoft\TabletTip\1.7" -Properties @{ "TipbandDesiredVisibility" = 0 }
    Set-RegistryBatch -Path "\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Properties @{ "PeopleBand" = 0 }

    # Hide "Meet Now" (User & Machine Policy)
    Set-RegistryBatch -Path "\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Properties @{ "HideSCAMeetNow" = 1 }
    Set-RegistryBatch -Hive "HKLM" -Path "\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Properties @{ "HideSCAMeetNow" = 1 }

    # Remove "3D Objects" folder from This PC
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Force -ErrorAction SilentlyContinue
}

