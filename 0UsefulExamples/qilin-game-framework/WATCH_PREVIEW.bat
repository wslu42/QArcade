@echo off
setlocal EnableExtensions
cd /d "%~dp0"

call :ensure_env
if errorlevel 1 exit /b 1

if not exist "previews" mkdir "previews"

start "" "%CD%\preview_viewer.html"

echo.
echo Qilin live preview is running.
echo Save framework\qilin_game_framework.p8 to update the PNG.
echo Close this window or press Ctrl+C to stop watching.
echo.

".venv\Scripts\python.exe" tools\render_preview.py ^
  framework\qilin_game_framework.p8 ^
  -o previews\current.png ^
  --native-output previews\current_128x128.png ^
  --metadata-output previews\current.json ^
  --watch ^
  --poll-interval 0.15

exit /b %errorlevel%

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
