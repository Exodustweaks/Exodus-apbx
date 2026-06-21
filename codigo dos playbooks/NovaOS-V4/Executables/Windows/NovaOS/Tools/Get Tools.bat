@echo off

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://download.sysinternals.com/files/Autoruns.zip','Autoruns.zip')"
powershell -Command "Expand-Archive -Path 'Autoruns.zip' -DestinationPath '.' -Force"
del Autoruns.zip

del autoruns.chm 2>nul
del Autoruns.exe 2>nul
del Autoruns64a.exe 2>nul
del autorunsc.exe 2>nul
del autorunsc64.exe 2>nul
del autorunsc64a.exe 2>nul
del Eula.txt 2>nul

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://github.com/spddl/GoInterruptPolicy/releases/download/v1.7.2/GoInterruptPolicy.exe','GoInterruptPolicy.exe')"

set ZIP=msiutil.zip
set URL=https://github.com/Sathango/Msi-Utility-v3/archive/refs/heads/main.zip

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%URL%', '%ZIP%')"
powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '.' -Force"
del %ZIP%

for %%d in (Msi-Utility-v3-main*) do (
    if exist "%%d\Msi Utility v3.exe" copy /Y "%%d\Msi Utility v3.exe" .
    rmdir /s /q "%%d"
)

set ZIP=msiutil.zip
set URL=https://github.com/Sathango/Msi-Utility-v3/archive/refs/heads/main.zip

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%URL%', '%ZIP%')"
powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '.' -Force"
del %ZIP%

for /d %%d in (Msi-Utility-v3-main*) do (
    if exist "%%d\Msi Utility v3.exe" copy /Y "%%d\Msi Utility v3.exe" .
    rmdir /s /q "%%d"
)

set CRU_ZIP=CRU.zip
set CRU_URL=https://customresolutionutility.net/wp-content/uploads/cru-1.5.3.zip

if not exist "CRU" mkdir CRU
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%CRU_URL%', '%CRU_ZIP%')"
powershell -Command "Expand-Archive -Path '%CRU_ZIP%' -DestinationPath 'CRU' -Force"
del %CRU_ZIP%

set SCEWIN_ZIP=SCEWIN.zip
set SCEWIN_URL=https://github.com/Lukefn123/Apps/releases/download/v1/SCEWIN.zip

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%SCEWIN_URL%', '%SCEWIN_ZIP%')"
powershell -Command "Expand-Archive -Path '%SCEWIN_ZIP%' -DestinationPath '.' -Force"
del %SCEWIN_ZIP%