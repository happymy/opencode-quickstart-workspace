@echo off
cd /d %~dp0

REM ========== Configurable variables (edit as needed) ==========
set "OPENCODE_PORT=4096"
set "OPENCODE_HOST=0.0.0.0"
set "OPENCODE_USER=opencode"
set "OPENCODE_PASSWORD=opencode"
set "OPENCHAMBER_PORT=2048"
REM =============================================

REM Start OpenCode server if not running
netstat -ano | findstr ":%OPENCODE_PORT% " | findstr LISTENING >nul 2>&1
if errorlevel 1 (
  start "opencode-server" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='%OPENCODE_PASSWORD%'; opencode serve --hostname %OPENCODE_HOST% --port %OPENCODE_PORT%"
)

REM Start OpenChamber Web UI
pwsh -NoLogo -Command "$env:OPENCODE_PORT='%OPENCODE_PORT%'; $env:OPENCODE_SKIP_START='true'; $env:OPENCODE_SERVER_PASSWORD='%OPENCODE_PASSWORD%'; openchamber --port %OPENCHAMBER_PORT%"
