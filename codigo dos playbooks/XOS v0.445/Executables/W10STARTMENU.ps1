# Clear W10 Start Menu tiles

$currentBuild = [System.Environment]::OSVersion.Version.Build
if ($currentBuild -gt 20000) { exit }

$blankLayoutXml = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$defaultShell = "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\Shell"
if (-not (Test-Path $defaultShell)) { New-Item -Path $defaultShell -ItemType Directory -Force | Out-Null }
$blankLayoutXml | Out-File -FilePath "$defaultShell\LayoutModification.xml" -Encoding UTF8 -Force

$defaultLayouts = "$defaultShell\DefaultLayouts.xml"
if (Test-Path $defaultLayouts) { Remove-Item $defaultLayouts -Force -ErrorAction SilentlyContinue }

$userShell = "$env:LOCALAPPDATA\Microsoft\Windows\Shell"
if (-not (Test-Path $userShell)) { New-Item -Path $userShell -ItemType Directory -Force | Out-Null }
$blankLayoutXml | Out-File -FilePath "$userShell\LayoutModification.xml" -Encoding UTF8 -Force

$tempLayout = "$env:TEMP\BlankStartLayout.xml"
$blankLayoutXml | Out-File -FilePath $tempLayout -Encoding UTF8 -Force
try { Import-StartLayout -LayoutPath $tempLayout -MountPath "$env:SystemDrive\" -ErrorAction SilentlyContinue } catch {}
Remove-Item $tempLayout -Force -ErrorAction SilentlyContinue

$cloudStorePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount'
if (Test-Path $cloudStorePath) {
    Get-ChildItem -Path $cloudStorePath | Where-Object {
        $_.Name -like '*start.tilegrid$windows.data.primarytilecollection*' -or
        $_.Name -like '*start.tilegrid$windows.data.curatedtilecollection*'
    } | ForEach-Object {
        Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Get-ChildItem -Path "$userShell\*.bin" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'LockedStartLayout' -Value 1 -Type DWord -Force
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'StartLayoutFile' -Value "$userShell\LayoutModification.xml" -Type ExpandString -Force

Start-Process 'explorer.exe'
Start-Sleep -Seconds 3

Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'LockedStartLayout' -Value 0 -Type DWord -Force

Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process 'explorer.exe'
