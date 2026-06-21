$toolsDir = Join-Path $env:windir 'FSOS\Tools'
New-Item -ItemType Directory -Path $toolsDir -Force -ErrorAction SilentlyContinue | Out-Null

$srcExe = Join-Path $PSScriptRoot 'SetTimerResolution.exe'
$dstExe = Join-Path $toolsDir 'SetTimerResolution.exe'

try { Unregister-ScheduledTask -TaskName 'FSOS-TimerSet' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
try { Unregister-ScheduledTask -TaskName 'TimerSet' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
try { Unregister-ScheduledTask -TaskName 'FSOS-TimerResolution' -Confirm:$false -ErrorAction SilentlyContinue } catch {}

Get-Process -Name 'SetTimerResolution' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $dstExe) {
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $fs = [System.IO.File]::Open($dstExe, 'Open', 'ReadWrite', 'None')
            $fs.Close()
            break
        } catch {
            Get-Process -Name 'SetTimerResolution' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 250
        }
    }
}

if (Test-Path $srcExe) {
    Copy-Item -Path $srcExe -Destination $dstExe -Force -ErrorAction SilentlyContinue
}

$staleTimerSet = Join-Path $toolsDir 'TimerSet.exe'
if (Test-Path $staleTimerSet) { Remove-Item -Path $staleTimerSet -Force -ErrorAction SilentlyContinue }

if (-not (Test-Path $dstExe)) { exit 0 }

$q = [char]34
$xml = ''
$xml += '<?xml version=' + $q + '1.0' + $q + ' encoding=' + $q + 'UTF-16' + $q + '?>' + "`r`n"
$xml += '<Task version=' + $q + '1.4' + $q + ' xmlns=' + $q + 'http://schemas.microsoft.com/windows/2004/02/mit/task' + $q + '>' + "`r`n"
$xml += '  <RegistrationInfo>' + "`r`n"
$xml += '    <Description>Sets the timer resolution to the lowest possible value for better desktop and multimedia responsiveness.</Description>' + "`r`n"
$xml += '    <URI>\FSOS-TimerResolution</URI>' + "`r`n"
$xml += '  </RegistrationInfo>' + "`r`n"
$xml += '  <Triggers>' + "`r`n"
$xml += '    <BootTrigger>' + "`r`n"
$xml += '      <Enabled>true</Enabled>' + "`r`n"
$xml += '    </BootTrigger>' + "`r`n"
$xml += '  </Triggers>' + "`r`n"
$xml += '  <Principals>' + "`r`n"
$xml += '    <Principal id=' + $q + 'Author' + $q + '>' + "`r`n"
$xml += '      <UserId>S-1-5-18</UserId>' + "`r`n"
$xml += '      <RunLevel>HighestAvailable</RunLevel>' + "`r`n"
$xml += '    </Principal>' + "`r`n"
$xml += '  </Principals>' + "`r`n"
$xml += '  <Settings>' + "`r`n"
$xml += '    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>' + "`r`n"
$xml += '    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>' + "`r`n"
$xml += '    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>' + "`r`n"
$xml += '    <AllowHardTerminate>false</AllowHardTerminate>' + "`r`n"
$xml += '    <StartWhenAvailable>true</StartWhenAvailable>' + "`r`n"
$xml += '    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>' + "`r`n"
$xml += '    <IdleSettings>' + "`r`n"
$xml += '      <StopOnIdleEnd>false</StopOnIdleEnd>' + "`r`n"
$xml += '      <RestartOnIdle>false</RestartOnIdle>' + "`r`n"
$xml += '    </IdleSettings>' + "`r`n"
$xml += '    <AllowStartOnDemand>true</AllowStartOnDemand>' + "`r`n"
$xml += '    <Enabled>true</Enabled>' + "`r`n"
$xml += '    <Hidden>true</Hidden>' + "`r`n"
$xml += '    <RunOnlyIfIdle>false</RunOnlyIfIdle>' + "`r`n"
$xml += '    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>' + "`r`n"
$xml += '    <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>' + "`r`n"
$xml += '    <WakeToRun>false</WakeToRun>' + "`r`n"
$xml += '    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>' + "`r`n"
$xml += '    <Priority>4</Priority>' + "`r`n"
$xml += '    <RestartOnFailure>' + "`r`n"
$xml += '      <Interval>PT1M</Interval>' + "`r`n"
$xml += '      <Count>999</Count>' + "`r`n"
$xml += '    </RestartOnFailure>' + "`r`n"
$xml += '  </Settings>' + "`r`n"
$xml += '  <Actions Context=' + $q + 'Author' + $q + '>' + "`r`n"
$xml += '    <Exec>' + "`r`n"
$xml += '      <Command>' + $dstExe + '</Command>' + "`r`n"
$xml += '      <Arguments>--resolution 5000 --no-console</Arguments>' + "`r`n"
$xml += '    </Exec>' + "`r`n"
$xml += '  </Actions>' + "`r`n"
$xml += '</Task>' + "`r`n"

$xmlPath = Join-Path $env:TEMP 'fsos-timerres-task.xml'
$xml | Set-Content -Path $xmlPath -Encoding Unicode -Force -ErrorAction SilentlyContinue
& schtasks.exe /Create /TN 'FSOS-TimerResolution' /XML $xmlPath /F 2>&1 | Out-Null
Remove-Item -Path $xmlPath -Force -ErrorAction SilentlyContinue
& schtasks.exe /Run /TN 'FSOS-TimerResolution' 2>&1 | Out-Null

try { Unregister-ScheduledTask -TaskName 'FSOS-LowAudioLatency' -Confirm:$false -ErrorAction SilentlyContinue } catch {}
$staleLA = Join-Path $toolsDir 'low_audio_latency.exe'
if (Test-Path $staleLA) { Remove-Item -Path $staleLA -Force -ErrorAction SilentlyContinue }

exit 0
