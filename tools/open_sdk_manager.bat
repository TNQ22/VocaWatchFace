@echo off
setlocal
echo ========================================================
echo   Garmin Connect IQ SDK Manager
echo ========================================================
echo Dang khoi dong Garmin SDK Manager...
echo.
echo Huong dan:
echo 1. Dang nhap tai khoan Garmin cua ban (neu duoc yeu cau).
echo 2. Vao muc "Devices" -> Chon "Forerunner 245 Music" (hoac thiet bi ban muon).
echo 3. Bam "Download" de tai profile thiet bi ve may.
echo ========================================================
start "" "%~dp0..\.dev_tools\garmin-sdk-manager\sdkmanager.exe"
