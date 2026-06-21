$ErrorActionPreference = 'SilentlyContinue'

$personalizationMarker = Join-Path $env:windir 'FSOS\.personalization-applied'
if (Test-Path $personalizationMarker) {
    $global:LASTEXITCODE = 0
    exit 0
}

$RegFavoritesResolve = '320300004C0000000114020000000000C0000000000000468300800020000000549E39A5246AD8012B113CA5246AD801A8B6C6DADDACD501970100000000000001000000000000000000000000000000A0013A001F80C827341F105C1042AA032EE45287D668260001002600EFBE1200000056F21270246AD8010F37A185246AD8012B113CA5246AD80114005600310000000000B154E29B11005461736B42617200400009000400EFBEB154C69BB154E29B2E000000F4940100000001000000000000000000000000000000D5BA89005400610073006B00420061007200000016000E01320097010000874F0749200046494C4545587E312E4C4E4B00007C0009000400EFBEB154E29BB154E29B2E00000097900100000002000000000000000000520000000000589C4400460069006C00650020004500780070006C006F007200650072002E006C006E006B00000040007300680065006C006C00330032002E0064006C006C002C002D003200320030003600370000001C00220000001E00EFBE02005500730065007200500069006E006E006500640000001C00120000002B00EFBE2B113CA5246AD8011C00420000001D00EFBE02004D006900630072006F0073006F00660074002E00570069006E0064006F00770073002E004500780070006C006F0072006500720000001C0000009B0000001C000000010000001C0000002D000000000000009A0000001100000003000000E4A63B761000000000433A5C55736572735C757365725C417070446174615C526F616D696E675C4D6963726F736F66745C496E7465726E6574204578706C6F7265725C517569636B204C61756E63685C557365722050696E6E65645C5461736B4261725C46696C65204578706C6F7265722E6C6E6B000060000000030000A05800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045000000090000A03900000031535053B1166D44AD8D7048A748402EA43D788C1D000000680000000048000000CE2181FCD4BF31408F25FF009E4345CA000000000000000000000000'

$RegFavorites = '00A40100003A001F80C827341F105C1042AA032EE45287D668260001002600EFBE1200000056F21270246AD8010F37A185246AD8012B113CA5246AD80114005600310000000000B154E29B11005461736B42617200400009000400EFBEB154C69BB154E29B2E000000F4940100000001000000000000000000000000000000D5BA89005400610073006B00420061007200000016001201320097010000874F0749200046494C4545587E312E4C4E4B00007C0009000400EFBEB154E29BB154E29B2E00000097900100000002000000000000000000520000000000589C4400460069006C00650020004500780070006C006F007200650072002E006C006E006B00000040007300680065006C006C00330032002E0064006C006C002C002D003200320030003600370000001C00120000002B00EFBE2B113CA5246AD8011C00420000001D00EFBE02004D006900630072006F0073006F00660074002E00570069006E0064006F00770073002E004500780070006C006F0072006500720000001C00260000001E00EFBE0200530079007300740065006D00500069006E006E006500640000001C000000FF'

function ConvertTo-ByteArray {
    param([string]$Hex)
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $Hex.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($Hex.Substring($i, 2), 16)
    }
    return ,$bytes
}

$favBytes = ConvertTo-ByteArray $RegFavorites
$favResolveBytes = ConvertTo-ByteArray $RegFavoritesResolve

$suppressedAuxPins = @(
    'MailPin','OutlookPin','OutlookWebPin','CopilotPin','CopilotPWAPin','StorePin','DevHomePin',
    'EdgePin','WidgetsPin','ChatPin','TaskViewPin','PhotosPin','SettingsPin','XboxPin','GamingPin',
    'BingPin','ClipchampPin','PhonePin','PhoneLinkPin','TodoPin','LinkedInPin','SpotifyPin',
    'TeamsPin','MailNewPin','OutlookNewPin','GetStartedPin','NotepadPin','SnippingToolPin'
)

function Resolve-UserAppDataRoot {
    param([string]$HiveSid, [string]$HivePath, [bool]$IsDefaultTemplate)

    if ($IsDefaultTemplate) {
        return @{
            Local   = "$env:SystemDrive\Users\Default\AppData\Local"
            Roaming = "$env:SystemDrive\Users\Default\AppData\Roaming"
        }
    }

    $local = $null
    $roaming = $null

    $shellFolders = "$HivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    $sf = Get-ItemProperty -Path $shellFolders -ErrorAction SilentlyContinue
    if ($sf) {
        $local = $sf.'Local AppData'
        $roaming = $sf.'AppData'
    }

    if ([string]::IsNullOrEmpty($local) -or [string]::IsNullOrEmpty($roaming) -or -not (Test-Path $local)) {
        $profileEntry = "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$HiveSid"
        $profileImage = (Get-ItemProperty -Path $profileEntry -Name 'ProfileImagePath' -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profileImage -and (Test-Path $profileImage)) {
            if ([string]::IsNullOrEmpty($local)   -or -not (Test-Path $local))   { $local   = Join-Path $profileImage 'AppData\Local' }
            if ([string]::IsNullOrEmpty($roaming) -or -not (Test-Path $roaming)) { $roaming = Join-Path $profileImage 'AppData\Roaming' }
        }
    }

    return @{ Local = $local; Roaming = $roaming }
}

function Write-TaskbandPins {
    param([string]$TaskbandKey)

    if ([string]::IsNullOrEmpty($TaskbandKey)) { return }
    New-Item -Path $TaskbandKey -Force -ErrorAction SilentlyContinue | Out-Null

    Set-ItemProperty -Path $TaskbandKey -Name 'Favorites' -Value $favBytes -Type Binary -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $TaskbandKey -Name 'FavoritesResolve' -Value $favResolveBytes -Type Binary -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $TaskbandKey -Name 'FavoritesVersion' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $TaskbandKey -Name 'FavoritesChanges' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $TaskbandKey -Name 'Pinned' -Force -ErrorAction SilentlyContinue

    $auxKey = Join-Path $TaskbandKey 'AuxilliaryPins'
    New-Item -Path $auxKey -Force -ErrorAction SilentlyContinue | Out-Null
    foreach ($pinName in $suppressedAuxPins) {
        Set-ItemProperty -Path $auxKey -Name $pinName -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

function Ensure-FileExplorerShortcut {
    param([string]$RoamingAppData)

    if ([string]::IsNullOrEmpty($RoamingAppData)) { return }
    if (-not (Test-Path $RoamingAppData)) { return }

    $taskBarFolder = Join-Path $RoamingAppData 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
    New-Item -ItemType Directory -Path $taskBarFolder -Force -ErrorAction SilentlyContinue | Out-Null

    Get-ChildItem -Path $taskBarFolder -File -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension -eq '.lnk' -and $_.Name -ne 'File Explorer.lnk'
    } | Remove-Item -Force -ErrorAction SilentlyContinue

    $implicitFolder = Join-Path $taskBarFolder 'ImplicitAppShortcuts'
    if (Test-Path $implicitFolder) {
        Get-ChildItem -Path $implicitFolder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    $explorerLnk = Join-Path $taskBarFolder 'File Explorer.lnk'

    $needsCreate = $true
    if (Test-Path $explorerLnk) {
        $existing = Get-Item -LiteralPath $explorerLnk -Force -ErrorAction SilentlyContinue
        if ($existing -and $existing.Length -gt 0) {
            $needsCreate = $false
        } else {
            Remove-Item -LiteralPath $explorerLnk -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not $needsCreate) { return }

    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        $shellApi = $null
        try {
            $shellApi = New-Object -ComObject WScript.Shell -ErrorAction SilentlyContinue
            if ($shellApi) {
                $sc = $shellApi.CreateShortcut($explorerLnk)
                $sc.TargetPath = (Join-Path $env:windir 'explorer.exe')
                $sc.IconLocation = (Join-Path $env:windir 'System32\shell32.dll') + ',-22067'
                $sc.Save()
                if ($sc) {
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sc) | Out-Null
                }
            }
        } catch {}
        finally {
            if ($shellApi) {
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shellApi) | Out-Null
            }
        }

        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 250

        $created = Get-Item -LiteralPath $explorerLnk -Force -ErrorAction SilentlyContinue
        if ($created -and $created.Length -gt 0) { return }

        if (Test-Path $explorerLnk) {
            Remove-Item -LiteralPath $explorerLnk -Force -ErrorAction SilentlyContinue
        }
    }
}

$defaultTemplateRoaming = "$env:SystemDrive\Users\Default\AppData\Roaming"
Ensure-FileExplorerShortcut -RoamingAppData $defaultTemplateRoaming

$liveHives = Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | Where-Object {
    ($_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$') -or
    ($_.PSChildName -match '^AME_UserHive_')
}

foreach ($hive in $liveHives) {
    $sid = $hive.PSChildName
    $hivePath = "Registry::HKU\$sid"
    $isDefault = $sid -match '^AME_UserHive_'

    $taskbandKey = "$hivePath\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
    Write-TaskbandPins -TaskbandKey $taskbandKey

    $appDataDirs = Resolve-UserAppDataRoot -HiveSid $sid -HivePath $hivePath -IsDefaultTemplate $isDefault
    Ensure-FileExplorerShortcut -RoamingAppData $appDataDirs.Roaming
}

try {
    $apiSignature = @'
[DllImport("shell32.dll")]
public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
'@
    $shellApi = Add-Type -MemberDefinition $apiSignature -Name 'FSOSPinRefresh' -Namespace 'FSOS' -PassThru -ErrorAction SilentlyContinue
    if ($shellApi) {
        $shellApi::SHChangeNotify(0x08000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)
    }
} catch {}

$global:LASTEXITCODE = 0
