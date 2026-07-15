@echo off
cd /d %~dp0
set "SCRIPT_DIR=%CD%"

echo ==========================================
echo   Starting pk-opencode-webui (port 2048)
echo ==========================================
echo.

REM Kill zombie port 2048 if any
:check_zombie_2048
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":2048 " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if not errorlevel 1 (
    echo  [..] Detected zombie port 2048, waiting for release...
    timeout /t 3 /nobreak >nul
    goto check_zombie_2048
  )
)

start "pk-opencode-webui" pwsh -NoLogo -Command "cd '%SCRIPT_DIR%\pk-opencode-webui\app-prefixable'; $env:PORT='2048'; $env:API_AUTH_USERNAME='opencode'; $env:API_AUTH_PASSWORD='opencode'; bun run dev"

echo  Waiting for port 2048...
:wait_2048
timeout /t 2 /nobreak >nul
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":2048 " ^| findstr LISTENING') do (
  tasklist /fi "PID eq %%p" 2>nul | findstr /c:"No tasks" >nul
  if errorlevel 1 (
    tasklist /fi "PID eq %%p" 2>nul | findstr /i "bun" >nul
    if not errorlevel 1 goto port_2048_ready
    for /f "tokens=1" %%n in ('tasklist /fi "PID eq %%p" /nh 2^>nul') do (
      echo  [WARN] Port 2048 is occupied by unexpected process: %%n (PID %%p)
      echo          To free it: taskkill /f /pid %%p
    )
  )
)
goto wait_2048
:port_2048_ready
echo  [OK] pk-opencode-webui is ready at http://localhost:2048
echo.
pause
