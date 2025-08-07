# TCP-to-HTTPS Proxy on Azure Container Apps with KEDA Autoscaling

This solution deploys a TCP-to-HTTPS proxy service on Azure Container Apps with elastic scaling powered by KEDA.

## Architecture Overview

```
[Legacy C++ App] --TCP--> [Azure Container Apps (KEDA)] --HTTPS--> [Web API]
                             ↕️
                    [Auto-scaling based on]:
                    - TCP connections
                    - HTTP requests
                    - CPU/Memory usage
                    - Custom metrics
```

## Features

✅ **Elastic Scaling with KEDA**
- Scale from 0 to 50+ instances automatically
- Multiple scaling triggers (TCP, HTTP, CPU, Memory)
- Cost-effective scale-to-zero capability

✅ **TCP Ingress Support**
- Native TCP protocol support
- External and internal connectivity options
- Load balancing across replicas

✅ **High Availability**
- Multi-zone deployment
- Health checks and automatic recovery
- Circuit breaker patterns

✅ **Monitoring & Observability**
- Built-in Azure Monitor integration
- Custom metrics and alerts
- Distributed tracing

## Deployment Instructions

1. **Prerequisites**
   ```bash
   # Install Azure CLI
   az login
   az extension add --name containerapp
   ```

2. **Deploy Infrastructure**
   ```bash
   # Deploy using Bicep templates
   az deployment group create \
     --resource-group tcp-proxy-rg \
     --template-file infra/main.bicep \
     --parameters @infra/main.parameters.json
   ```

3. **Build and Deploy Application**
   ```bash
   # Build and push container
   docker build -t tcpproxy:latest .
   az acr build --registry <your-acr> --image tcpproxy:latest .

   # Deploy to Container Apps
   az containerapp update \
     --name tcp-proxy-app \
     --resource-group tcp-proxy-rg \
     --image <your-acr>.azurecr.io/tcpproxy:latest
   ```

## Scaling Configuration

The application is configured with the following KEDA scaling rules:

- **Minimum Replicas**: 0 (scale to zero when idle)
- **Maximum Replicas**: 50
- **TCP Scaling**: Scale when >10 concurrent connections per replica
- **HTTP Scaling**: Scale when >100 requests per replica
- **CPU Scaling**: Scale when CPU usage >70%

## Configuration

Environment variables for the proxy application:

| Variable | Description | Default |
|----------|-------------|---------|
| `TCP_PORT` | TCP port to listen on | `8080` |
| `WEB_API_ENDPOINT` | Target HTTPS web API URL | Required |
| `WEB_API_AUTH_TOKEN` | Authentication token for web API | Required |
| `MAX_CONNECTIONS` | Maximum concurrent connections | `1000` |
| `CONNECTION_TIMEOUT` | Connection timeout in seconds | `30` |

## Monitoring

Access monitoring dashboards:
- **Azure Portal**: Container Apps monitoring blade
- **Application Insights**: Custom telemetry and traces
- **Azure Monitor**: Metrics and alerts

## Security

- Private networking with VNet integration
- Managed identity for Azure resource access
- TLS encryption for all HTTPS communications
- Network security groups for traffic filtering
