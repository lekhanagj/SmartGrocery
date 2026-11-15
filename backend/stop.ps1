# stop.ps1 - Stop SmartGrocery backend
$Port = 8000

$conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $conn) {
    Write-Host "Nothing is running on port $Port." -ForegroundColor Yellow
    exit 0
}

$procId = $conn.OwningProcess
Write-Host "Stopping process $procId on port $Port..." -ForegroundColor Cyan
Stop-Process -Id $procId -Force

$waited = 0
while ($waited -lt 5) {
    Start-Sleep -Seconds 1
    $waited++
    if (-not (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)) {
        Write-Host "Stopped." -ForegroundColor Green
        exit 0
    }
}

Write-Host "Process $procId still listening after 5 seconds." -ForegroundColor Red
exit 1