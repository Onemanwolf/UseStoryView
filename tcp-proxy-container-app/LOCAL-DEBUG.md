# Local Development & Debugging Guide

## 🐛 **Quick Fix for Your Issue**

You're getting the error because the `WEB_API_ENDPOINT` environment variable is required. Here are **3 easy ways** to fix this:

---

## 🚀 **Option 1: Use VS Code Debug Configuration (Recommended)**

1. **Open VS Code**
2. **Press F5** or go to **Run and Debug** panel
3. **Select** "Debug TCP Proxy (Local Testing)" from the dropdown
4. **Click the green play button** ▶️

This will automatically set all required environment variables and start debugging with breakpoints!

---

## 🚀 **Option 2: Use Setup Script**

1. **Run the setup script:**
   ```powershell
   .\setup-local-env.ps1
   ```

2. **Then debug or run:**
   ```powershell
   go run main.go
   ```

---

## 🚀 **Option 3: Set Environment Variables Manually**

### PowerShell:
```powershell
$env:WEB_API_ENDPOINT="https://httpbin.org/post"
$env:TCP_PORT="8080"
$env:METRICS_PORT="9090"
go run main.go
```

### Command Prompt:
```cmd
set WEB_API_ENDPOINT=https://httpbin.org/post
set TCP_PORT=8080
set METRICS_PORT=9090
go run main.go
```

---

## 🔧 **Debug Configurations Available**

| Configuration | Purpose | Web API Endpoint |
|---------------|---------|------------------|
| **Debug TCP Proxy (Local Testing)** | Quick testing with httpbin.org | `https://httpbin.org/post` |
| **Debug TCP Proxy (Custom API)** | Prompts for your API endpoint | User-defined |
| **Debug TCP Proxy (Production-like)** | Production settings template | Your production API |

---

## 🧪 **Testing Your Local Setup**

### **1. Start the proxy:**
```powershell
# Option A: Use VS Code task
# Ctrl+Shift+P -> "Tasks: Run Task" -> "Setup Local Development Environment"

# Option B: Use script directly
.\setup-local-env.ps1

# Option C: Set environment and run
$env:WEB_API_ENDPOINT="https://httpbin.org/post"
go run main.go
```

### **2. Test with our test client:**
```powershell
# Use VS Code task
# Ctrl+Shift+P -> "Tasks: Run Task" -> "Test TCP Proxy Locally"

# Or run directly
go run test/test-client.go localhost 8080 "Hello World"
```

### **3. Test with telnet:**
```cmd
telnet localhost 8080
```

### **4. Check health endpoints:**
```powershell
# Health check
curl http://localhost:9090/health

# Metrics for KEDA scaling
curl http://localhost:9090/metrics
```

---

## 🎯 **Environment Variables Reference**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WEB_API_ENDPOINT` | ✅ **Yes** | None | HTTPS endpoint to forward TCP data |
| `WEB_API_AUTH_TOKEN` | ❌ No | Empty | Bearer token for API authentication |
| `TCP_PORT` | ❌ No | 8080 | Port for TCP proxy to listen on |
| `METRICS_PORT` | ❌ No | 9090 | Port for metrics and health endpoints |
| `MAX_CONNECTIONS` | ❌ No | 1000 | Maximum concurrent connections |
| `CONNECTION_TIMEOUT` | ❌ No | 30 | Connection timeout in seconds |

---

## 🔍 **Common Debug Scenarios**

### **Scenario 1: Test with httpbin.org**
```powershell
$env:WEB_API_ENDPOINT="https://httpbin.org/post"
go run main.go
```
**Use this for:** Basic connectivity testing

### **Scenario 2: Test with your API**
```powershell
$env:WEB_API_ENDPOINT="https://your-api.com/endpoint"
$env:WEB_API_AUTH_TOKEN="your-token-here"
go run main.go
```
**Use this for:** Real API integration testing

### **Scenario 3: Test error handling**
```powershell
$env:WEB_API_ENDPOINT="https://httpbin.org/status/500"
go run main.go
```
**Use this for:** Error scenario testing

---

## 🐞 **Debugging Tips**

### **1. Set Breakpoints**
- Line 131: `go p.handleConnection(conn)` - When new connections arrive
- Line 141: `atomic.AddInt64(&activeConnections, 1)` - Connection tracking
- Line 168: `response, err := p.forwardToHTTPS(buffer[:n])` - HTTPS forwarding

### **2. Watch Variables**
- `activeConnections` - Current connection count
- `totalRequests` - Total requests processed
- `p.config.WebAPIEndpoint` - API endpoint being used

### **3. Console Output**
The application logs all important events:
- Connection accepts/rejects
- HTTPS forwarding results
- Error conditions

---

## 📊 **Testing Flow**

```
1. Start TCP Proxy (with environment variables)
        ↓
2. TCP Proxy listens on port 8080
        ↓
3. Metrics server starts on port 9090
        ↓
4. Send TCP data to localhost:8080
        ↓
5. Proxy forwards to HTTPS endpoint
        ↓
6. Response comes back to TCP client
        ↓
7. Check metrics at localhost:9090/metrics
```

---

## ✅ **Quick Checklist**

- [ ] Go is installed and in PATH
- [ ] `WEB_API_ENDPOINT` environment variable is set
- [ ] Ports 8080 and 9090 are available
- [ ] Internet connection for HTTPS requests
- [ ] VS Code Go extension is installed

---

## 🎉 **You're Ready!**

Now you can:
1. **Debug locally** with full breakpoint support
2. **Test TCP connections** with the included test client
3. **Monitor metrics** for KEDA scaling
4. **Deploy to Azure** when ready

Happy debugging! 🚀
