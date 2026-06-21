<# Contains code from LeanAndMean, code modified to match with XOS Playbook needs.
Copyright (c) 2021 AveYo
Licensed under MIT License
#>

$logDir = 'C:\ProgramData\AME\Logs'
if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir 'DefenderOFF.log'
function Log($msg) { $ts = Get-Date -Format 'HH:mm:ss'; "$ts $msg" | Out-File -FilePath $logFile -Append -Encoding utf8 }

Log '=== DefenderOFF.ps1 started ==='
Log "Username: $([environment]::username)"
Log "PID: $PID"
Log "PSVersion: $($PSVersionTable.PSVersion)"
Log "WorkingDir: $(Get-Location)"

$op = "Disable"
$O1 = 0                        # do not re-enable TamperProtection on Enable
$O2 = 1                        # toggle SmartScreen as well
$TOGGLE_SMARTSCREENFILTER = $O2
$id = "Defender"
$key = 'HKLM:'                 # not used in SYSTEM context; set to valid path so rp call is silently harmless

## -- begin $code block (verbatim from ToggleDefender, runs as SYSTEM) --
try {
 $I=[int32]; $M=$I.module.gettype("System.Runtime.Interop`Services.Mar`shal"); $P=$I.module.gettype("System.Int`Ptr"); $S=[string]
 $D=@(); $DM=[AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1); $U=[uintptr]; $Z=[uintptr]::size
 0..5|% {$D += $DM."Defin`eType"("AveYo_$_",1179913,[ValueType])}; $D += $U; 4..6|% {$D += $D[$_]."MakeByR`efType"()}; $F=@()
 $F+='kernel','CreateProcess',($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), 'advapi','RegOpenKeyEx',($U,$S,$I,$I,$D[9])
 $F+='advapi','RegSetValueEx',($U,$S,$I,$I,[byte[]],$I),'advapi','RegFlushKey',($U),'advapi','RegCloseKey',($U)
 0..4|% {$9=$D[0]."DefinePInvok`eMethod"($F[3*$_+1], $F[3*$_]+"32", 8214,1,$S, $F[3*$_+2], 1,4)}
 $DF=($P,$I,$P),($I,$I,$I,$I,$P,$D[1]),($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P),($D[3],$P),($P,$P,$I,$I)
 1..5|% {$k=$_; $n=1; $DF[$_-1]|% {$9=$D[$k]."Defin`eField"("f" + $n++, $_, 6)}}; $T=@(); 0..5|% {$T += $D[$_]."Creat`eType"()}
 0..5|% {nv "A$_" ([Activator]::CreateInstance($T[$_])) -fo}; function F ($1,$2) {$T[0]."G`etMethod"($1).invoke(0,$2)}
 function M ($1,$2,$3) {$M."G`etMethod"($1,[type[]]$2).invoke(0,$3)}; $H=@(); $Z,(4*$Z+16)|% {$H += M "AllocHG`lobal" $I $_}
 Log 'P/Invoke setup OK'
} catch {
 Log "P/Invoke setup FAILED: $_"
}

try {
 if ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value -ne 'S-1-5-18') {
   Log 'Not running as SYSTEM, creating TI process...'
   $TI="Trusted`Installer"; start-service $TI -ea 0; $As=get-process -name $TI -ea 0
   M "WriteInt`Ptr" ($P,$P) ($H[0],$As.Handle); $A1.f1=131072; $A1.f2=$Z; $A1.f3=$H[0]; $A2.f1=1; $A2.f2=1; $A2.f3=1; $A2.f4=1
   $A2.f6=$A1; $A3.f1=10*$Z+32; $A4.f1=$A3; $A4.f2=$H[1]; M "StructureTo`Ptr" ($D[2],$P,[boolean]) (($A2 -as $D[2]),$A4.f2,$false)
   $R=@($null, "powershell -nop -c iex(`$env:R); # $id", 0, 0, 0, 0x0E080610, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
   F 'CreateProcess' $R; Log 'TI process created, returning'; return
 }
 Log 'Running as SYSTEM, continuing inline'
 $env:R=''; rp $key $id -force -ea 0; $e=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
 Log "SetPrivilege method: $($e -ne $null)"
 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {
   try { $e.Invoke($null,@("$_",2)); Log "Privilege OK: $_" } catch { Log "Privilege FAILED: $_ - $($_.Exception.Message)" }
 }
} catch {
 Log "Privilege/TI section FAILED: $_"
}
## Toggling was unreliable due to multiple windows programs with open handles on these keys
## so went with low-level functions instead! do not use them in other scripts without a trip to learn-microsoft-com
function RegSetDwords ($hive, $key, [array]$values, [array]$dword, $REG_TYPE=4, $REG_ACCESS=2, $REG_OPTION=0) {
  $rok = ($hive, $key, $REG_OPTION, $REG_ACCESS, ($hive -as $D[9]));  F "RegOpenKeyEx" $rok; $rsv = $rok[4]
  Log "RegOpenKeyEx '$key' handle=$($rsv[0])"
  $values |% {$i = 0} { F "RegSetValueEx" ($rsv[0], [string]$_, 0, $REG_TYPE, [byte[]]($dword[$i]), 4); $i++ }
  F "RegFlushKey" @($rsv); F "RegCloseKey" @($rsv); $rok = $null; $rsv = $null;
}
################################################################################################################################

 ## get script options
 $toggle = @(0,1)[$op -eq "Disable"]; $toggle_rev = @(0,1)[$op -eq "Enable"]
 $ENABLE_TAMPER_PROTECTION = $O1; $TOGGLE_SMARTSCREENFILTER = $O2

 rnp "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" "Disabled_Old" -force -ea 0
 sp "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1 -type Dword -force -ea 0
 stop-service "wscsvc" -force -ea 0 >$null 2>$null
 kill -name "OFFmeansOFF","MpCmdRun" -force -ea 0

 $HKLM = [uintptr][uint32]2147483650; $HKU = [uintptr][uint32]2147483651
 $VALUES = "ServiceKeepAlive","PreviousRunningMode","IsServiceRunning","DisableAntiSpyware","DisableAntiVirus","PassiveMode"
 $DWORDS = 0, 0, 0, $toggle, $toggle, $toggle
 Log "RegSetDwords pass 1: Policies\Microsoft\Windows Defender"
 RegSetDwords $HKLM "SOFTWARE\Policies\Microsoft\Windows Defender" $VALUES $DWORDS
 Log "RegSetDwords pass 1: Microsoft\Windows Defender"
 RegSetDwords $HKLM "SOFTWARE\Microsoft\Windows Defender" $VALUES $DWORDS
 [GC]::Collect(); sleep 1

 $defDir = "$env:programfiles\Windows Defender"
 Log "Defender dir exists: $(Test-Path $defDir)"
 pushd $defDir -ea 0
 Log "Current dir after pushd: $(Get-Location)"
 $mpcmdrun=("OFFmeansOFF.exe","MpCmdRun.exe")[(test-path "MpCmdRun.exe")]
 Log "MpCmdRun executable: $mpcmdrun (exists: $(Test-Path $mpcmdrun))"
 if (Test-Path $mpcmdrun) {
   Log "Running $mpcmdrun -DisableService -HighPriority"
   start -wait $mpcmdrun -args "-DisableService -HighPriority"
   Log "MpCmdRun completed"
 } else {
   Log "SKIPPED: $mpcmdrun not found"
 }
 $wait=@(3,14)[$op -eq "Disable"]
 Log "Waiting for MsMpEng to exit (max $wait seconds)"
 while ((get-process -name "MsMpEng" -ea 0) -and $wait -gt 0) {$wait--; sleep 1}
 $msmpenRunning = [bool](get-process -name "MsMpEng" -ea 0)
 Log "MsMpEng still running: $msmpenRunning"

 ## OFF means OFF
 $svcImagePath = (gp "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" ImagePath -ea 0).ImagePath
 Log "WinDefend ImagePath: $svcImagePath"
 if ($svcImagePath) {
   pushd (split-path $svcImagePath.Trim('"')) -ea 0
   Log "Platform dir: $(Get-Location)"
   if ($op -eq "Disable") {ren MpCmdRun.exe OFFmeansOFF.exe -force -ea 0; Log 'Renamed MpCmdRun -> OFFmeansOFF'} else {ren OFFmeansOFF.exe MpCmdRun.exe -force -ea 0}
 } else {
   Log 'WinDefend ImagePath not found, skipping rename'
 }

 ## clear per-user toggle notifications
 gi "Registry::HKU\S-1-5-21-*\Software\Microsoft\Windows\CurrentVersion" |% {
   $n1=join-path $_.PSPath "Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"
   ni $n1 -force -ea 0|out-null; ri $n1.replace("Settings","Current") -recurse -force -ea 0
   if ($op -eq "Enable") {rp $n1 "Enabled" -force -ea 0} else {sp $n1 "Enabled" 0 -type Dword -force -ea 0}
   ri "HKLM:\Software\Microsoft\Windows Security Health\State\Persist" -recurse -force -ea 0
 }

 ## clear old scan history
 if ($op -eq "Disable") {del "$env:ProgramData\Microsoft\Windows Defender\Scans\mpenginedb.db" -force -ea 0}
 if ($op -eq "Disable") {del "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service" -recurse -force -ea 0}

 Log "RegSetDwords pass 2: Policies\Microsoft\Windows Defender"
 RegSetDwords $HKLM "SOFTWARE\Policies\Microsoft\Windows Defender" $VALUES $DWORDS
 Log "RegSetDwords pass 2: Microsoft\Windows Defender"
 RegSetDwords $HKLM "SOFTWARE\Microsoft\Windows Defender" $VALUES $DWORDS

 ## toggle SmartScreen
 if ($TOGGLE_SMARTSCREENFILTER -ne 0) {
   sp "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" 'VerifiedAndReputablePolicyState' 0 -type Dword -force -ea 0
   sp "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" 'SmartScreenEnabled' @('Off','Warn')[$toggle -eq 0] -force -ea 0
   gi Registry::HKEY_Users\S-1-5-21*\Software\Microsoft -ea 0 |% {
     sp "$($_.PSPath)\Windows\CurrentVersion\AppHost" 'EnableWebContentEvaluation' $toggle_rev -type Dword -force -ea 0
     sp "$($_.PSPath)\Windows\CurrentVersion\AppHost" 'PreventOverride' $toggle_rev -type Dword -force -ea 0
     ni "$($_.PSPath)\Edge\SmartScreenEnabled" -Force -ea 0 > $null
     sp "$($_.PSPath)\Edge\SmartScreenEnabled" "(Default)" $toggle_rev -ea 0
   }
   if ($toggle_rev -eq 0) {
     kill -name smartscreen -force -ea 0
     ren "$env:SystemRoot\System32\smartscreen.exe" 'smartscreen.old' -force -ea 0
     Log 'smartscreen.exe renamed to smartscreen.old'
   } else {
     $ssOld = "$env:SystemRoot\System32\smartscreen.old"
     if (Test-Path $ssOld) { ren $ssOld 'smartscreen.exe' -force -ea 0; Log 'smartscreen.old renamed back to smartscreen.exe' }
   }
   Log 'SmartScreen toggled'
 }

 ## re-enable TamperProtection if toggling back on (skipped when O1=0)
 if ($ENABLE_TAMPER_PROTECTION -ne 0 -and $op -eq "Enable") {
   RegSetDwords $HKLM "SOFTWARE\Microsoft\Windows Defender\Features" ("TamperProtection","TamperProtectionSource") (1,5)
 }

 if ($op -eq "Enable") {start-service "windefend" -ea 0}
 start-service "wscsvc" -ea 0 >$null 2>$null
 if ($op -eq "Enable") {rnp "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled_Old" "Disabled" -force -ea 0}
## -- end $code block --

Log '=== DefenderOFF.ps1 finished ==='
