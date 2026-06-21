@echo off
:: Requires running as administrator

echo Disabling services...

:: Privacy Services
sc stop DiagTrack
sc config DiagTrack start= disabled

sc stop dmwappushservice
sc config dmwappushservice start= disabled

sc stop WerSvc
sc config WerSvc start= disabled

:: Performance Services
sc stop SysMain
sc config SysMain start= disabled

sc stop WSearch
sc config WSearch start= disabled

:: Network Services
sc stop RemoteRegistry
sc config RemoteRegistry start= disabled

sc stop TermService
sc config TermService start= disabled

sc stop RoutingAndRemoteAccess
sc config RoutingAndRemoteAccess start= disabled

sc stop SharedAccess
sc config SharedAccess start= disabled

:: Gaming Services
sc stop XblAuthManager
sc config XblAuthManager start= disabled

sc stop XblGameSave
sc config XblGameSave start= disabled

sc stop XboxNetApiSvc
sc config XboxNetApiSvc start= disabled

sc stop XboxGipSvc
sc config XboxGipSvc start= disabled

:: Device Services
sc stop bthserv
sc config bthserv start= disabled

sc stop lfsvc
sc config lfsvc start= disabled

sc stop MapsBroker
sc config MapsBroker start= disabled

sc stop FrameServer
sc config FrameServer start= disabled

sc stop WbioSrvc
sc config WbioSrvc start= disabled

sc stop SCardSvr
sc config SCardSvr start= disabled

sc stop SensorService
sc config SensorService start= disabled

sc stop PhoneSvc
sc config PhoneSvc start= disabled

:: Legacy Services
sc stop Fax
sc config Fax start= disabled

sc stop CscService
sc config CscService start= disabled

sc stop RetailDemo
sc config RetailDemo start= disabled

sc stop Spooler
sc config Spooler start= disabled

sc stop WpnService
sc config WpnService start= disabled

sc stop DPS
sc config DPS start= disabled

sc stop wisvc
sc config wisvc start= disabled

sc stop SessionEnv
sc config SessionEnv start= disabled

:: Additional Services
sc stop AxInstSV
sc config AxInstSV start= disabled

sc stop tzautoupdates
sc config tzautoupdates start= disabled

sc stop BthAvctpSvc
sc config BthAvctpSvc start= disabled

sc stop BluetoothUserService
sc config BluetoothUserService start= disabled

sc stop BcastDVRUserService
sc config BcastDVRUserService start= disabled

sc stop DoSvc
sc config DoSvc start= disabled

sc stop NaturalAuthentication
sc config NaturalAuthentication start= disabled

sc stop lltdsvc
sc config lltdsvc start= disabled

sc stop CDPUserSvc
sc config CDPUserSvc start= disabled

sc stop NetTcpPortSharing
sc config NetTcpPortSharing start= disabled

sc stop QWAVE
sc config QWAVE start= disabled

sc stop RemoteAccess
sc config RemoteAccess start= disabled

sc stop SensorDataService
sc config SensorDataService start= disabled

sc stop SensrSvc
sc config SensrSvc start= disabled

sc stop ShellHWDetection
sc config ShellHWDetection start= disabled

sc stop ScDeviceEnum
sc config ScDeviceEnum start= disabled

sc stop SSDPSRV
sc config SSDPSRV start= disabled

sc stop WiaRpc
sc config WiaRpc start= disabled

sc stop upnphost
sc config upnphost start= disabled

sc stop UserDataSvc
sc config UserDataSvc start= disabled

sc stop UevAgentService
sc config UevAgentService start= disabled

sc stop FrameServerMonitor
sc config FrameServerMonitor start= disabled

sc stop stisvc
sc config stisvc start= disabled

sc stop WpnUserService
sc config WpnUserService start= disabled

sc stop PrintWorkflowUserSv
sc config PrintWorkflowUserSv start= disabled

sc stop PrintNotify
sc config PrintNotify start= disabled

sc stop icssvc
sc config icssvc start= disabled

sc stop GpuEnergyDrv
sc config GpuEnergyDrv start= disabled

echo All selected services have been disabled.

