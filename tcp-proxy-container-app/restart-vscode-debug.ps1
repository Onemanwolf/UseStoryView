# Script to restart VS Code with proper workspace configuration
Write-Host "Closing current VS Code instances..." -ForegroundColor Yellow
taskkill /F /IM Code.exe 2>$null

Start-Sleep -Seconds 2

Write-Host "Opening VS Code with tcp-proxy workspace..." -ForegroundColor Green
Set-Location "C:\Users\timot\UseStoryView\tcp-proxy-container-app"
code .

Write-Host "VS Code should now open with proper debug configuration!" -ForegroundColor Green
Write-Host ""
Write-Host "To debug:" -ForegroundColor Cyan
Write-Host "1. Open main.go" -ForegroundColor White
Write-Host "2. Set a breakpoint (click left margin on line 131: log.Printf)" -ForegroundColor White
Write-Host "3. Press F5 or go to Run and Debug panel" -ForegroundColor White
Write-Host "4. Select 'Launch TCP Proxy' configuration" -ForegroundColor White
Write-Host "5. Click the green play button" -ForegroundColor White
Write-Host ""
Write-Host "Environment variables are now set in launch.json:" -ForegroundColor Cyan
Write-Host "- WEB_API_ENDPOINT: https://httpbin.org/post" -ForegroundColor White
Write-Host "- TCP_PORT: 8080" -ForegroundColor White
Write-Host "- METRICS_PORT: 9090" -ForegroundColor White
