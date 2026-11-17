@echo off
:: Fresh Mart Launcher (batch fallback)
:: Finds Godot and launches the game

setlocal enabledelayedexpansion

set "APP_DIR=%~dp0"
set "GODOT_EXE="

:: Check WinGet symlink
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    goto :launch
)

:: Search WinGet packages
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine*") do (
    for /d %%S in ("%%D\*") do (
        for %%F in ("%%S\Godot_v*.exe") do (
            echo %%F | findstr /i "unin" >nul 2>&1
            if errorlevel 1 (
                set "GODOT_EXE=%%F"
                goto :launch
            )
        )
    )
)

:: Check Program Files
if exist "C:\Program Files\Godot\Godot_v4.3-stable_win64.exe" (
    set "GODOT_EXE=C:\Program Files\Godot\Godot_v4.3-stable_win64.exe"
    goto :launch
)

:: Not found — try winget install
echo Godot 4 not found. Attempting installation via winget...
winget install GodotEngine.GodotEngine --silent --accept-package-agreements --accept-source-agreements

:: Check again
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    goto :launch
)

echo.
echo Could not find or install Godot 4.
echo Please install it from: https://godotengine.org/download/windows/
echo Then run this launcher again.
pause
exit /b 1

:launch
echo Launching Fresh Mart with: !GODOT_EXE!
start "" "!GODOT_EXE!" --path "%APP_DIR%."
exit /b 0
