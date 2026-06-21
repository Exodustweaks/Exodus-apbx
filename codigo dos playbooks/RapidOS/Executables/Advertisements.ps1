#Requires -RunAsAdministrator
param ([switch]$undo)

$file = 'SettingsExtensions.json'
$path = gci "$env:WinDir\SystemApps" -r | ? {$_.Name -eq $file} | Select -First 1 -Expand FullName
if (!$path) {
    Write-Host "User is likely on Windows 10. Exiting..." -F DarkGray
    exit
}

$bakDir = "$env:WinDir\RapidScripts"
$bak = Join-Path $bakDir $file

"SystemSettings", "ShellExperienceHost" | % {taskkill /f /im "${_}.exe" *>$null}

# ==============================
# Undo / Restore
# ==============================
if ($undo) {
    if (Test-Path $bakDir) {
        if (Test-Path $bak) {
            takeown /f $path /a *>$null
            icacls $path /grant *S-1-5-32-544:F /t /q *>$null
            copy $bak $path -Force
        }
        Write-Host "Restored original files." -F Green
    } else {
        Write-Host "Backup not found." -F Red
    }
    exit
}

# ==============================
# Backup operations
# ==============================
if (!(Test-Path $bakDir)) {mkdir $bakDir -Force *>$null}
if (!(Test-Path $bak)) {copy $path $bak -Force}

# ==============================
# JSON modification
# ==============================
$json = type $bak -Raw | ConvertFrom-Json

$blockList = "SubscriptionCard", "SubscriptionCard_Enterprise", "CopilotSubscriptionCard",
             "CopilotSubscriptionCard_Enterprise", "XboxSubscriptionCard",
             "XboxSubscriptionCard_Enterprise", "SignedOutCard", "SignedOutCard_SecondPlace",
             "SignedOutCard_Enterprise_AAD", "HomeSubscriptionHigherRankedCard",
             "SettingsPageYourMicrosoftAccount", "SettingsPageAccountsPicture", "SettingsPageGroupAccounts",
             "SettingsPageGroupAccounts_Home", "SettingsPageGroupHome", "SettingsPageHome"

$json.addedHomeCards = $json.addedHomeCards | ? {$blockList -notcontains $_.cardId}

$json.hiddenPages = $json.hiddenPages | % { 
    if ($_.pageGroupId -eq 'SettingsPageGroupAccounts' -and $_.conditions.velocityKey) {
        $_.conditions.velocityKey.default = 'disabled'
    }
    $_
}

$json.addedPages = $json.addedPages | % {
    if ($_.pageId -eq 'SettingsPageGroupAccounts_Home' -and $_.conditions.velocityKey) {
        $_.conditions.velocityKey.default = 'disabled'
    }
    $_
}

$temp = Join-Path $env:TEMP $file
$json | ConvertTo-Json -Depth 100 | Set-Content $temp

takeown /f $path /a *>$null
icacls $path /grant *S-1-5-32-544:F /t /q *>$null
copy $temp $path -Force
del $temp -Force *>$null

Write-Host "Done." -F Green