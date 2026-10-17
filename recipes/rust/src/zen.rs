//! Hanzo Zen Recipes: Generative Foundation LLM Integration Patterns.
//!
//! OpenAI wire format request construction, Server-Sent Events (SSE) stream parsing,
//! reasoning token extraction (`reasoning_content`), and structured tool calling.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// Configuration for a Zen generative completion request.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZenChatConfig {
    pub model: String,
    pub temperature: f32,
    pub max_tokens: u32,
    pub stream: bool,
    pub reasoning_effort: Option<String>, // "low", "medium", "high"
}

impl Default for ZenChatConfig {
    fn default() -> Self {
        Self {
            model: "zen".into(),
            temperature: 0.2,
            max_tokens: 2048,
            stream: false,
            reasoning_effort: None,
        }
    }
}

/// A chat message in the conversation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

/// 1. Zen Chat Completion Recipe.
pub struct ZenChatRecipe;

impl ZenChatRecipe {
    /// Builds an OpenAI-compatible request payload for Zen.
    pub fn build_request(config: &ZenChatConfig, messages: &[ChatMessage]) -> Value {
        let mut payload = json!({
            "model": config.model,
            "messages": messages,
            "temperature": config.temperature,
            "max_tokens": config.max_tokens,
            "stream": config.stream,
        });

        if let Some(ref effort) = config.reasoning_effort {
            payload["reasoning_effort"] = json!(effort);
        }

        payload
    }

    /// Builds a function/tool calling request payload for Zen.
    pub fn build_tool_request(
        config: &ZenChatConfig,
        messages: &[ChatMessage],
        tools: &[Value],
    ) -> Value {
        let mut payload = Self::build_request(config, messages);
        payload["tools"] = json!(tools);
        payload["tool_choice"] = json!("auto");
        payload
    }
}

/// Accumulated stream state from Zen's SSE output.
#[derive(Debug, Default, Clone)]
pub struct ZenStreamAccumulator {
    pub reasoning_content: String,
    pub content: String,
    pub finish_reason: Option<String>,
}

impl ZenStreamAccumulator {
    pub fn new() -> Self {
        Self::default()
    }

    /// Ingests a single Server-Sent Events data line (e.g. `data: {"choices": [...]}`).
    /// Returns true if a chunk was processed, false if end-of-stream `[DONE]` or comment.
    pub fn ingest_sse_line(&mut self, line: &str) -> Result<bool, serde_json::Error> {
        let trimmed = line.trim();
        if !trimmed.starts_with("data:") {
            return Ok(false);
        }

        let raw_json = trimmed[5..].trim();
        if raw_json == "[DONE]" {
            return Ok(false);
        }

        let parsed: Value = serde_json::from_str(raw_json)?;
        if let Some(choice) = parsed.get("choices").and_then(|c| c.get(0)) {
            if let Some(delta) = choice.get("delta") {
                if let Some(reasoning) = delta.get("reasoning_content").and_then(|r| r.as_str()) {
                    self.reasoning_content.push_str(reasoning);
                }
                if let Some(content) = delta.get("content").and_then(|c| c.as_str()) {
                    self.content.push_str(content);
                }
            }
            if let Some(reason) = choice.get("finish_reason").and_then(|r| r.as_str()) {
                self.finish_reason = Some(reason.to_string());
            }
        }

        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zen_request_generation() {
        let config = ZenChatConfig {
            model: "zen5-pro".into(),
            temperature: 0.1,
            max_tokens: 4096,
            stream: true,
            reasoning_effort: Some("high".into()),
        };

        let messages = vec![
            ChatMessage {
                role: "system".into(),
                content: "You are a deterministic code reasoner.".into(),
            },
            ChatMessage {
                role: "user".into(),
                content: "Optimize this algorithm".into(),
            },
        ];

        let req = ZenChatRecipe::build_request(&config, &messages);
        assert_eq!(req["model"], "zen5-pro");
        assert_eq!(req["stream"], true);
        assert_eq!(req["reasoning_effort"], "high");
        assert_eq!(req["messages"].as_array().unwrap().len(), 2);
    }

    #[test]
    fn test_zen_sse_stream_accumulator() {
        let mut acc = ZenStreamAccumulator::new();

        let sse_chunk_1 = "data: {\"choices\": [{\"delta\": {\"reasoning_content\": \"Analyzing performance bottleneck...\"}}]}";
        let sse_chunk_2 = "data: {\"choices\": [{\"delta\": {\"content\": \"Use a hash map to achieve O(1) lookups.\"}}]}";
        let sse_done = "data: [DONE]";

        assert!(acc.ingest_sse_line(sse_chunk_1).unwrap());
        assert_eq!(acc.reasoning_content, "Analyzing performance bottleneck...");
        assert_eq!(acc.content, "");

        assert!(acc.ingest_sse_line(sse_chunk_2).unwrap());
        assert_eq!(acc.reasoning_content, "Analyzing performance bottleneck...");
        assert_eq!(acc.content, "Use a hash map to achieve O(1) lookups.");

        assert!(!acc.ingest_sse_line(sse_done).unwrap());
    }
}
