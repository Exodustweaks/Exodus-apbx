@echo off
:: balanced
powercfg -import "C:\envy\power plan\default power plans\Balanced.pow" 381b4222-f694-41f0-9685-ff5bb260df2e>nul 2>&1

:: battery-life overlay
powercfg -import "C:\envy\power plan\default power plans\Better Battery-life Overlay.pow" 961cc777-2547-4f9d-8174-7d86181b8a7a>nul 2>&1

:: high perf overlay
powercfg -import "C:\envy\power plan\default power plans\High Performance Overlay.pow" 3af9b8d9-7c97-431d-ad78-34a8bfea439f>nul 2>&1

:: high perf
powercfg -import "C:\envy\power plan\default power plans\High performance.pow" 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c>nul 2>&1

:: max perf overlay
powercfg -import "C:\envy\power plan\default power plans\Max Performance Overlay.pow" ded574b5-45a0-4f42-8737-46345c09c238>nul 2>&1

:: power saver
powercfg -import "C:\envy\power plan\default power plans\Power saver.pow" a1841308-3541-4fab-bc81-f71556f20b4a>nul 2>&1

:: ultimate perf
powercfg -import "C:\envy\power plan\default power plans\Ultimate Performance.pow" e9a42b02-d5df-448d-aa00-03f14749eb61>nul 2>&1