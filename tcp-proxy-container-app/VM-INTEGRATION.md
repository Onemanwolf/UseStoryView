# Azure VM to Container Apps Integration Guide

## 🏗️ **Architecture Overview**

When deploying your legacy C++ application on an Azure VM and connecting it to our TCP-to-HTTPS proxy in Container Apps, you have several integration options:

## **Option 1: Application Gateway (Recommended)**

```
[Azure VM] ──TCP──▶ [Application Gateway] ──HTTP──▶ [Container Apps]
   C++ App             Layer 7 LB                    TCP-to-HTTPS Proxy
```

### ✅ **Advantages:**
- **Layer 7 Load Balancing**: HTTP-aware routing and health checks
- **SSL Termination**: Can handle SSL/TLS if needed
- **WAF Integration**: Web Application Firewall protection
- **Path-based Routing**: Route different paths to different backends
- **Auto Scaling**: Built-in scaling capabilities
- **Health Probes**: Advanced health checking

### 📋 **Use Cases:**
- Production workloads requiring high availability
- Multiple backend services
- SSL/TLS termination requirements
- WAF protection needed

---

## **Option 2: Direct Connection (Simplest)**

```
[Azure VM] ──TCP──▶ [Container Apps (Public Ingress)]
   C++ App             TCP-to-HTTPS Proxy
```

### ✅ **Advantages:**
- **Simplicity**: Direct connection, no additional components
- **Lower Cost**: No load balancer costs
- **Lower Latency**: Fewer network hops
- **Easy Debugging**: Direct connection simplifies troubleshooting

### 📋 **Use Cases:**
- Development and testing
- Single backend scenario
- Cost-optimized deployments
- Simple architectures

---

## **Option 3: Azure Load Balancer (Limited)**

⚠️ **Note**: Standard Azure Load Balancer works at Layer 4 (TCP) but has limitations with Container Apps external ingress. Better suited for VM-to-VM scenarios.

---

## 🚀 **Deployment Instructions**

### **Deploy with Application Gateway**

```powershell
# Deploy with Application Gateway for production
.\deploy-vm-integration.ps1 `
    -WebApiEndpoint "https://your-api.com" `
    -LoadBalancingOption "ApplicationGateway" `
    -ResourceGroupName "vm-tcp-proxy-rg"
```

### **Deploy Direct Connection**

```powershell
# Deploy with direct connection for simplicity
.\deploy-vm-integration.ps1 `
    -WebApiEndpoint "https://your-api.com" `
    -LoadBalancingOption "Direct" `
    -ResourceGroupName "vm-tcp-proxy-rg"
```

---

## ⚙️ **C++ Application Configuration**

### **Application Gateway Setup**
```cpp
// Configure your C++ TCP client
const std::string proxy_host = "your-appgw-ip-or-fqdn";  // From deployment output
const int proxy_port = 8080;

// Create socket connection
socket_fd = socket(AF_INET, SOCK_STREAM, 0);
server_addr.sin_family = AF_INET;
server_addr.sin_port = htons(proxy_port);
inet_pton(AF_INET, proxy_host.c_str(), &server_addr.sin_addr);

// Connect to proxy
connect(socket_fd, (struct sockaddr*)&server_addr, sizeof(server_addr));
```

### **Direct Connection Setup**
```cpp
// Configure your C++ TCP client for direct connection
const std::string proxy_host = "your-container-app-fqdn";  // From deployment output
const int proxy_port = 8080;

// Same connection code as above
```

---

## 🔧 **Network Configuration**

### **VM Network Security Group Rules**

```bash
# Allow outbound TCP to proxy (Application Gateway)
az network nsg rule create \
    --resource-group vm-tcp-proxy-rg \
    --nsg-name vm-nsg \
    --name AllowTCPToProxy \
    --protocol Tcp \
    --direction Outbound \
    --priority 100 \
    --source-address-prefixes VirtualNetwork \
    --destination-address-prefixes "GATEWAY_IP/32" \
    --destination-port-ranges 8080

# Allow outbound TCP to Container Apps (Direct)
az network nsg rule create \
    --resource-group vm-tcp-proxy-rg \
    --nsg-name vm-nsg \
    --name AllowTCPToContainerApps \
    --protocol Tcp \
    --direction Outbound \
    --priority 100 \
    --source-address-prefixes VirtualNetwork \
    --destination-address-prefixes Internet \
    --destination-port-ranges 8080
```

---

## 📊 **Monitoring and Scaling**

### **Application Gateway Metrics**
- Request count and rate
- Response time
- Failed requests
- Backend health

### **Container Apps KEDA Scaling**
- **TCP Connections**: Scales based on active connections
- **HTTP Requests**: Scales based on request rate
- **CPU/Memory**: Traditional resource-based scaling
- **Custom Metrics**: Your application metrics

### **Scaling Configuration**
```yaml
# KEDA scaling rules (already configured)
- TCP connections > 10 per replica
- HTTP requests > 100 per replica
- CPU > 70%
- Memory > 80%
```

---

## 🔍 **Testing Your Setup**

### **Test Application Gateway**
```bash
# Test TCP connection through Application Gateway
telnet your-gateway-ip 8080

# Test HTTP health check
curl https://your-container-app-fqdn/health
```

### **Test Direct Connection**
```bash
# Test direct TCP connection
telnet your-container-app-fqdn 8080

# Test metrics endpoint
curl https://your-container-app-fqdn/metrics
```

---

## 🛡️ **Security Considerations**

### **Application Gateway Security**
- WAF rules for HTTP protection
- SSL/TLS termination
- Private backend communication
- NSG rules for traffic control

### **Direct Connection Security**
- HTTPS for web API communication
- Container Apps managed certificates
- Network isolation if needed
- Authentication tokens

---

## 💰 **Cost Comparison**

| Option | Monthly Cost* | Use Case |
|--------|---------------|----------|
| **Application Gateway** | ~$50-200 | Production, HA |
| **Direct Connection** | ~$0 | Development, Simple |

*Estimated costs for basic configurations, excluding Container Apps costs

---

## 🔧 **Troubleshooting**

### **Common Issues**

1. **Connection Refused**
   ```bash
   # Check Container Apps status
   az containerapp show --name tcp-proxy --resource-group vm-tcp-proxy-rg

   # Check Application Gateway backend health
   az network application-gateway show-backend-health --name appgw --resource-group vm-tcp-proxy-rg
   ```

2. **Health Check Failures**
   ```bash
   # Test health endpoint
   curl https://your-container-app-fqdn/health

   # Check Container Apps logs
   az containerapp logs show --name tcp-proxy --resource-group vm-tcp-proxy-rg
   ```

3. **Scaling Issues**
   ```bash
   # Check KEDA scaling metrics
   curl https://your-container-app-fqdn/metrics

   # Monitor Container Apps replicas
   az containerapp revision list --name tcp-proxy --resource-group vm-tcp-proxy-rg
   ```

---

## 📚 **Next Steps**

1. **Deploy** using your preferred option
2. **Configure** your C++ application with the provided endpoints
3. **Test** the connection and monitor scaling
4. **Optimize** based on your traffic patterns
5. **Monitor** using Azure Monitor and Application Insights

Choose the deployment option that best fits your requirements and budget! 🚀
