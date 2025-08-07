# 🔧 VS Code Workspace Fix Guide

## ❌ **Problem:**
VS Code is not recognizing the `.vscode` configuration files and showing "create a launch.json file" option.

## ✅ **Solution Steps:**

### **Step 1: Open Workspace Correctly**
1. **Close VS Code completely**
2. **Navigate to the project folder:**
   ```cmd
   cd "C:\Users\timot\UseStoryView\tcp-proxy-container-app"
   ```
3. **Open VS Code from this directory:**
   ```cmd
   code .
   ```
   **OR** double-click `tcp-proxy.code-workspace` file

### **Step 2: Verify VS Code Setup**
1. **Check bottom status bar** - should show "Go" language mode
2. **Press Ctrl+Shift+P** → Type "Go: Install/Update Tools" → Install Go tools if prompted
3. **Open Command Palette** → "Developer: Reload Window" to refresh

### **Step 3: Debug Configuration**
1. **Go to Run and Debug panel** (Ctrl+Shift+D)
2. **You should now see:** "Debug TCP Proxy" configuration
3. **If not visible:** Click gear icon → "Add Configuration" → Select "Go"

### **Step 4: Manual Debug Setup (If needed)**
If VS Code still doesn't recognize the files:

1. **Press F1** → "Go: Toggle Test File"
2. **Go to Run panel** → Click "create a launch.json file"
3. **Select "Go"** → It will create default config
4. **Replace the content** with:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Debug TCP Proxy",
         "type": "go",
         "request": "launch",
         "mode": "debug",
         "program": "main.go",
         "env": {
           "WEB_API_ENDPOINT": "https://httpbin.org/post",
           "TCP_PORT": "8080",
           "METRICS_PORT": "9090"
         }
       }
     ]
   }
   ```

## 🚀 **Quick Test:**

### **Option A: Use VS Code Task (Recommended)**
1. **Ctrl+Shift+P** → "Tasks: Run Task"
2. **Select:** "Run TCP Proxy"
3. **Should start without environment variable errors**

### **Option B: Use F5 Debug**
1. **Set breakpoint** on line 131 in main.go
2. **Press F5**
3. **Select:** "Debug TCP Proxy"
4. **Should start debugging**

### **Option C: Manual Environment (Fallback)**
In VS Code terminal:
```powershell
$env:WEB_API_ENDPOINT="https://httpbin.org/post"
$env:TCP_PORT="8080"
$env:METRICS_PORT="9090"
go run main.go
```

## 📁 **Files Created:**
- ✅ `tcp-proxy.code-workspace` - VS Code workspace file
- ✅ `.vscode/launch.json` - Simplified debug configuration
- ✅ `.vscode/tasks.json` - Simplified tasks
- ✅ `.env` - Environment variables backup

## 🎯 **Expected Result:**
After following these steps:
- ✅ VS Code recognizes the workspace
- ✅ Debug panel shows "Debug TCP Proxy" configuration
- ✅ F5 starts debugging without environment variable errors
- ✅ Tasks are available in Command Palette

**If you still see "create a launch.json file", use Step 4 (Manual Debug Setup).** 🔧
