# Quick Debug Setup Script
# This script sets environment variables and starts the Go program for debugging

Write-Host "🔧 Setting up environment variables for debugging..." -ForegroundColor Green

# Set environment variables
$env:WEB_API_ENDPOINT = "https://httpbin.org/post"
$env:TCP_PORT = "8080"
$env:METRICS_PORT = "9090"
$env:MAX_CONNECTIONS = "100"
$env:CONNECTION_TIMEOUT = "30"
$env:WEB_API_AUTH_TOKEN = ""

Write-Host "✅ Environment variables set:" -ForegroundColor Green
Write-Host "  WEB_API_ENDPOINT: $env:WEB_API_ENDPOINT" -ForegroundColor Cyan
Write-Host "  TCP_PORT: $env:TCP_PORT" -ForegroundColor Cyan
Write-Host "  METRICS_PORT: $env:METRICS_PORT" -ForegroundColor Cyan

Write-Host "`n🚀 Starting TCP proxy for debugging..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

# Run the Go application
go run main.go
