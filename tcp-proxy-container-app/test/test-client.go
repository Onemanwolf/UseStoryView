package main

import (
	"fmt"
	"net"
	"os"
	"time"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: go run test-client.go <host> <port> [message]")
		fmt.Println("Example: go run test-client.go localhost 8080 'Hello TCP Proxy'")
		os.Exit(1)
	}

	host := os.Args[1]
	port := os.Args[2]
	message := "Hello from TCP test client!"

	if len(os.Args) > 3 {
		message = os.Args[3]
	}

	address := net.JoinHostPort(host, port)
	fmt.Printf("🔌 Connecting to TCP proxy at %s...\n", address)

	// Connect to TCP proxy
	conn, err := net.DialTimeout("tcp", address, 10*time.Second)
	if err != nil {
		fmt.Printf("❌ Failed to connect: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	fmt.Printf("✅ Connected successfully!\n")
	fmt.Printf("📤 Sending message: %s\n", message)

	// Send message
	_, err = conn.Write([]byte(message))
	if err != nil {
		fmt.Printf("❌ Failed to send message: %v\n", err)
		os.Exit(1)
	}

	// Read response
	buffer := make([]byte, 4096)
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	n, err := conn.Read(buffer)
	if err != nil {
		fmt.Printf("❌ Failed to read response: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("📥 Received response (%d bytes):\n", n)
	fmt.Printf("Response: %s\n", string(buffer[:n]))
	fmt.Printf("✅ Test completed successfully!\n")
}
