# start.ps1 - Start SmartGrocery backend in background
$ErrorActionPreference = "Stop"

$BackendPath = "C:\Users\Lekhana GJ\SmartGrocery\backend"
$PythonExe   = Join-Path $BackendPath "venv\Scripts\python.exe"
$LogDir      = Join-Path $BackendPath "logs"
$OutLog      = Join-Path $LogDir "out.log"
$ErrLog      = Join-Path $LogDir "err.log"
$Port        = 8000

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Port $Port is already in use (PID $($existing.OwningProcess))." -ForegroundColor Yellow
    Write-Host "Run stop.ps1 first if you want to restart." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting Uvicorn on port $Port..." -ForegroundColor Cyan
Start-Process -FilePath $PythonExe `
    -ArgumentList "-m","uvicorn","main:app","--host","127.0.0.1","--port","$Port" `
    -WindowStyle Hidden `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -WorkingDirectory $BackendPath

$waited = 0
while ($waited -lt 10) {
    Start-Sleep -Seconds 1
    $waited++
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
        $procId = (Get-NetTCPConnection -LocalPort $Port -State Listen).OwningProcess
        Write-Host "Backend running. PID: $procId" -ForegroundColor Green
        Write-Host "Docs:  http://127.0.0.1:$Port/docs" -ForegroundColor Green
        Write-Host "Logs:  $LogDir" -ForegroundColor Green
        exit 0
    }
}

Write-Host "Backend did not start within 10 seconds." -ForegroundColor Red
Write-Host "Check error log: $ErrLog" -ForegroundColor Red
Get-Content $ErrLog -Tail 20 -ErrorAction SilentlyContinue
exit 1