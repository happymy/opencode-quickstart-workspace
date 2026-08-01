@echo off
cd /d %~dp0

REM ========== Configurable variables (edit as needed) ==========
set "OPENCHAMBER_PORT=2048"
REM =============================================

echo ==========================================
echo   Stopping OpenChamber Web UI
echo ==========================================
echo.

echo [1/2] Stopping OpenChamber...
call openchamber stop >nul 2>&1
timeout /t 2 /nobreak >nul
echo  [OK] OpenChamber stopped.

echo [2/2] Freeing port %OPENCHAMBER_PORT%...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%OPENCHAMBER_PORT% " ^| findstr LISTENING') do (
  echo  PID %%p is listening on port %OPENCHAMBER_PORT%, force killing...
  taskkill /f /t /pid %%p >nul 2>&1
)
echo  [OK] Port %OPENCHAMBER_PORT% is free.

echo ==========================================
echo  Web UI stopped
echo ==========================================
pause
