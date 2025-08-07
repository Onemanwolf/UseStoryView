# TCP-to-HTTPS Proxy Deployment Guide

## Prerequisites

1. **Azure CLI** installed and logged in:
   ```bash
   az login
   az extension add --name containerapp
   ```

2. **Docker** installed for building container images

3. **Azure Developer CLI (azd)** installed:
   ```bash
   # Windows (PowerShell)
   winget install Microsoft.Azd

   # macOS
   brew tap azure/azd && brew install azd

   # Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

## Quick Deployment with AZD

1. **Initialize the project**:
   ```bash
   cd tcp-proxy-container-app
   azd init
   ```

2. **Configure environment variables**:
   ```bash
   azd env set WEB_API_ENDPOINT "https://your-api.example.com/api/endpoint"
   azd env set WEB_API_AUTH_TOKEN "your-auth-token"
   ```

3. **Deploy to Azure**:
   ```bash
   azd up
   ```

## Manual Deployment Steps

### 1. Create Resource Group
```bash
az group create --name tcp-proxy-rg --location eastus
```

### 2. Deploy Infrastructure
```bash
az deployment group create \
  --resource-group tcp-proxy-rg \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json \
  --parameters webApiEndpoint="https://your-api.example.com/api/endpoint" \
  --parameters webApiAuthToken="your-auth-token"
```

### 3. Build and Push Container Image
```bash
# Get ACR login server
ACR_NAME=$(az deployment group show \
  --resource-group tcp-proxy-rg \
  --name main \
  --query properties.outputs.containerRegistryName.value -o tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push image
az acr build --registry $ACR_NAME --image tcp-proxy:latest .
```

### 4. Update Container App
```bash
# Get Container App name
APP_NAME=$(az deployment group show \
  --resource-group tcp-proxy-rg \
  --name main \
  --query properties.outputs.containerAppName.value -o tsv)

# Update with new image
az containerapp update \
  --name $APP_NAME \
  --resource-group tcp-proxy-rg \
  --image $ACR_NAME.azurecr.io/tcp-proxy:latest
```

## KEDA Scaling Configuration

The Container App is configured with multiple KEDA autoscaling rules:

### 1. TCP Connection Scaling
```yaml
- name: tcp-connections
  tcp:
    metadata:
      concurrentRequests: '10'  # Scale when >10 concurrent TCP connections per replica
```

### 2. HTTP Request Scaling
```yaml
- name: http-requests
  http:
    metadata:
      concurrentRequests: '100'  # Scale when >100 HTTP requests per replica
```

### 3. CPU-based Scaling
```yaml
- name: cpu-scaling
  custom:
    type: cpu
    metadata:
      type: Utilization
      value: '70'  # Scale when CPU usage >70%
```

### 4. Memory-based Scaling
```yaml
- name: memory-scaling
  custom:
    type: memory
    metadata:
      type: Utilization
      value: '80'  # Scale when memory usage >80%
```

## Scaling Behavior

- **Minimum Replicas**: 0 (scale-to-zero for cost optimization)
- **Maximum Replicas**: 50 (can handle high load)
- **Scale-up**: Triggered by any of the scaling rules
- **Scale-down**: Gradual scale-down when load decreases
- **Cold Start**: ~2-3 seconds from zero to serving traffic

## Monitoring and Observability

### 1. Application Insights
- **Telemetry**: Custom metrics, traces, and logs
- **Dashboard**: Real-time monitoring of requests and performance

### 2. Container Apps Metrics
- **Built-in Metrics**: CPU, memory, request count, response time
- **Custom Metrics**: Active connections, throughput

### 3. Log Analytics
- **Container Logs**: Application logs and system events
- **Query Language**: KQL for advanced log analysis

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TCP_PORT` | TCP listening port | `8080` | No |
| `METRICS_PORT` | Metrics/health endpoint port | `9090` | No |
| `WEB_API_ENDPOINT` | Target HTTPS API URL | - | Yes |
| `WEB_API_AUTH_TOKEN` | API authentication token | - | No |
| `MAX_CONNECTIONS` | Max concurrent connections | `1000` | No |
| `CONNECTION_TIMEOUT` | Connection timeout (seconds) | `30` | No |

### Security Best Practices

1. **Managed Identity**: Uses Azure Managed Identity for ACR access
2. **Private Networking**: Deployed in VNet with private subnets
3. **Secret Management**: Sensitive data stored as Container App secrets
4. **TLS Encryption**: All HTTPS communications use TLS 1.2+
5. **Health Checks**: Liveness and readiness probes for reliability

## Testing the Deployment

### 1. Get the Container App URL
```bash
FQDN=$(az containerapp show \
  --name $APP_NAME \
  --resource-group tcp-proxy-rg \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "TCP Proxy URL: $FQDN:8080"
```

### 2. Test TCP Connection
```bash
# Using telnet
telnet $FQDN 8080

# Using netcat
echo "test data" | nc $FQDN 8080
```

### 3. Monitor Scaling
```bash
# Watch replica count
watch az containerapp replica list \
  --name $APP_NAME \
  --resource-group tcp-proxy-rg \
  --query length
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check if Container App is running and TCP ingress is configured
2. **Scaling Not Working**: Verify KEDA rules and metrics endpoints
3. **Authentication Errors**: Check managed identity permissions and secrets

### Log Analysis
```bash
# View application logs
az containerapp logs show \
  --name $APP_NAME \
  --resource-group tcp-proxy-rg \
  --follow

# Query specific errors
az monitor log-analytics query \
  --workspace $WORKSPACE_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerName_s == 'tcp-proxy' | order by TimeGenerated desc"
```

## Cost Optimization

1. **Scale-to-Zero**: Automatically scales to 0 replicas when idle
2. **Consumption Pricing**: Pay only for actual usage
3. **Resource Right-sizing**: Optimized CPU/memory allocation
4. **Log Retention**: 30-day retention for cost efficiency

## Production Considerations

1. **Multi-region Deployment**: Deploy to multiple regions for high availability
2. **Load Testing**: Test scaling behavior under expected load
3. **Monitoring Alerts**: Set up alerts for critical metrics
4. **Backup Strategy**: Implement configuration and data backup
5. **Disaster Recovery**: Plan for regional outages
