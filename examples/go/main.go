// net/http rather than github.com/hanzoai/go-sdk/v8: its v8.5.623 decoder refuses a choice
// question with named criteria ("data matches more than one schema in oneOf").
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
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

func run() error {
	apiKey := os.Getenv("HANZO_API_KEY")
	if apiKey == "" {
		return fmt.Errorf("HANZO_API_KEY environment variable is required")
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
		return err
	}

	req, err := http.NewRequest("POST", baseURL+"/v1/decisions", bytes.NewBuffer(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode >= 400 {
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, body)
	}

	var decision DecisionResponse
	if err := json.Unmarshal(body, &decision); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}

	ans, ok := decision.Answers["action"]
	if !ok || ans.Choice == nil {
		return fmt.Errorf("no choice answer for \"action\" in %s", body)
	}
	fmt.Printf("Model: %s\n", decision.Model)
	fmt.Printf("Decision ID: %s\n", decision.ID)
	fmt.Printf("Latency: %.1fms\n", decision.LatencyMs)
	fmt.Printf("Action Choice: %s\n", *ans.Choice)
	if ans.Confidence != nil {
		fmt.Printf("Confidence: %.4f\n", *ans.Confidence)
	}
	fmt.Println("Probabilities:")
	for opt, p := range ans.Probabilities {
		fmt.Printf("  - %s: %.2f%%\n", opt, p*100)
	}
	return nil
}
