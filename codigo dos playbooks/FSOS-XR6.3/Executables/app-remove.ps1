[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string[]]$Packages,

    [Parameter(Mandatory=$false)]
    [switch]$Unregister
)

$ErrorActionPreference = 'SilentlyContinue'

$AppxStoreRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'

function Stop-PackageProcesses {
    param($PackageRecord)

    $installRoot = $null
    try {
        $matched = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageFullName -eq $PackageRecord.PackageFullName } |
            Select-Object -First 1
        if ($matched) { $installRoot = $matched.InstallLocation }
    } catch {}

    if ($installRoot) {
        Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
            $procPath = $null
            try { $procPath = $_.Path } catch {}
            if ($procPath -and $procPath.StartsWith($installRoot, [StringComparison]::OrdinalIgnoreCase)) {
                try { $_ | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
    }

    $publisherToken = ($PackageRecord.PackageFamilyName -split '_', 2)[0]
    if ($publisherToken) {
        Get-Process -Name "*$publisherToken*" -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

function Block-PackageReinstall {
    param([string]$FamilyName, [string]$FullName)

    $deprovKey = Join-Path $AppxStoreRoot "Deprovisioned\$FamilyName"
    if (-not (Test-Path -LiteralPath $deprovKey)) {
        New-Item -Path $deprovKey -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $inboxKey = Join-Path $AppxStoreRoot "InboxApplications\$FullName"
    if (Test-Path -LiteralPath $inboxKey) {
        Remove-Item -LiteralPath $inboxKey -Force -ErrorAction SilentlyContinue
    }
}

function Clear-NonRemovableFlag {
    param($PackageRecord)

    if ($PackageRecord.NonRemovable -eq 1) {
        try {
            Set-NonRemovableAppsPolicy -Online -PackageFamilyName $PackageRecord.PackageFamilyName -NonRemovable 0 -ErrorAction SilentlyContinue | Out-Null
        } catch {}
    }
}

function Invoke-Removal {
    param(
        [string]$FullName,
        [string]$Scope,
        [bool]$KeepRoamable
    )

    $argMap = @{ Package = $FullName; ErrorAction = 'SilentlyContinue' }
    if ($Scope -eq 'AllUsers') {
        $argMap['AllUsers'] = $true
    } else {
        $argMap['User'] = $Scope
    }
    if ($KeepRoamable) {
        $argMap['PreserveRoamableApplicationData'] = $true
    }

    try { Remove-AppxPackage @argMap } catch {}
}

$installedSnapshot = @()
try {
    $installedSnapshot = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
        Select-Object PackageFullName, PackageFamilyName, PackageUserInformation, NonRemovable)
} catch {}

$keepRoamable = [bool]$Unregister

foreach ($pattern in $Packages) {
    $needle = "*$pattern*"

    $hits = $installedSnapshot | Where-Object { $_.PackageFullName -like $needle }
    if (-not $hits) { continue }

    foreach ($entry in $hits) {
        $famName  = $entry.PackageFamilyName
        $fullName = $entry.PackageFullName

        Block-PackageReinstall -FamilyName $famName -FullName $fullName
        Clear-NonRemovableFlag -PackageRecord $entry

        Stop-PackageProcesses -PackageRecord $entry
        Start-Sleep -Milliseconds 200

        if ($entry.PackageUserInformation) {
            foreach ($userRec in $entry.PackageUserInformation) {
                $thisSid = $null
                try { $thisSid = $userRec.UserSecurityID.SID } catch {}
                if (-not $thisSid) { continue }

                Invoke-Removal -FullName $fullName -Scope $thisSid -KeepRoamable $keepRoamable
            }
        }

        Invoke-Removal -FullName $fullName -Scope 'AllUsers' -KeepRoamable $keepRoamable
    }
}
