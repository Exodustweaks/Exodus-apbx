$WarningPreference = 'SilentlyContinue'

$logDir = "C:\ProgramData\AME\Logs"
$logFile = "$logDir\OptionalFeatures.log"
if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath $logFile -Encoding utf8
}

Write-Log "--- OptionalFeatures script started ---"

$disable = @(
    "SMBDirect",
    "MSRDC-Infrastructure",
    "Workfolders-Client",
    "WCF-Services45",
    "WCF-TCP-PortSharing45",
    "Printing-PrintToPDFServices-Features",
    "Printing-Foundation-Features",
    "Printing-Foundation-InternetPrinting-Client",
    # Hyper-V
    "Microsoft-Hyper-V-All",
    "Microsoft-Hyper-V",
    "Microsoft-Hyper-V-Tools-All",
    "Microsoft-Hyper-V-Management-PowerShell",
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Services",
    "Microsoft-Hyper-V-Management-Clients",
    "HypervisorPlatform",
    "VirtualMachinePlatform",
    # WSL
    "Microsoft-Windows-Subsystem-Linux",
    # XPS
    "Printing-XPSServices-Features"
)

$enable = @(
    "DirectPlay"
)

Write-Log "Querying all optional feature states..."
$allFeatures = @{}
Get-WindowsOptionalFeature -Online | ForEach-Object { $allFeatures[$_.FeatureName] = $_.State }
Write-Log "Retrieved $($allFeatures.Count) features"

foreach ($f in $disable) {
    $state = $allFeatures[$f]
    if ($null -eq $state) {
        Write-Log "[SKIP] $f - not present on this system"
        continue
    }
    if ($state -eq "Disabled" -or $state -eq "DisabledWithPayloadRemoved") {
        Write-Log "[SKIP] $f - already disabled ($state)"
        continue
    }
    Write-Log "[DISABLE] $f - current state: $state"
    Disable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart | Out-Null
    Write-Log "[DONE] $f disabled"
}

foreach ($f in $enable) {
    $state = $allFeatures[$f]
    if ($null -eq $state) {
        Write-Log "[SKIP] $f - not present on this system"
        continue
    }
    if ($state -eq "Enabled") {
        Write-Log "[SKIP] $f - already enabled"
        continue
    }
    Write-Log "[ENABLE] $f - current state: $state"
    Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -All | Out-Null
    Write-Log "[DONE] $f enabled"
}

$sr = Get-WindowsCapability -Online -Name "App.StepsRecorder~~~~0.0.1.0"
if ($sr.State -ne "NotPresent") {
    Write-Log "[REMOVE] App.StepsRecorder - current state: $($sr.State)"
    Remove-WindowsCapability -Online -Name "App.StepsRecorder~~~~0.0.1.0" | Out-Null
    Write-Log "[DONE] App.StepsRecorder removed"
} else {
    Write-Log "[SKIP] App.StepsRecorder - already removed"
}

Write-Log "--- OptionalFeatures script finished ---"
