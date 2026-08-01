@echo off
cd /d %~dp0

echo ==========================================
echo   Stopping OpenChamber Web UI
echo ==========================================
echo.

echo [1/2] Stopping OpenChamber...
call openchamber stop >nul 2>&1
timeout /t 2 /nobreak >nul
echo  [OK] OpenChamber stopped.

echo [2/2] Freeing port 2048...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":2048 " ^| findstr LISTENING') do (
  echo  PID %%p is listening on port 2048, force killing...
  taskkill /f /t /pid %%p >nul 2>&1
)
echo  [OK] Port 2048 is free.

echo ==========================================
echo  Web UI stopped
echo ==========================================
pause
