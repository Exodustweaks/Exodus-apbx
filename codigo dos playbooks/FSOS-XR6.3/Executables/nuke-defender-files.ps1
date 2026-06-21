Start-Sleep 5
foreach ($d in @(
  (Join-Path $env:ProgramFiles 'Windows Defender'),
  (Join-Path $env:ProgramFiles 'Windows Defender Advanced Threat Protection'),
  (Join-Path ${env:ProgramFiles(x86)} 'Windows Defender'),
  (Join-Path $env:ProgramData 'Microsoft\Windows Defender'),
  (Join-Path $env:ProgramData 'Microsoft\Windows Defender Advanced Threat Protection')
)) {
  if (Test-Path $d) {
    & takeown.exe /F $d /R /A /D Y 2>&1 | Out-Null
    & icacls.exe $d /reset /T /C /Q 2>&1 | Out-Null
    & icacls.exe $d /grant Administrators:F /T /C /Q 2>&1 | Out-Null
    & icacls.exe $d /grant '*S-1-5-18:(OI)(CI)F' /T /C /Q 2>&1 | Out-Null
    Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $d) {
      Get-ChildItem -Path $d -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
          & takeown.exe /F $_.FullName /A 2>&1 | Out-Null
          & icacls.exe $_.FullName /reset /C /Q 2>&1 | Out-Null
          & icacls.exe $_.FullName /grant Administrators:F /C /Q 2>&1 | Out-Null
          if ($_.PSIsContainer) {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
          } else {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
          }
        } catch {}
      }
      & cmd.exe /c ('rmdir /s /q "' + $d + '"') 2>&1 | Out-Null
    }
  }
}
foreach ($svc in @('WinDefend','WdFilter','WdNisDrv','WdBoot','WdNisSvc','MsSecFlt','MsSecWfp','MsSecCore','SecurityHealthService','Sense','wscsvc','MDCoreSvc','SgrmAgent','SgrmBroker','webthreatdefsvc','webthreatdefusersvc')) {
  $key = "HKLM\SYSTEM\CurrentControlSet\Services\$svc"
  $r = reg query $key /ve 2>&1
  if ($LASTEXITCODE -eq 0) {
    reg delete $key /f 2>&1 | Out-Null
  }
}
try { Unregister-ScheduledTask -TaskName 'FSOSDefenderCleanup' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
$fsosDir = Join-Path $env:windir 'FSOS'
foreach ($f in @('fsos-options.txt','fsos-pkgs-current.txt')) {
  $fp = Join-Path $fsosDir $f
  if (Test-Path $fp) { Remove-Item -Path $fp -Force -ErrorAction SilentlyContinue }
}
$toolsDir = Join-Path $fsosDir 'Tools'
foreach ($f in @('nuke-defender-files.ps1','nuke-defender-launcher.vbs','defender-cleanup.ps1','defender-cleanup.log')) {
  $fp = Join-Path $toolsDir $f
  if (Test-Path $fp) { Remove-Item -Path $fp -Force -ErrorAction SilentlyContinue }
}
$winreAgent = Join-Path $env:SystemDrive '$WinREAgent'
if (Test-Path $winreAgent) { Remove-Item -Path $winreAgent -Recurse -Force -ErrorAction SilentlyContinue }
exit 0
