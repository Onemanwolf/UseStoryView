# Manual debug with environment variables
$env:WEB_API_ENDPOINT="https://httpbin.org/post"
$env:TCP_PORT="8080"
$env:METRICS_PORT="9090"
$env:WEB_API_AUTH_TOKEN=""
$env:MAX_CONNECTIONS="100"
$env:CONNECTION_TIMEOUT="30"

Write-Host "Starting TCP Proxy with environment variables:" -ForegroundColor Green
Write-Host "WEB_API_ENDPOINT: $env:WEB_API_ENDPOINT" -ForegroundColor Cyan
Write-Host "TCP_PORT: $env:TCP_PORT" -ForegroundColor Cyan
Write-Host "METRICS_PORT: $env:METRICS_PORT" -ForegroundColor Cyan

# Start with delve debugger
dlv debug --headless --listen=:2345 --api-version=2 --accept-multiclient
