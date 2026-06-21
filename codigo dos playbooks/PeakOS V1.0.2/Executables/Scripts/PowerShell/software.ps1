param (
	[switch]$Chrome,
	[switch]$Brave,
	[switch]$Firefox,
	[switch]$Thorium
)


if ($Brave) {
	curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "$env:TEMP\brave.exe"
	Start-Process -FilePath "$env:TEMP\brave.exe" -ArgumentList '/silent /install' -WindowStyle Hidden -Wait
}

if ($Chrome) {
	curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" -o "$env:TEMP\chrome.msi"
	Start-Process -FilePath "$env:TEMP\chrome.msi" -ArgumentList '/qn' -WindowStyle Hidden -Wait
}

if ($Firefox) {
	curl.exe -LSs "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" -o "$env:TEMP\firefox.exe"
	Start-Process -FilePath "$env:TEMP\firefox.exe" -ArgumentList '/S /ALLUSERS=1' -WindowStyle Hidden -Wait
}

if ($Thorium) {
	try {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$latest = Invoke-RestMethod -Uri "https://api.github.com/repos/Alex313031/Thorium-Win/releases/latest"
		$url = $latest.assets | Where-Object { $_.name -like "*mini_installer.exe" } | Select-Object -First 1 -ExpandProperty browser_download_url
		
		if ($url) {
			curl.exe -LSs $url -o "$env:TEMP\thorium.exe"
			Start-Process -FilePath "$env:TEMP\thorium.exe" -ArgumentList '/silent /install' -WindowStyle Hidden -Wait
		} else {
			Write-Error "Could not find Thorium download URL."
		}
	} catch {
		Write-Error "Failed to install Thorium: $_"
	}
}


# 7zip
Invoke-WebRequest "https://www.7-zip.org/a/7z2201-x64.exe" -OutFile "$env:TEMP\\7zip.exe"; Start-Process $env:TEMP\\7zip.exe -ArgumentList "/S" -Wait

# vcredist
Invoke-WebRequest "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$env:TEMP\\vcredist.exe"; Start-Process $env:TEMP\\vcredist.exe -ArgumentList "/quiet /norestart" -Wait

# openshell
Invoke-WebRequest "https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.191/OpenShellSetup_4_4_191.exe" -OutFile "$env:TEMP\\openshell.exe"; Start-Process $env:TEMP\\openshell.exe -ArgumentList "/qn ADDLOCAL=StartMenu" -Wait