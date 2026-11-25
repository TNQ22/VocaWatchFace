$sdk = "C:\Users\TNQ\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2"
Write-Host "--- Compiling PRG ---"
& "$sdk\bin\monkeyc.bat" -o "out\VocaWatchFace_fr245m.prg" -f "monkey.jungle" -y "ci\developer_key.der" -d fr245m -l 0
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!"
    exit 1
}

Write-Host "--- Pushing to Simulator ---"
java -classpath "$sdk\bin\monkeybrains.jar" com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux -f "out\VocaWatchFace_fr245m.prg" -d fr245m -s "$sdk\bin\shell.exe"

Start-Sleep -Seconds 3

Write-Host "--- Capturing Simulator Screenshot ---"
python tools\capture_sim.py
