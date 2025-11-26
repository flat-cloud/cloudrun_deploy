package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

type Response struct {
	Message   string `json:"message"`
	Framework string `json:"framework"`
	Language  string `json:"language"`
	Timestamp string `json:"timestamp"`
	Service   string `json:"service"`
	Revision  string `json:"revision"`
}

type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
}

type InfoResponse struct {
	Service     string            `json:"service"`
	Version     string            `json:"version"`
	Endpoints   map[string]string `json:"endpoints"`
	Environment map[string]string `json:"environment"`
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	response := Response{
		Message:   "Hello from Cloud Run!",
		Framework: "Native HTTP",
		Language:  "Go",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Service:   getEnv("K_SERVICE", "local"),
		Revision:  getEnv("K_REVISION", "dev"),
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
	response := InfoResponse{
		Service: "Go HTTP Sample App",
		Version: "1.0.0",
		Endpoints: map[string]string{
			"/":         "Home page",
			"/health":   "Health check",
			"/api/info": "Service information",
		},
		Environment: map[string]string{
			"port":       getEnv("PORT", "8080"),
			"service":    getEnv("K_SERVICE", "local"),
			"revision":   getEnv("K_REVISION", "dev"),
			"goVersion":  runtime.Version(),
			"goOS":       runtime.GOOS,
			"goArch":     runtime.GOARCH,
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/api/info", infoHandler)
	
	port := getEnv("PORT", "8080")
	addr := fmt.Sprintf(":%s", port)
	
	log.Printf("Server starting on port %s", port)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}
