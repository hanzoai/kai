package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

type DecisionRequest struct {
	Model     string                 `json:"model"`
	State     any                    `json:"state"`
	Questions map[string]interface{} `json:"questions"`
}

func main() {
	apiKey := os.Getenv("HANZO_API_KEY")
	reqBody := DecisionRequest{
		Model: "kai",
		State: "High disk usage on node /dev/sda1 (98% full)",
		Questions: map[string]interface{}{
			"action": map[string]interface{}{
				"type":         "choice",
				"instructions": "Determine automated remediation action",
				"criteria": map[string]string{
					"purge_logs": "safe deletion of expired container logs",
					"scale_disk": "request EBS volume expansion",
					"page_oncall": "immediate human escalation required",
				},
			},
		},
	}

	payload, _ := json.Marshal(reqBody)
	req, _ := http.NewRequest("POST", "https://api.hanzo.ai/v1/decisions", bytes.NewBuffer(payload))
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Println(string(body))
}
