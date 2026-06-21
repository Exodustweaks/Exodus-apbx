@echo off
CD /d %~dp0
DevManView.exe /disable "PCI Encryption/Decryption Controller" > NUL 2>&1
DevManView.exe /disable "AMD PSP" > NUL 2>&1
DevManView.exe /disable "Intel SMBus" > NUL 2>&1
DevManView.exe /disable "Intel Management Engine" > NUL 2>&1
DevManView.exe /disable "PCI Memory Controller" > NUL 2>&1
DevManView.exe /disable "PCI standard RAM Controller" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (IKEv2)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (IP)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (IPv6)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (L2TP)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (Network Monitor)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (PPPOE)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (PPTP)" > NUL 2>&1
DevManView.exe /disable "WAN Miniport (SSTP)" > NUL 2>&1
DevManView.exe /disable "Programmable Interrupt Controller" > NUL 2>&1
DevManView.exe /disable "Numeric Data Processor" > NUL 2>&1
DevManView.exe /disable "Communications Port (COM1)" > NUL 2>&1
DevManView.exe /disable "Microsoft GS Wavetable Synth" > NUL 2>&1
