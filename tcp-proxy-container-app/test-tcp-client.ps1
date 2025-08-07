# Simple TCP client to test the proxy
param(
    [string]$Server = "localhost",
    [int]$Port = 8080,
    [string]$Message = "Hello from TCP client!"
)

try {
    Write-Host "Connecting to ${Server}:${Port}..."

    # Create TCP client
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($Server, $Port)

    Write-Host "Connected! Sending message: ${Message}"

    # Get network stream
    $stream = $tcpClient.GetStream()

    # Send data
    $data = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $stream.Write($data, 0, $data.Length)

    # Read response
    $buffer = New-Object byte[] 4096
    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
    $response = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)

    Write-Host "Response received ($bytesRead bytes):"
    Write-Host $response

    # Clean up
    $stream.Close()
    $tcpClient.Close()

    Write-Host "Connection closed successfully"
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
