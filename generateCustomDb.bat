@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
    where py >nul 2>&1
    if errorlevel 1 (
        echo Python not found. Install Python or add it to PATH.
        pause
        exit /b 1
    )
    py -3 "%~dp0generateCustomDb.py"
) else (
    python "%~dp0generateCustomDb.py"
)

exit /b %ERRORLEVEL%
