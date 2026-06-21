@echo off

set NVCLEAN_EXE=NVCleanstall_1.19.0.exe
set NVCLEAN_URL=https://github.com/Lukefn123/Apps/releases/download/v1/NVCleanstall_1.19.0.exe

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%NVCLEAN_URL%', '%NVCLEAN_EXE%')"