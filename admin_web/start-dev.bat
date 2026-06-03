@echo off
cd /d "%~dp0"
if not exist "node_modules\vite" (
  echo Installing dependencies... this may take a few minutes.
  set NODE_OPTIONS=--use-system-ca
  call npm install
  if errorlevel 1 (
    echo npm install failed. Check your internet connection and try again.
    pause
    exit /b 1
  )
)
call npm run dev
