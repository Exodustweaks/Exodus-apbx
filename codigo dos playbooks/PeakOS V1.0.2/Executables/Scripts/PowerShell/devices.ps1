#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Device Manager Optimizer - Disables power management and unnecessary devices
.DESCRIPTION
    This script disables the "Allow the computer to turn off this device to save power" 
    option for every device in Device Manager on Windows 10/11, and also disables
    commonly unnecessary devices that can be safely removed from most systems.
.NOTES
    Must be run as Administrator
    Author: Ryvex
    Date: 2025-12-31
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Device Manager Optimizer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Counter for tracking changes
$totalDevices = 0
$modifiedDevices = 0
$errorDevices = 0

# Get all PnP devices
Write-Host "[*] Enumerating all devices..." -ForegroundColor Yellow
$devices = Get-PnpDevice | Where-Object { $_.Status -eq 'OK' -or $_.Status -eq 'Unknown' }
$totalDevices = $devices.Count

Write-Host "[+] Found $totalDevices devices" -ForegroundColor Green
Write-Host ""

# Process each device
foreach ($device in $devices) {
    $deviceName = $device.FriendlyName
    $instanceId = $device.InstanceId
    
    try {
        # Registry path for device power management
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters\WDF"
        
        # Check if the registry path exists
        if (Test-Path $regPath) {
            # Set IdleInWorkingState to 0 (disable power saving)
            Set-ItemProperty -Path $regPath -Name "IdleInWorkingState" -Value 0 -ErrorAction SilentlyContinue
        }
        
        # Also check for power management in the main device parameters
        $powerRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters"
        if (Test-Path $powerRegPath) {
            Set-ItemProperty -Path $powerRegPath -Name "SelectiveSuspendEnabled" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $powerRegPath -Name "SelectiveSuspendOn" -Value 0 -ErrorAction SilentlyContinue
        }
        
        # Disable power management via WMI for USB and other devices
        $wmiPath = $instanceId -replace '\\', '\\'
        $powerMgmt = Get-WmiObject -Class MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | 
        Where-Object { $_.InstanceName -like "*$($device.InstanceId)*" }
        
        if ($powerMgmt) {
            $powerMgmt.Enable = $false
            $powerMgmt.Put() | Out-Null
            Write-Host "[+] Disabled power saving: $deviceName" -ForegroundColor Green
            $modifiedDevices++
        }
        
        # Additional registry keys for network adapters
        if ($device.Class -eq 'Net') {
            $netRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
            $netAdapters = Get-ChildItem -Path $netRegPath -ErrorAction SilentlyContinue
            
            foreach ($adapter in $netAdapters) {
                $driverDesc = (Get-ItemProperty -Path $adapter.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
                if ($driverDesc -eq $deviceName) {
                    Set-ItemProperty -Path $adapter.PSPath -Name "PnPCapabilities" -Value 24 -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $adapter.PSPath -Name "*WakeOnMagicPacket" -Value 0 -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $adapter.PSPath -Name "*WakeOnPattern" -Value 0 -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $adapter.PSPath -Name "*DeviceSleepOnDisconnect" -Value 0 -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $adapter.PSPath -Name "EnablePME" -Value 0 -ErrorAction SilentlyContinue
                }
            }
        }
        
        # USB Root Hubs and Controllers - Critical for preventing USB power saving
        if ($device.Class -eq 'USB' -or $deviceName -like "*USB*" -or $deviceName -like "*Root Hub*") {
            $usbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$instanceId"
            if (Test-Path $usbRegPath) {
                Set-ItemProperty -Path $usbRegPath -Name "AllowIdleIrpInD3" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "$usbRegPath\Device Parameters" -Name "SelectiveSuspendEnabled" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "$usbRegPath\Device Parameters" -Name "SelectiveSuspendOn" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "$usbRegPath\Device Parameters" -Name "EnhancedPowerManagementEnabled" -Value 0 -ErrorAction SilentlyContinue
            }
        }
        
    }
    catch {
        Write-Host "[-] Error processing: $deviceName - $($_.Exception.Message)" -ForegroundColor Red
        $errorDevices++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Devices Scanned: $totalDevices" -ForegroundColor White
Write-Host "Devices Modified: $modifiedDevices" -ForegroundColor Green
Write-Host "Errors Encountered: $errorDevices" -ForegroundColor $(if ($errorDevices -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Disable USB Selective Suspend globally
Write-Host "[*] Disabling USB Selective Suspend globally..." -ForegroundColor Yellow
try {
    # For plugged in (AC)
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1030-4bd2-94d2-a1c1fe687b17 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    # For on battery (DC)
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1030-4bd2-94d2-a1c1fe687b17 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    # Apply the changes
    powercfg /setactive SCHEME_CURRENT
    Write-Host "[+] USB Selective Suspend disabled globally" -ForegroundColor Green
}
catch {
    Write-Host "[-] Error disabling USB Selective Suspend: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable Link State Power Management for PCI Express
Write-Host "[*] Disabling PCI Express Link State Power Management..." -ForegroundColor Yellow
try {
    # For plugged in (AC)
    powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
    # For on battery (DC)
    powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
    # Apply the changes
    powercfg /setactive SCHEME_CURRENT
    Write-Host "[+] PCI Express Link State Power Management disabled" -ForegroundColor Green
}
catch {
    Write-Host "[-] Error disabling PCI Express ASPM: $($_.Exception.Message)" -ForegroundColor Red
}

# Disable hard disk sleep
Write-Host "[*] Disabling hard disk sleep..." -ForegroundColor Yellow
try {
    # For plugged in (AC) - 0 means never turn off
    powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
    # For on battery (DC)
    powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
    # Apply the changes
    powercfg /setactive SCHEME_CURRENT
    Write-Host "[+] Hard disk sleep disabled" -ForegroundColor Green
}
catch {
    Write-Host "[-] Error disabling hard disk sleep: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disabling Specific Unnecessary Devices" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Counter for disabled devices
$disabledCount = 0

# Define devices to disable (only if they exist and are safe to disable)
$devicesToDisable = @(
    # Display adapters - Intel graphics (only if you have dedicated GPU)
    @{ Pattern = "*Intel*HD Graphics*"; Category = "Display adapters"; Safe = $true },
    @{ Pattern = "*Intel*UHD Graphics*"; Category = "Display adapters"; Safe = $true },
    
    # Network adapters - WAN Miniports (usually not needed)
    @{ Pattern = "WAN Miniport*"; Category = "Network adapters"; Safe = $true },
    @{ Pattern = "*ISATAP*"; Category = "Network adapters"; Safe = $true },
    
    # Storage controllers - iSCSI (only if not using iSCSI)
    @{ Pattern = "*iSCSI*"; Category = "Storage controllers"; Safe = $true },
    
    # System devices
    @{ Pattern = "*Composite Bus Enumerator*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Intel Management Engine*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Intel*ME*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*AMD PSP*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*SPI*Controller*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Microsoft GS Wavetable Synth*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Virtual Drive Enumerator*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*NDIS Virtual Network Adapter Enumerator*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Remote Desktop Device Redirector Bus*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*SMBus*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*System speaker*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*Terminal Server*"; Category = "System devices"; Safe = $true },
    @{ Pattern = "*UMBus*"; Category = "System devices"; Safe = $true }
)

foreach ($deviceInfo in $devicesToDisable) {
    try {
        # Find matching devices
        $matchingDevices = Get-PnpDevice | Where-Object { 
            $_.FriendlyName -like $deviceInfo.Pattern -and 
            ($_.Status -eq 'OK' -or $_.Status -eq 'Unknown')
        }
        
        foreach ($device in $matchingDevices) {
            try {
                # Check if it's safe to disable (not critical for system boot)
                $isCritical = $false
                
                # Don't disable if it's the only display adapter
                if ($deviceInfo.Category -eq "Display adapters") {
                    $allDisplayAdapters = Get-PnpDevice | Where-Object { $_.Class -eq 'Display' -and $_.Status -eq 'OK' }
                    if ($allDisplayAdapters.Count -le 1) {
                        Write-Host "[!] Skipping $($device.FriendlyName) - Only display adapter detected" -ForegroundColor Yellow
                        $isCritical = $true
                    }
                }
                
                if (-not $isCritical) {
                    # Disable the device
                    Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
                    Write-Host "[+] Disabled: $($device.FriendlyName)" -ForegroundColor Green
                    $disabledCount++
                }
            }
            catch {
                # If we can't disable it, it might be in use or protected - skip silently
                Write-Host "[!] Could not disable $($device.FriendlyName) - may be in use" -ForegroundColor Yellow
            }
        }
    }
    catch {
        # Silently continue if device type doesn't exist
        continue
    }
}

Write-Host ""
Write-Host "[+] Disabled $disabledCount unnecessary devices" -ForegroundColor Green

Write-Host ""
Write-Host "[!] IMPORTANT: A system restart is recommended for all changes to take full effect." -ForegroundColor Yellow
Write-Host ""

