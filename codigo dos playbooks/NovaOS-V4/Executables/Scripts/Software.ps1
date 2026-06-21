param ([switch]$Chrome, [switch]$Brave, [switch]$Firefox, [switch]$Thorium)

if ($Brave) {curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "BraveSetup.exe"
Start-Process -FilePath "BraveSetup.exe" -ArgumentList '/silent /install' -WindowStyle Hidden -Wait
}

if ($Chrome) {curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -o "chrome.msi"
Start-Process -FilePath "chrome.msi" -ArgumentList '/qn' -WindowStyle Hidden -Wait
}

if ($Firefox) {curl.exe -LSs "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -o "firefox.exe"
Start-Process -FilePath "firefox.exe" -ArgumentList '/S /ALLUSERS=1' -WindowStyle Hidden -Wait
}

if ($Thorium) {curl.exe -LSs "https://github.com/Alex313031/Thorium-Win/releases/download/M130.0.6723.174/thorium_SSE3_mini_installer.exe" -o "thorium.exe"
Start-Process -FilePath "thorium.exe" -ArgumentList '/S' -WindowStyle Hidden -Wait
}

$sevenZipRelease = Invoke-WebRequest -Uri "https://api.github.com/repos/ip7z/7zip/releases/latest" -UseBasicParsing | ConvertFrom-Json
$sevenZip = ($sevenZipRelease.assets | Where-Object { $_.name -match "x64.exe" }).browser_download_url
curl.exe -LSs $sevenZip -o "$env:TEMP\7zip.exe"
Start-Process -Wait -FilePath "$env:TEMP\7zip.exe" -ArgumentList "/S"

$TEMP_DIR = "$env:TEMP\VC_Runtimes"
New-Item -Path $TEMP_DIR -ItemType Directory -Force
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x86.exe" -OutFile "$TEMP_DIR\vc2015-2022_x86.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$TEMP_DIR\vc2015-2022_x64.exe"
Start-Process -FilePath "$TEMP_DIR\vc2015-2022_x86.exe" -ArgumentList "/passive", "/norestart" -Wait
Start-Process -FilePath "$TEMP_DIR\vc2015-2022_x64.exe" -ArgumentList "/passive", "/norestart" -Wait
Remove-Item -Path $TEMP_DIR -Recurse -Force

$Url = "https://www.startallback.com/download.php"
$OutputPath = "$env:TEMP\StartAllBackSetup.exe"
curl.exe -LSs $Url -o $OutputPath
Start-Process -FilePath $OutputPath -ArgumentList "/install", "/silent", "/allusers"

$DestDir = "$env:SystemDrive\Windows\Misc"
New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
$Url = "https://github.com/Lukefn123/Stuff/releases/download/v1.0/nvidiaProfileInspector.exe"
$OutputPath = Join-Path $DestDir "nvidiaProfileInspector.exe"
curl.exe -LSs $Url -o $OutputPath

$Url = "https://app.prntscr.com/build/setup-lightshot.exe"
$OutputPath = "$env:TEMP\setup-lightshot.exe"
curl.exe -LSs $Url -o $OutputPath
Start-Process -FilePath $OutputPath -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART"