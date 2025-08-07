# VS Code Workspace Opener
# This script ensures VS Code opens with the correct workspace configuration

Write-Host "🔧 Opening VS Code with proper workspace configuration..." -ForegroundColor Green

# Get current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Cyan

# Check if we're in the correct directory
if (-not (Test-Path "main.go")) {
    Write-Host "❌ main.go not found. Please run this script from the tcp-proxy-container-app directory." -ForegroundColor Red
    exit 1
}

# Check if .vscode directory exists
if (-not (Test-Path ".vscode")) {
    Write-Host "❌ .vscode directory not found." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found main.go and .vscode directory" -ForegroundColor Green

# Check if VS Code is already running
$vscodeProcesses = Get-Process "Code" -ErrorAction SilentlyContinue
if ($vscodeProcesses) {
    Write-Host "⚠️ VS Code is already running. Please close it first for best results." -ForegroundColor Yellow
    $choice = Read-Host "Continue anyway? (y/n)"
    if ($choice -ne "y" -and $choice -ne "Y") {
        exit 0
    }
}

# Open VS Code with workspace
Write-Host "🚀 Opening VS Code workspace..." -ForegroundColor Green

if (Test-Path "tcp-proxy.code-workspace") {
    Write-Host "Opening workspace file..." -ForegroundColor Cyan
    code "tcp-proxy.code-workspace"
} else {
    Write-Host "Opening current directory..." -ForegroundColor Cyan
    code .
}

Write-Host "✅ VS Code should now be open with proper configuration!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Check Run and Debug panel (Ctrl+Shift+D)" -ForegroundColor White
Write-Host "2. Look for 'Debug TCP Proxy' configuration" -ForegroundColor White
Write-Host "3. Set breakpoint on line 131 and press F5" -ForegroundColor White
