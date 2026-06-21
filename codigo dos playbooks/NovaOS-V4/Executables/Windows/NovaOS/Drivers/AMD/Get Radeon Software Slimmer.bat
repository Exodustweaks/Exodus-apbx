@echo off

set RADEON_ZIP=RadeonSoftwareSlimmer_1.12.0_net48.zip
set RADEON_URL=https://github.com/GSDragoon/RadeonSoftwareSlimmer/releases/download/1.12.0/RadeonSoftwareSlimmer_1.12.0_net48.zip

if not exist "Radeon Software Slimmer" mkdir "Radeon Software Slimmer"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%RADEON_URL%', '%RADEON_ZIP%')"
powershell -Command "Expand-Archive -Path '%RADEON_ZIP%' -DestinationPath 'Radeon Software Slimmer' -Force"
del %RADEON_ZIP%