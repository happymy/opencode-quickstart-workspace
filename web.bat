@echo off
cd /d %~dp0

REM Start OpenCode server if not running
netstat -ano | findstr ":4096 " | findstr LISTENING >nul 2>&1
if errorlevel 1 (
  start "opencode-server" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='opencode'; opencode serve --hostname 0.0.0.0 --port 4096"
)

REM Start OpenChamber Web UI
pwsh -NoLogo -Command "$env:OPENCODE_PORT='4096'; $env:OPENCODE_SKIP_START='true'; $env:OPENCODE_SERVER_PASSWORD='opencode'; openchamber --port 3000"
