@echo off
cd /d %~dp0
set "SCRIPT_DIR=%CD%"

echo ==========================================
echo   Starting all services...
echo ==========================================
echo.

echo [1/4] Starting OpenCode Server (headless API) on port 4096...

REM Check for zombie port 4096 (LISTENING with dead process)
:check_zombie_4096
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":4096 " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if not errorlevel 1 (
    echo  [..] Detected zombie port 4096, waiting for release...
    timeout /t 3 /nobreak >nul
    goto check_zombie_4096
  )
)

start "opencode-server" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='opencode'; opencode serve --hostname 0.0.0.0 --port 4096"

echo  Waiting for port 4096...
:wait_4096
timeout /t 2 /nobreak >nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":4096 " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if errorlevel 1 (
    tasklist /fi "PID eq %%p" 2>nul | findstr /i "opencode" >nul
    if not errorlevel 1 goto port_4096_ready
    for /f "tokens=1" %%n in ('tasklist /fi "PID eq %%p" /nh 2^>nul') do (
      echo  [WARN] Port 4096 is occupied by unexpected process: %%n (PID %%p)
      echo          To free it: taskkill /f /pid %%p
    )
  )
)
goto wait_4096
:port_4096_ready
echo  [OK] OpenCode Server is ready.
echo.

echo [2/4] Starting OpenChamber (Web UI) on port 3000...

start "openchamber-ui" pwsh -NoLogo -Command "$env:OPENCODE_PORT='4096'; $env:OPENCODE_SKIP_START='true'; $env:OPENCODE_SERVER_PASSWORD='opencode'; openchamber --port 3000"

echo  Waiting for port 3000...
:wait_3000
timeout /t 2 /nobreak >nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if errorlevel 1 (
    tasklist /fi "PID eq %%p" 2>nul | findstr /i "node" >nul
    if not errorlevel 1 goto port_3000_ready
    for /f "tokens=1" %%n in ('tasklist /fi "PID eq %%p" /nh 2^>nul') do (
      echo  [WARN] Port 3000 is occupied by unexpected process: %%n (PID %%p)
      echo          To free it: taskkill /f /pid %%p
    )
  )
)
goto wait_3000
:port_3000_ready
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
start "opencode-tui" pwsh -NoLogo -Command "$env:OPENCODE_SERVER_PASSWORD='opencode'; opencode attach http://localhost:4096 -c"
echo  [OK] Terminal TUI attached.
echo.

echo ==========================================
echo  All services started successfully!
echo ==========================================
echo.
echo  OpenChamber UI:      http://localhost:3000
echo  OpenCode API:        http://localhost:4096
echo  Username: opencode
echo  Password: opencode
echo.
echo  Terminal TUI:        attached to same server
echo  WeChat bot:          shares sessions with all UIs
echo.
echo  Stop all:            stop-all.bat
echo.

pause
