@echo off
setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0.."
set "JAVA_HOME=%PROJECT_DIR%\.dev_tools\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"

set "SDK_BIN=C:\Users\TNQ\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
set "DEVICE=fr245m"
set "OUTPUT_DIR=%PROJECT_DIR%\out"
set "PRG=%OUTPUT_DIR%\VocaWatchFace_%DEVICE%.prg"

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo ========================================================
echo   Building VocaWatchFace for %DEVICE%...
echo ========================================================

call "%SDK_BIN%\monkeyc.bat" -o "%PRG%" -f "%PROJECT_DIR%\monkey.jungle" -y "%PROJECT_DIR%\ci\developer_key.der" -d %DEVICE% -l 0

if %ERRORLEVEL% neq 0 (
    echo.
    echo [LOI] Khong the build ung dung!
    echo Neu bao loi "Invalid device id", vui long chay tools\open_sdk_manager.bat
    echo de dang nhap va tai profile thiet bi %DEVICE%.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [OK] Build thanh cong: %PRG%
echo ========================================================
echo   Khoi dong Garmin Connect IQ Simulator...
echo ========================================================

start "" "%SDK_BIN%\connectiq.bat"
timeout /t 3 /nobreak >nul

echo   Dang nap ung dung vao Simulator...
call "%SDK_BIN%\monkeydo.bat" "%PRG%" %DEVICE%

echo Hoan tat!
pause
