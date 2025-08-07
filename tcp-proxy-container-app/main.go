package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

// Configuration from environment variables
type Config struct {
	TCPPort           string
	WebAPIEndpoint    string
	WebAPIAuthToken   string
	MaxConnections    int
	ConnectionTimeout time.Duration
	MetricsPort       string
}

// Metrics for KEDA scaling
var (
	activeConnections int64
	totalRequests     int64
	requestDuration   int64
)

type TCPProxy struct {
	config     *Config
	httpClient *http.Client
	listener   net.Listener
	wg         sync.WaitGroup
}

type MetricsResponse struct {
	ActiveConnections int64 `json:"active_connections"`
	TotalRequests     int64 `json:"total_requests"`
	AvgDuration       int64 `json:"avg_duration_ms"`
}

func init() {
	// Initialize metrics
	atomic.StoreInt64(&activeConnections, 0)
	atomic.StoreInt64(&totalRequests, 0)
	atomic.StoreInt64(&requestDuration, 0)
}

func NewTCPProxy() *TCPProxy {
	config := &Config{
		TCPPort:           getEnv("TCP_PORT", "8080"),
		WebAPIEndpoint:    getEnv("WEB_API_ENDPOINT", ""),
		WebAPIAuthToken:   getEnv("WEB_API_AUTH_TOKEN", ""),
		MaxConnections:    getEnvInt("MAX_CONNECTIONS", 1000),
		ConnectionTimeout: time.Duration(getEnvInt("CONNECTION_TIMEOUT", 30)) * time.Second,
		MetricsPort:       getEnv("METRICS_PORT", "9090"),
	}

	if config.WebAPIEndpoint == "" {
		log.Fatal("WEB_API_ENDPOINT environment variable is required")
	}

	// Create HTTP client with proper TLS configuration
	httpClient := &http.Client{
		Timeout: config.ConnectionTimeout,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				InsecureSkipVerify: false,
			},
			MaxIdleConns:        100,
			MaxIdleConnsPerHost: 10,
			IdleConnTimeout:     90 * time.Second,
		},
	}

	return &TCPProxy{
		config:     config,
		httpClient: httpClient,
	}
}

func (p *TCPProxy) Start() error {
	// Start metrics server for KEDA
	go p.startMetricsServer()

	// Start TCP listener
	listener, err := net.Listen("tcp", ":"+p.config.TCPPort)
	if err != nil {
		return fmt.Errorf("failed to start TCP listener: %v", err)
	}
	p.listener = listener

	log.Printf("TCP proxy listening on port %s", p.config.TCPPort)
	log.Printf("Forwarding to HTTPS endpoint: %s", p.config.WebAPIEndpoint)

	// Handle graceful shutdown
	go p.handleShutdown()

	// Accept connections
	for {
		conn, err := listener.Accept()
		if err != nil {
			select {
			case <-context.Background().Done():
				return nil
			default:
				log.Printf("Failed to accept connection: %v", err)
				continue
			}
		}

		// Check connection limit
		if atomic.LoadInt64(&activeConnections) >= int64(p.config.MaxConnections) {
			log.Printf("Connection limit reached, rejecting connection")
			conn.Close()
			continue
		}

		// Handle connection in goroutine
		p.wg.Add(1)
		go p.handleConnection(conn)
	}
}

func (p *TCPProxy) handleConnection(conn net.Conn) {
	defer p.wg.Done()
	defer conn.Close()

	// Track active connections for KEDA scaling
	atomic.AddInt64(&activeConnections, 1)
	defer atomic.AddInt64(&activeConnections, -1)

	start := time.Now()
	defer func() {
		duration := time.Since(start).Milliseconds()
		atomic.StoreInt64(&requestDuration, duration)
		atomic.AddInt64(&totalRequests, 1)
	}()

	// Set connection timeout
	conn.SetDeadline(time.Now().Add(p.config.ConnectionTimeout))

	// Read TCP data
	buffer := make([]byte, 4096)
	n, err := conn.Read(buffer)
	if err != nil {
		log.Printf("Failed to read from TCP connection: %v", err)
		return
	}

	// Convert TCP data to HTTPS request
	response, err := p.forwardToHTTPS(buffer[:n])
	if err != nil {
		log.Printf("Failed to forward to HTTPS: %v", err)
		// Send error response back to TCP client
		conn.Write([]byte(fmt.Sprintf("ERROR: %v\n", err)))
		return
	}

	// Send HTTPS response back to TCP client
	_, err = conn.Write(response)
	if err != nil {
		log.Printf("Failed to write response to TCP connection: %v", err)
	}
}

func (p *TCPProxy) forwardToHTTPS(data []byte) ([]byte, error) {
	// Create HTTP POST request with TCP data as body
	req, err := http.NewRequest("POST", p.config.WebAPIEndpoint, bytes.NewReader(data))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %v", err)
	}

	// Add authentication header if provided
	if p.config.WebAPIAuthToken != "" {
		req.Header.Set("Authorization", "Bearer "+p.config.WebAPIAuthToken)
	}

	// Set content type
	req.Header.Set("Content-Type", "application/octet-stream")
	req.Header.Set("User-Agent", "TCP-Proxy/1.0")

	// Make HTTPS request
	resp, err := p.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTPS request failed: %v", err)
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	// Check for HTTP errors
	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP error %d: %s", resp.StatusCode, string(body))
	}

	return body, nil
}

func (p *TCPProxy) startMetricsServer() {
	// Metrics endpoint for KEDA scaling
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		metrics := MetricsResponse{
			ActiveConnections: atomic.LoadInt64(&activeConnections),
			TotalRequests:     atomic.LoadInt64(&totalRequests),
			AvgDuration:       atomic.LoadInt64(&requestDuration),
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(metrics)
	})

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Readiness probe
	http.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		if p.listener != nil {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("READY"))
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte("NOT READY"))
		}
	})

	log.Printf("Metrics server starting on port %s", p.config.MetricsPort)
	if err := http.ListenAndServe(":"+p.config.MetricsPort, nil); err != nil {
		log.Printf("Metrics server error: %v", err)
	}
}

func (p *TCPProxy) handleShutdown() {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Shutting down TCP proxy...")

	if p.listener != nil {
		p.listener.Close()
	}

	// Wait for all connections to complete
	p.wg.Wait()
	log.Println("TCP proxy shutdown complete")
	os.Exit(0)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func main() {
	proxy := NewTCPProxy()
	if err := proxy.Start(); err != nil {
		log.Fatal(err)
	}
}
