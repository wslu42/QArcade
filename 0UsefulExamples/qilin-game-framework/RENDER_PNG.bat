@echo off
setlocal EnableExtensions
cd /d "%~dp0"

call :ensure_env
if errorlevel 1 exit /b 1

if not exist "previews" mkdir "previews"

echo Rendering Qilin preview with layout guide lines...
".venv\Scripts\python.exe" tools\render_preview_guided.py ^
  framework\qilin_game_framework_4Qv.p8 ^
  -o previews\current.png ^
  --native-output previews\current_128x128.png ^
  --metadata-output previews\current.json

if errorlevel 1 (
  echo.
  echo Preview render failed.
  pause
  exit /b 1
)

start "" "%CD%\previews\current.png"
exit /b 0

:ensure_env
if exist ".venv\Scripts\python.exe" goto check_dependencies

echo Creating local preview environment...
where py >nul 2>nul
if not errorlevel 1 (
  py -3 -m venv .venv
) else (
  python -m venv .venv
)

if errorlevel 1 (
  echo Python 3 was not found or the virtual environment could not be created.
  echo Install Python 3 and enable the Python launcher, then try again.
  pause
  exit /b 1
)

:check_dependencies
".venv\Scripts\python.exe" -c "import PIL" >nul 2>nul
if not errorlevel 1 exit /b 0

echo Installing preview dependencies. This only happens on first use...
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
  echo Dependency installation failed.
  pause
  exit /b 1
)
exit /b 0
