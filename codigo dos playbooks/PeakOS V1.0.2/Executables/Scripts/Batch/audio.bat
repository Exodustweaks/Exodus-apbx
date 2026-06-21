@echo off
set aud_key=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio
set maud_key=HKCU\Software\Microsoft\Multimedia\Audio

:: disable BCMStartupLatency
Reg.exe add "%aud_key%" /v DisableExemptionForBCMStartupLatency /t REG_DWORD /d 1 /f >nul

:: disable audio capture monitoring
Reg.exe add "%aud_key%" /v EnableCaptureMonitor /t REG_DWORD /d 0 /f >nul

:: disable audio notification policy
Reg.exe add "%aud_key%" /v DisableToastPolicy /t REG_DWORD /d 1 /f >nul

:: acoustic echo cancellation history
Reg.exe add "%aud_key%" /v DisableAecStateHistory /t REG_DWORD /d 1 /f >nul

:: disable pump backup timer
Reg.exe add "%aud_key%" /v DisablePumpBackupTimer /t REG_DWORD /d 1 /f >nul

:: disable ducking preference
Reg.exe add "%maud_key%" /v UserDuckingPreference /t REG_DWORD /d 3 /f >nul
Reg.exe add "%maud_key%" /v ScreenReaderDuckingPreference /t REG_DWORD /d 0 /f >nul

:: disable audio mono
Reg.exe add "%maud_key%" /v AccessibilityMonoMixState /t REG_DWORD /d 0 /f >nul

:: disable microphone notification policy
Reg.exe add "%maud_key%" /v MicrophonePrivacyToastFired /t REG_DWORD /d 0 /f >nul

:: disable spatial audio (user override)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v DisableSpatialAudioGlobal /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v DisableSpatialAudioVssFeature /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v SpatialAudioHrtfOnByDefault /t REG_DWORD /d 0 /f