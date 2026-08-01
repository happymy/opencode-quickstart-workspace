@echo off
cd /d %~dp0
set "SCRIPT_DIR=%CD%"

REM ========== Configurable variables (edit as needed) ==========
set "OPENCODE_PORT=4096"
set "OPENCODE_HOST=0.0.0.0"
set "OPENCODE_USER=opencode"
set "OPENCODE_PASSWORD=opencode"
set "OPENCHAMBER_PORT=2048"
REM =============================================

echo ==========================================
echo   Starting all services...
echo ==========================================
echo.

echo [1/4] Starting OpenCode Server (headless API) on port %OPENCODE_PORT%...

REM Check for zombie port %OPENCODE_PORT% (LISTENING with dead process)
:check_zombie_4096
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%OPENCODE_PORT% " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if not errorlevel 1 (
    echo  [..] Detected zombie port %OPENCODE_PORT%, waiting for release...
    timeout /t 3 /nobreak >nul
    goto check_zombie_4096
  )
)

start "opencode-server" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='%OPENCODE_PASSWORD%'; opencode serve --hostname %OPENCODE_HOST% --port %OPENCODE_PORT%"

echo  Waiting for port %OPENCODE_PORT%...
:wait_4096
timeout /t 2 /nobreak >nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%OPENCODE_PORT% " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if errorlevel 1 (
    tasklist /fi "PID eq %%p" 2>nul | findstr /i "opencode" >nul
    if not errorlevel 1 goto port_4096_ready
    for /f "tokens=1" %%n in ('tasklist /fi "PID eq %%p" /nh 2^>nul') do (
      echo  [WARN] Port %OPENCODE_PORT% is occupied by unexpected process: %%n (PID %%p)
      echo          To free it: taskkill /f /pid %%p
    )
  )
)
goto wait_4096
:port_4096_ready
echo  [OK] OpenCode Server is ready.
echo.

echo [2/4] Starting OpenChamber (Web UI) on port %OPENCHAMBER_PORT%...

netstat -ano | findstr ":%OPENCHAMBER_PORT% " | findstr LISTENING >nul 2>&1
if errorlevel 1 (
  start "openchamber-ui" pwsh -NoLogo -Command "$env:OPENCODE_PORT='%OPENCODE_PORT%'; $env:OPENCODE_SKIP_START='true'; $env:OPENCODE_SERVER_PASSWORD='%OPENCODE_PASSWORD%'; openchamber --port %OPENCHAMBER_PORT%"
) else (
  echo  [OK] OpenChamber already running, reusing.
)

echo  Waiting for port %OPENCHAMBER_PORT%...
:wait_2048
timeout /t 2 /nobreak >nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%OPENCHAMBER_PORT% " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if errorlevel 1 (
    tasklist /fi "PID eq %%p" 2>nul | findstr /i "node bun" >nul
    if not errorlevel 1 goto port_2048_ready
    for /f "tokens=1" %%n in ('tasklist /fi "PID eq %%p" /nh 2^>nul') do (
      echo  [WARN] Port %OPENCHAMBER_PORT% is occupied by unexpected process: %%n (PID %%p)
      echo          To free it: taskkill /f /pid %%p
    )
  )
)
goto wait_2048
:port_2048_ready
echo  [OK] OpenChamber is ready.
echo.

echo [3/4] Starting WeChat bridge...
call npx wechat-acp@latest stop >nul 2>&1
start "wechat-bridge" pwsh -NoLogo -Command "npx -y wechat-acp@latest --agent 'node wechat-adapter.js' --cwd '%SCRIPT_DIR%'"

echo  Waiting for WeChat login...
:wait_wechat
timeout /t 3 /nobreak >nul
if exist "%USERPROFILE%\.wechat-acp\token.json" (
  echo  [OK] WeChat bridge is logged in.
) else (
  echo  Please scan the QR code in the new terminal window...
  goto wait_wechat
)
echo.

echo [next] Starting terminal attach...
start "opencode-tui" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='%OPENCODE_PASSWORD%'; opencode attach http://localhost:%OPENCODE_PORT% -c"
echo  [OK] Terminal TUI attached.
echo.

echo ==========================================
echo  All services started successfully!
echo ==========================================
echo.
echo  OpenChamber UI:      http://localhost:%OPENCHAMBER_PORT%
echo  OpenCode API:        http://localhost:%OPENCODE_PORT%
echo  Username: %OPENCODE_USER%
echo  Password: %OPENCODE_PASSWORD%
echo.
echo  Terminal TUI:        attached to same server
echo  WeChat bot:          shares sessions with all UIs
echo.
echo  Stop all:            stop-all.bat
echo.

pause
