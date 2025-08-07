@echo off
echo Setting up debug environment...
set WEB_API_ENDPOINT=https://httpbin.org/post
set TCP_PORT=8080
set METRICS_PORT=9090
set MAX_CONNECTIONS=100
set CONNECTION_TIMEOUT=30
set WEB_API_AUTH_TOKEN=

echo Starting TCP proxy with debug environment...
go run main.go
