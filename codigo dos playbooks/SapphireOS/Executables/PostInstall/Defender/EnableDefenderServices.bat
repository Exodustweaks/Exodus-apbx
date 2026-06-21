@echo off
for %%z in (
      MsSecCore
      MsSecFlt
      MsSecWfp
      SecurityHealthService
      Sense
      WdBoot
      WdFilter
      WdNisDrv
      WdNisSvc
      WinDefend
      wscsvc
      MDCoreSvc
      SgrmAgent
      SgrmBroker
      webthreatdefsvc
      webthreatdefusersvc
) do (
C:\PostInstall\Tweaks\MinSudo.exe --NoLogo --TrustedInstaller --Privileged cmd /c "Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "2" /f"
)