package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// DecisionRequest payload for Hanzo Decisions API
type DecisionRequest struct {
	Model     string                 `json:"model"`
	State     any                    `json:"state"`
	Questions map[string]interface{} `json:"questions"`
}

// DecisionResponse represents the evaluated answers and decision telemetry
type DecisionResponse struct {
	ID        string                    `json:"id"`
	Model     string                    `json:"model"`
	LatencyMs float64                   `json:"latency_ms"`
	Answers   map[string]DecisionAnswer `json:"answers"`
}

type DecisionAnswer struct {
	Type          string             `json:"type"`
	Choice        *string            `json:"choice,omitempty"`
	Score         *float64           `json:"score,omitempty"`
	Noul          *float64           `json:"noul,omitempty"`
	Confidence    *float64           `json:"confidence,omitempty"`
	Probabilities map[string]float64 `json:"probabilities,omitempty"`
}

func main() {
	apiKey := os.Getenv("HANZO_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Error: HANZO_API_KEY environment variable is required")
		os.Exit(1)
	}

	model := os.Getenv("KAI_MODEL")
	if model == "" {
		model = "kai" // or "typesafe/jev-1.13"
	}

	baseURL := os.Getenv("HANZO_BASE_URL")
	if baseURL == "" {
		baseURL = "https://api.hanzo.ai"
	}
	baseURL = strings.TrimRight(baseURL, "/")

	reqBody := DecisionRequest{
		Model: model,
		State: "High disk usage on node /dev/sda1 (98% full)",
		Questions: map[string]interface{}{
			"action": map[string]interface{}{
				"type":         "choice",
				"instructions": "Determine automated remediation action",
				"criteria": map[string]string{
					"purge_logs":  "safe deletion of expired container logs",
					"scale_disk":  "request EBS volume expansion",
					"page_oncall": "immediate human escalation required",
				},
			},
		},
	}

	payload, err := json.Marshal(reqBody)
	if err != nil {
		panic(err)
	}

	req, err := http.NewRequest("POST", baseURL+"/v1/decisions", bytes.NewBuffer(payload))
	if err != nil {
		panic(err)
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	if resp.StatusCode >= 400 {
		fmt.Fprintf(os.Stderr, "HTTP %d Error: %s\n", resp.StatusCode, string(body))
		os.Exit(1)
	}

	var decision DecisionResponse
	if err := json.Unmarshal(body, &decision); err != nil {
		fmt.Println("Raw response:", string(body))
		return
	}

	fmt.Printf("Model: %s\n", decision.Model)
	fmt.Printf("Decision ID: %s\n", decision.ID)
	fmt.Printf("Latency: %.1fms\n", decision.LatencyMs)
	if ans, ok := decision.Answers["action"]; ok && ans.Choice != nil {
		fmt.Printf("Action Choice: %s\n", *ans.Choice)
		if ans.Confidence != nil {
			fmt.Printf("Confidence: %.4f\n", *ans.Confidence)
		}
		if len(ans.Probabilities) > 0 {
			fmt.Println("Probabilities:")
			for opt, p := range ans.Probabilities {
				fmt.Printf("  - %s: %.2f%%\n", opt, p*100)
			}
		}
	}
}
