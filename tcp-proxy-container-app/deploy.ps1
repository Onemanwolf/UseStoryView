# TCP-to-HTTPS Proxy Deployment Script for Azure Container Apps
# This script deploys the TCP proxy with KEDA autoscaling

param(
    [Parameter(Mandatory = $true)]
    [string]$WebApiEndpoint,

    [Parameter(Mandatory = $false)]
    [string]$WebApiAuthToken = "",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "tcp-proxy-rg",

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$ProjectName = "tcp-proxy"
)

Write-Host "🚀 Starting TCP-to-HTTPS Proxy Deployment" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Web API Endpoint: $WebApiEndpoint" -ForegroundColor Yellow

# Check if Azure CLI is installed
try {
    az version | Out-Null
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
}
catch {
    Write-Error "❌ Azure CLI is not installed. Please install it first."
    exit 1
}

# Check if Container Apps extension is installed
$extensions = az extension list --query "[?name=='containerapp'].name" -o tsv
if (-not $extensions) {
    Write-Host "📦 Installing Container Apps extension..." -ForegroundColor Yellow
    az extension add --name containerapp
}

# Check if logged in to Azure
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "✅ Logged in to Azure as: $($account.user.name)" -ForegroundColor Green
}
catch {
    Write-Host "🔐 Please login to Azure..." -ForegroundColor Yellow
    az login
}

# Create Resource Group
Write-Host "📦 Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# Deploy Infrastructure using Bicep
Write-Host "🏗️ Deploying infrastructure..." -ForegroundColor Yellow
$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "infra/main.bicep" `
    --parameters projectName=$ProjectName `
    --parameters environmentName="prod" `
    --parameters webApiEndpoint=$WebApiEndpoint `
    --parameters webApiAuthToken=$WebApiAuthToken `
    --parameters containerImage="mcr.microsoft.com/hello-world:latest" `
    --query "properties.outputs" -o json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to deploy infrastructure"
    exit 1
}

Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green

# Extract outputs
$acrName = $deploymentResult.containerRegistryName.value
$acrLoginServer = $deploymentResult.containerRegistryLoginServer.value
$appName = $deploymentResult.containerAppName.value
$appFQDN = $deploymentResult.containerAppFQDN.value

Write-Host "Container Registry: $acrName" -ForegroundColor Cyan
Write-Host "Container App: $appName" -ForegroundColor Cyan
Write-Host "App URL: $appFQDN" -ForegroundColor Cyan

# Build and Push Container Image
Write-Host "🐳 Building and pushing container image..." -ForegroundColor Yellow

# Login to ACR
az acr login --name $acrName

# Build and push using ACR Build
az acr build --registry $acrName --image "tcp-proxy:latest" .

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to build container image"
    exit 1
}

# Update Container App with new image
Write-Host "🔄 Updating Container App with new image..." -ForegroundColor Yellow
az containerapp update `
    --name $appName `
    --resource-group $ResourceGroupName `
    --image "$acrLoginServer/tcp-proxy:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to update Container App"
    exit 1
}

Write-Host "✅ Container App updated successfully!" -ForegroundColor Green

# Display deployment information
Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "TCP Proxy Endpoint: $appFQDN" -ForegroundColor White
Write-Host "TCP Port: 8080" -ForegroundColor White
Write-Host "Metrics Port: 9090" -ForegroundColor White
Write-Host "Health Check: https://$appFQDN/health" -ForegroundColor White
Write-Host "Metrics: https://$appFQDN/metrics" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor Cyan

# Test connectivity
Write-Host "`n🔍 Testing deployment..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$appFQDN/health" -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Health check passed!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️ Health check failed. The app might still be starting up." -ForegroundColor Yellow
    Write-Host "Please wait a few minutes and try again." -ForegroundColor Yellow
}

# Show scaling information
Write-Host "`n📊 Scaling Configuration:" -ForegroundColor Cyan
Write-Host "- Min Replicas: 0 (scale-to-zero)" -ForegroundColor White
Write-Host "- Max Replicas: 50" -ForegroundColor White
Write-Host "- TCP Scaling: >10 concurrent connections per replica" -ForegroundColor White
Write-Host "- HTTP Scaling: >100 requests per replica" -ForegroundColor White
Write-Host "- CPU Scaling: >70% CPU utilization" -ForegroundColor White
Write-Host "- Memory Scaling: >80% memory utilization" -ForegroundColor White

# Show monitoring links
Write-Host "`n📈 Monitoring:" -ForegroundColor Cyan
Write-Host "- Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$((az account show --query id -o tsv))/resourceGroups/$ResourceGroupName/providers/Microsoft.App/containerApps/$appName" -ForegroundColor White
Write-Host "- Application Insights: Available in Azure Portal" -ForegroundColor White

Write-Host "`n✨ Your TCP-to-HTTPS proxy with KEDA autoscaling is ready!" -ForegroundColor Green
