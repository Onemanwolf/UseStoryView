# Debug Helper Script
# This script helps setup VS Code debugging for the TCP Proxy

Write-Host "=== TCP Proxy Debug Setup ===" -ForegroundColor Green

# Check if we're in the right directory
if (!(Test-Path "main.go")) {
    Write-Host "ERROR: main.go not found. Please run this from the tcp-proxy-container-app directory." -ForegroundColor Red
    exit 1
}

# Check VS Code configuration
if (!(Test-Path ".vscode\launch.json")) {
    Write-Host "ERROR: .vscode\launch.json not found." -ForegroundColor Red
    exit 1
}

Write-Host "✓ main.go found" -ForegroundColor Green
Write-Host "✓ .vscode\launch.json found" -ForegroundColor Green

# Verify Go module
if (Test-Path "go.mod") {
    Write-Host "✓ go.mod found" -ForegroundColor Green
} else {
    Write-Host "Initializing Go module..." -ForegroundColor Yellow
    go mod init tcp-proxy
    go mod tidy
}

# Test environment variables from launch.json
Write-Host "`n=== Testing Debug Configuration ===" -ForegroundColor Green
Write-Host "Environment variables that will be set during debugging:"
Write-Host "  WEB_API_ENDPOINT: https://httpbin.org/post" -ForegroundColor Cyan
Write-Host "  TCP_PORT: 8080" -ForegroundColor Cyan
Write-Host "  METRICS_PORT: 9090" -ForegroundColor Cyan

Write-Host "`n=== Instructions ===" -ForegroundColor Green
Write-Host "1. Open VS Code in this directory: code ." -ForegroundColor White
Write-Host "2. Set a breakpoint on line 64 (the environment variable check)" -ForegroundColor White
Write-Host "3. Press F5 or go to Run and Debug panel" -ForegroundColor White
Write-Host "4. Select 'Launch TCP Proxy' configuration" -ForegroundColor White
Write-Host "5. Click the green play button or press F5" -ForegroundColor White

Write-Host "`n=== Opening VS Code ===" -ForegroundColor Green
code .
