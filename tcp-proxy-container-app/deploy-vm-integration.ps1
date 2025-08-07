# VM-to-Container-Apps TCP Proxy Deployment Script
# This script deploys the TCP proxy with Load Balancer/Application Gateway for VM integration

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
    [string]$ProjectName = "tcp-proxy",

    [Parameter(Mandatory = $false)]
    [ValidateSet("ApplicationGateway", "Direct")]
    [string]$LoadBalancingOption = "ApplicationGateway"
)

Write-Host "🚀 Starting VM-to-Container-Apps TCP Proxy Deployment" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Web API Endpoint: $WebApiEndpoint" -ForegroundColor Yellow
Write-Host "Load Balancing: $LoadBalancingOption" -ForegroundColor Yellow

# Check prerequisites
try {
    az version | Out-Null
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
}
catch {
    Write-Error "❌ Azure CLI is not installed. Please install it first."
    exit 1
}

# Install Container Apps extension if needed
$extensions = az extension list --query "[?name=='containerapp'].name" -o tsv
if (-not $extensions) {
    Write-Host "📦 Installing Container Apps extension..." -ForegroundColor Yellow
    az extension add --name containerapp
}

# Check Azure login
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

# Deploy main infrastructure (Container Apps)
Write-Host "🏗️ Deploying Container Apps infrastructure..." -ForegroundColor Yellow
$mainDeployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "infra/main.bicep" `
    --parameters projectName=$ProjectName `
    --parameters environmentName="prod" `
    --parameters webApiEndpoint=$WebApiEndpoint `
    --parameters webApiAuthToken=$WebApiAuthToken `
    --parameters containerImage="mcr.microsoft.com/hello-world:latest" `
    --query "properties.outputs" -o json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to deploy main infrastructure"
    exit 1
}

# Extract outputs from main deployment
$acrName = $mainDeployment.containerRegistryName.value
$acrLoginServer = $mainDeployment.containerRegistryLoginServer.value
$appName = $mainDeployment.containerAppName.value
$appFQDN = $mainDeployment.containerAppFQDN.value
$vnetName = $mainDeployment.virtualNetworkName.value

Write-Host "✅ Container Apps infrastructure deployed!" -ForegroundColor Green
Write-Host "Container Registry: $acrName" -ForegroundColor Cyan
Write-Host "Container App: $appName" -ForegroundColor Cyan
Write-Host "App FQDN: $appFQDN" -ForegroundColor Cyan

# Build and push container image
Write-Host "🐳 Building and pushing container image..." -ForegroundColor Yellow
az acr login --name $acrName
az acr build --registry $acrName --image "tcp-proxy:latest" .

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to build container image"
    exit 1
}

# Update Container App with new image
Write-Host "🔄 Updating Container App..." -ForegroundColor Yellow
az containerapp update `
    --name $appName `
    --resource-group $ResourceGroupName `
    --image "$acrLoginServer/tcp-proxy:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to update Container App"
    exit 1
}

# Deploy load balancing solution
if ($LoadBalancingOption -eq "ApplicationGateway") {
    Write-Host "🌐 Deploying Application Gateway for VM integration..." -ForegroundColor Yellow

    $appGwDeployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "infra/application-gateway.bicep" `
        --parameters projectName=$ProjectName `
        --parameters environmentName="prod" `
        --parameters containerAppFQDN=$appFQDN `
        --parameters virtualNetworkName=$vnetName `
        --query "properties.outputs" -o json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to deploy Application Gateway"
        exit 1
    }

    $gatewayIP = $appGwDeployment.applicationGatewayPublicIP.value
    $gatewayFQDN = $appGwDeployment.applicationGatewayFQDN.value

    Write-Host "✅ Application Gateway deployed!" -ForegroundColor Green
    Write-Host "Gateway IP: $gatewayIP" -ForegroundColor Cyan
    Write-Host "Gateway FQDN: $gatewayFQDN" -ForegroundColor Cyan
}

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

if ($LoadBalancingOption -eq "ApplicationGateway") {
    Write-Host "VM Connection Details:" -ForegroundColor White
    Write-Host "- TCP Endpoint: $gatewayIP:8080" -ForegroundColor White
    Write-Host "- Gateway FQDN: $gatewayFQDN" -ForegroundColor White
    Write-Host "- Configure your C++ app to connect to: $gatewayIP:8080" -ForegroundColor Yellow
}
else {
    Write-Host "Direct Connection Details:" -ForegroundColor White
    Write-Host "- TCP Endpoint: $appFQDN:8080" -ForegroundColor White
    Write-Host "- Configure your C++ app to connect to: $appFQDN:8080" -ForegroundColor Yellow
}

Write-Host "`nContainer App Details:" -ForegroundColor White
Write-Host "- Container App FQDN: $appFQDN" -ForegroundColor White
Write-Host "- Health Check: https://$appFQDN/health" -ForegroundColor White
Write-Host "- Metrics: https://$appFQDN/metrics" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor Cyan

# Test deployment
Write-Host "`n🔍 Testing deployment..." -ForegroundColor Yellow
try {
    $healthUrl = "https://$appFQDN/health"
    $response = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Container App health check passed!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️ Health check failed. The app might still be starting up." -ForegroundColor Yellow
}

# Show architecture diagram
Write-Host "`n🏗️ Architecture:" -ForegroundColor Cyan
if ($LoadBalancingOption -eq "ApplicationGateway") {
    Write-Host @"
┌─────────────┐    ┌─────────────────────┐    ┌──────────────────┐
│   Azure VM  │───▶│  Application Gateway │───▶│  Container Apps  │
│  (C++ App)  │    │   (Load Balancer)   │    │  (TCP-to-HTTPS)  │
│             │    │                     │    │                  │
│ Port: Any   │    │ Public IP:8080      │    │ Internal:8080    │
└─────────────┘    └─────────────────────┘    └──────────────────┘
                                                        │
                                                        ▼
                                                 ┌─────────────┐
                                                 │  Your Web   │
                                                 │    API      │
                                                 │   (HTTPS)   │
                                                 └─────────────┘
"@ -ForegroundColor White
}
else {
    Write-Host @"
┌─────────────┐                                 ┌──────────────────┐
│   Azure VM  │────────────────────────────────▶│  Container Apps  │
│  (C++ App)  │         Direct Connection       │  (TCP-to-HTTPS)  │
│             │                                 │                  │
│ Port: Any   │                                 │ Public:8080      │
└─────────────┘                                 └──────────────────┘
                                                        │
                                                        ▼
                                                 ┌─────────────┐
                                                 │  Your Web   │
                                                 │    API      │
                                                 │   (HTTPS)   │
                                                 └─────────────┘
"@ -ForegroundColor White
}

# Configuration instructions for C++ app
Write-Host "`n⚙️ C++ Application Configuration:" -ForegroundColor Cyan
Write-Host "Update your C++ application to connect to:" -ForegroundColor White
if ($LoadBalancingOption -eq "ApplicationGateway") {
    Write-Host "  Host: $gatewayIP" -ForegroundColor Yellow
}
else {
    Write-Host "  Host: $appFQDN" -ForegroundColor Yellow
}
Write-Host "  Port: 8080" -ForegroundColor Yellow
Write-Host "  Protocol: TCP" -ForegroundColor Yellow

Write-Host "`n📊 Scaling Information:" -ForegroundColor Cyan
Write-Host "- KEDA Autoscaling: Enabled" -ForegroundColor White
Write-Host "- Scale to Zero: Yes" -ForegroundColor White
Write-Host "- Max Replicas: 50" -ForegroundColor White
Write-Host "- Scaling Triggers: TCP connections, HTTP requests, CPU, Memory" -ForegroundColor White

Write-Host "`n✨ Your VM-to-Container-Apps TCP proxy is ready!" -ForegroundColor Green
