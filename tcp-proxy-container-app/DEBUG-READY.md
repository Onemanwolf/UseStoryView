# Quick Debug Test Instructions

## ✅ **Fix Applied - Ready to Debug!**

I've removed the conflicting `test_go` directory that contained a duplicate `main` function. Your Go debugger should now work properly.

## 🚀 **How to Debug in VS Code:**

### **Step 1: Use F5 to Debug**
1. **Open** `main.go` in VS Code
2. **Set a breakpoint** on line 131: `go p.handleConnection(conn)`
3. **Press F5**
4. **Select:** "Debug TCP Proxy (Local Testing)" from the dropdown
5. **The debugger should start successfully!**

### **Step 2: Test the Debugging**
Once the debugger starts:
1. Open a new terminal
2. Run the test client:
   ```powershell
   go run test/test-client.go localhost 8080 "Debug test"
   ```
3. Your breakpoint should hit!

## 🐞 **Debug Configurations Available:**

| Configuration | Environment | Use Case |
|---------------|-------------|----------|
| **Debug TCP Proxy (Local Testing)** | Pre-configured with httpbin.org | Quick debugging |
| **Debug TCP Proxy (Custom API)** | Prompts for your API endpoint | Custom endpoint testing |
| **Debug TCP Proxy (Production-like)** | Template for production settings | Production debugging |

## 🎯 **Key Debugging Points:**

- **Line 131**: `go p.handleConnection(conn)` - New connection handler
- **Line 141**: `atomic.AddInt64(&activeConnections, 1)` - Connection tracking
- **Line 156**: `buffer := make([]byte, 4096)` - TCP data reading
- **Line 163**: `response, err := p.forwardToHTTPS(buffer[:n])` - HTTPS forwarding
- **Line 178**: `req, err := http.NewRequest("POST", ...)` - HTTP request creation

## ✅ **Environment Variables Set:**
- `WEB_API_ENDPOINT`: "https://httpbin.org/post"
- `TCP_PORT`: "8080"
- `METRICS_PORT`: "9090"
- `MAX_CONNECTIONS`: "100"
- `CONNECTION_TIMEOUT`: "30"

**You're all set! Press F5 to start debugging!** 🚀
