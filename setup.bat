@echo off
cd /d %~dp0
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%CD%"

echo ==========================================
echo   Work workspace - Environment Setup
echo ==========================================
echo.

:: --- 0. pwsh (PowerShell 7+) — needed for version lock loading ---
echo [0] Checking PowerShell 7+...
where pwsh >nul 2>&1
if errorlevel 1 (
    echo  ! pwsh not found, installing via winget...
    winget install Microsoft.PowerShell -e --accept-source-agreements --accept-package-agreements >nul 2>&1
    if errorlevel 1 (
        echo  [FAIL] pwsh install failed. Download from https://github.com/PowerShell/PowerShell/releases
        pause
        exit /b 1
    ) else (
        echo  [OK] PowerShell 7+ installed
    )
)
echo.

:: --- Load locked versions from .tool-versions.json ---
echo [  ] Loading version locks...
for /f "tokens=*" %%v in ('pwsh -NoLogo -Command "$PSVersionTable.PSVersion.ToString()"') do set "PWSH_VER=%%v"
:: Generate temp PowerShell script to avoid cmd.exe pipe/quoting issues
>"%TEMP%\load-vers.ps1" (
  echo $c = Get-Content '.tool-versions.json' -Raw ^| ConvertFrom-Json
  echo echo ('LOCKED_NODE=' + $c.runtime.node^)
  echo echo ('LOCKED_NPM=' + $c.runtime.npm^)
  echo echo ('LOCKED_PWSH=' + $c.shell.pwsh^)
  echo echo ('LOCKED_PYTHON=' + $c.script.python^)
  echo echo ('LOCKED_GIT=' + $c.vcs.git^)
  echo echo ('LOCKED_OPENCODE_CLI=' + $c.opencode.cli^)
  echo echo ('LOCKED_OPENCHAMBER_CLI=' + $c.openchamber.cli^)
  echo echo ('LOCKED_WECHAT_ACP=' + $c.wechat.acp^)
)
for /f "delims=" %%v in ('pwsh -NoLogo -File "%TEMP%\load-vers.ps1"') do set %%v
del "%TEMP%\load-vers.ps1"
if not "!PWSH_VER!"=="%LOCKED_PWSH%" (
    echo  [WARN] PowerShell version !PWSH_VER! does not match locked version %LOCKED_PWSH%
)
echo   [OK] Version locks loaded
echo.

:: --- 1. Node.js ---
echo [1/5] Checking Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo  ! Node.js not found, installing via winget...
    winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements >nul 2>&1
    if errorlevel 1 (
        echo  [FAIL] Node.js install failed. Download from https://nodejs.org
    ) else (
        echo  [OK] Node.js installed
    )
) else (
    for /f "tokens=*" %%v in ('node --version') do set "NODE_VER=%%v"
    echo  [OK] Node.js !NODE_VER!  (locked: v%LOCKED_NODE%^)
    if not "!NODE_VER!"=="v%LOCKED_NODE%" (
        echo  [WARN] Version mismatch, expected v%LOCKED_NODE%
    )
)
echo.

:: --- 2. npm deps ---
echo [2/5] Installing workspace npm dependencies...
call npm install --ignore-scripts 2>&1
if errorlevel 1 (
    echo  [FAIL] npm install failed
) else (
    echo  [OK] npm dependencies installed
)
echo.

:: --- 3. opencode CLI (version locked) ---
echo [3/5] Checking opencode CLI...
where opencode >nul 2>&1
if errorlevel 1 (
    echo  ! opencode not found, installing v%LOCKED_OPENCODE_CLI%...
    call npm install -g opencode-windows-x64@%LOCKED_OPENCODE_CLI% 2>&1
    if errorlevel 1 (
        echo  [FAIL] opencode install failed
    ) else (
        echo  [OK] opencode v%LOCKED_OPENCODE_CLI% installed
    )
) else (
    for /f "tokens=*" %%v in ('opencode --version') do set "OPENCODE_VER=%%v"
    if "!OPENCODE_VER!"=="%LOCKED_OPENCODE_CLI%" (
        echo  [OK] opencode !OPENCODE_VER!
    ) else (
        echo  [WARN] opencode version !OPENCODE_VER! does not match locked version %LOCKED_OPENCODE_CLI%
    )
)
echo.
echo [4/5] Checking OpenChamber CLI...
where openchamber >nul 2>&1
if errorlevel 1 (
    echo  ! openchamber not found, installing v%LOCKED_OPENCHAMBER_CLI%...
    call npm install -g @openchamber/web@%LOCKED_OPENCHAMBER_CLI% 2>&1
    if errorlevel 1 (
        echo  [FAIL] openchamber install failed
    ) else (
        echo  [OK] openchamber v%LOCKED_OPENCHAMBER_CLI% installed
    )
) else (
    for /f "tokens=*" %%v in ('openchamber --version 2^>nul') do set "OPENCHAMBER_VER=%%v"
    echo  [OK] openchamber !OPENCHAMBER_VER!  (locked: v%LOCKED_OPENCHAMBER_CLI%^)
    if not "!OPENCHAMBER_VER!"=="v%LOCKED_OPENCHAMBER_CLI%" (
        echo  [WARN] openchamber version !OPENCHAMBER_VER! does not match locked version v%LOCKED_OPENCHAMBER_CLI%
    )
)
echo.

:: --- 5. wechat-acp (version locked) ---
echo [5/5] Refreshing wechat-acp (v%LOCKED_WECHAT_ACP%)...
pwsh -NoLogo -Command "$c='$env:LOCALAPPDATA\npm-cache\_npx';if(Test-Path $c){Remove-Item -Recurse -Force \"$c\*\" -ErrorAction SilentlyContinue}"
call npx -y wechat-acp@%LOCKED_WECHAT_ACP% --version 2>&1
if errorlevel 1 (
    echo  [FAIL] wechat-acp download failed
) else (
    echo  [OK] wechat-acp v%LOCKED_WECHAT_ACP% refreshed
)
echo.

echo ==========================================
echo   Setup complete! Run start-all.bat
echo ==========================================
echo   Version locks from .tool-versions.json:
echo     Node.js     %LOCKED_NODE%
echo     npm         %LOCKED_NPM%
echo     PowerShell  %LOCKED_PWSH%
echo     Python      %LOCKED_PYTHON%
echo     Git         %LOCKED_GIT%
echo     opencode    %LOCKED_OPENCODE_CLI%
echo     openchamber %LOCKED_OPENCHAMBER_CLI%
echo     wechat-acp  %LOCKED_WECHAT_ACP%
echo ==========================================
pause
