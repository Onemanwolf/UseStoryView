# 🚀 Quick Start Guide - TCP-to-HTTPS Proxy with KEDA Autoscaling

This guide will help you deploy your TCP-to-HTTPS proxy to Azure Container Apps with elastic scaling powered by KEDA.

## ⚡ One-Click Deployment

### Using VS Code Tasks (Recommended)

1. **Open Command Palette**: `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)

2. **Run Task**: Type "Tasks: Run Task" and select it

3. **Deploy**: Choose "**Deploy TCP Proxy to Azure Container Apps**"

4. **Configure**: Enter the required information when prompted:
   - **Web API Endpoint**: Your target HTTPS API (e.g., `https://api.example.com/endpoint`)
   - **Auth Token**: Authentication token (optional)
   - **Resource Group**: Azure resource group name (default: `tcp-proxy-rg`)
   - **Location**: Azure region (default: `eastus`)

5. **Wait**: The deployment takes 5-10 minutes and includes:
   - ✅ Infrastructure provisioning (VNet, Container Registry, Log Analytics)
   - ✅ Container image building and pushing
   - ✅ Container App deployment with KEDA scaling
   - ✅ Health checks and validation

## 🎯 What You Get

### **Elastic Scaling with KEDA**
- **Scale-to-Zero**: Automatically scales to 0 replicas when idle (saves costs)
- **Auto-scaling**: Scales up to 50 replicas based on:
  - TCP connections (>10 per replica)
  - HTTP requests (>100 per replica)
  - CPU usage (>70%)
  - Memory usage (>80%)

### **Production-Ready Features**
- **High Availability**: Multi-zone deployment with health checks
- **Security**: Managed identity, private networking, secret management
- **Monitoring**: Application Insights, Log Analytics, custom metrics
- **Networking**: TCP ingress with load balancing

### **Cost-Effective**
- **Pay-per-use**: Only pay when traffic is flowing
- **Resource optimization**: Right-sized containers with auto-scaling
- **No idle costs**: Scale-to-zero eliminates idle charges

## 📊 Monitoring & Management

### Available VS Code Tasks

| Task | Description |
|------|-------------|
| **Deploy TCP Proxy to Azure Container Apps** | Full deployment with prompts |
| **Build Docker Image Locally** | Test container locally |
| **Test Docker Image Locally** | Run container with environment variables |
| **Check Azure Login Status** | Verify Azure CLI authentication |
| **View Container App Logs** | Stream live logs from Azure |
| **Scale Container App** | Manually adjust replica count |
| **Delete Deployment** | Clean up all Azure resources |

### Access Your Deployment

After deployment, you'll get:

```
🎉 Deployment Complete!
===========================================
TCP Proxy Endpoint: your-app.region.azurecontainerapps.io
TCP Port: 8080
Metrics Port: 9090
Health Check: https://your-app.region.azurecontainerapps.io/health
Metrics: https://your-app.region.azurecontainerapps.io/metrics
===========================================
```

## 🔧 Local Development

### Debug Locally
1. Set breakpoints in `main.go`
2. Press `F5` or use "Debug TCP Proxy" configuration
3. Test with: `telnet localhost 8080`

### Test Container Locally
1. Run Task: "Build Docker Image Locally"
2. Run Task: "Test Docker Image Locally"
3. Access: `http://localhost:8080` (TCP) and `http://localhost:9090/metrics`

## 📈 Scaling Behavior

### Automatic Scaling Triggers

```yaml
Scale Up When:
├── TCP Connections > 10 per replica
├── HTTP Requests > 100 per replica
├── CPU Usage > 70%
└── Memory Usage > 80%

Scale Down When:
├── Traffic decreases (gradual scale-down)
└── No traffic for 5 minutes (scale to zero)
```

### Manual Scaling
Use the "Scale Container App" task to manually set replica count for testing.

## 🛠️ Architecture

```
[Legacy C++ App] --TCP--> [Azure Container Apps + KEDA] --HTTPS--> [Web API]
                              │
                              ├── Auto-scaling (0-50 replicas)
                              ├── Load Balancing
                              ├── Health Monitoring
                              └── Cost Optimization
```

## 💡 Tips

- **First Deployment**: Takes 5-10 minutes for initial setup
- **Subsequent Updates**: Takes 2-3 minutes for code changes
- **Cold Start**: ~2-3 seconds from zero to serving traffic
- **Monitoring**: Check Azure Portal for detailed metrics and logs
- **Cost**: Typical monthly cost: $10-50 for low-medium traffic

## 🔍 Troubleshooting

### Common Issues

1. **"Command not found"**: Install Azure CLI and Container Apps extension
2. **Authentication failed**: Run "Login to Azure" task
3. **Health check failed**: App might still be starting (wait 2-3 minutes)
4. **Scaling not working**: Check KEDA metrics in Azure Portal

### Get Help

- **View Logs**: Run "View Container App Logs" task
- **Azure Portal**: Check Container Apps resource for detailed metrics
- **Health Status**: Visit `/health` endpoint for app status

---

**🎉 You're ready to deploy your TCP-to-HTTPS proxy with enterprise-grade elastic scaling!**
