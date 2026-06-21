
Write-Host "Setting up Post-Install Folder Icon..."

$folderPath = "$env:USERPROFILE\Desktop\PeakOS Post Install"
$iconDest = "$folderPath\icon.ico"

# Ensure the folder exists (it should via copy)
if (-not (Test-Path $folderPath)) {
    Write-Warning "Post-Install folder not found at $folderPath"
    return
}

# Ensure the icon exists
if (-not (Test-Path $iconDest)) {
    Write-Warning "icon.ico not found in $folderPath. Icon modification skipped."
    return
}

# Set proper attributes for the folder (Read Only is required for desktop.ini to be read)
$folderItem = Get-Item $folderPath
$folderItem.Attributes = 'ReadOnly'

# Set proper attributes for desktop.ini (Hidden, System)
$iniPath = "$folderPath\desktop.ini"
if (Test-Path $iniPath) {
    Set-ItemProperty -Path $iniPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System)
}

Write-Host "Folder icon configuration applied." -ForegroundColor Green
