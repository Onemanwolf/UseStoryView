# Local Development Environment Setup
# This script sets up environment variables for local debugging and testing

param(
    [Parameter(Mandatory = $false)]
    [string]$WebApiEndpoint = "https://httpbin.org/post",

    [Parameter(Mandatory = $false)]
    [string]$WebApiAuthToken = "",

    [Parameter(Mandatory = $false)]
    [string]$TCPPort = "8080",

    [Parameter(Mandatory = $false)]
    [string]$MetricsPort = "9090"
)

Write-Host "🔧 Setting up local development environment..." -ForegroundColor Green

# Set environment variables
$env:WEB_API_ENDPOINT = $WebApiEndpoint
$env:WEB_API_AUTH_TOKEN = $WebApiAuthToken
$env:TCP_PORT = $TCPPort
$env:METRICS_PORT = $MetricsPort
$env:MAX_CONNECTIONS = "100"
$env:CONNECTION_TIMEOUT = "30"

Write-Host "✅ Environment variables set:" -ForegroundColor Green
Write-Host "  WEB_API_ENDPOINT: $env:WEB_API_ENDPOINT" -ForegroundColor Cyan
Write-Host "  TCP_PORT: $env:TCP_PORT" -ForegroundColor Cyan
Write-Host "  METRICS_PORT: $env:METRICS_PORT" -ForegroundColor Cyan
Write-Host "  MAX_CONNECTIONS: $env:MAX_CONNECTIONS" -ForegroundColor Cyan
Write-Host "  CONNECTION_TIMEOUT: $env:CONNECTION_TIMEOUT" -ForegroundColor Cyan

Write-Host "`n🚀 You can now:" -ForegroundColor Yellow
Write-Host "  1. Start debugging in VS Code (F5)" -ForegroundColor White
Write-Host "  2. Run: go run main.go" -ForegroundColor White
Write-Host "  3. Test with: telnet localhost $TCPPort" -ForegroundColor White
Write-Host "  4. Check health: curl http://localhost:$MetricsPort/health" -ForegroundColor White
Write-Host "  5. Check metrics: curl http://localhost:$MetricsPort/metrics" -ForegroundColor White

# Optional: Start the application
$startApp = Read-Host "`nStart the TCP proxy now? (y/n)"
if ($startApp -eq "y" -or $startApp -eq "Y") {
    Write-Host "`n🚀 Starting TCP proxy..." -ForegroundColor Green
    go run main.go
}
