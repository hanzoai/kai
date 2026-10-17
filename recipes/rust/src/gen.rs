//! Hanzo Gen Recipes: Conversational Assistant & Tool Dispatch Patterns.
//!
//! Multi-turn dialogue management, tool call orchestration, and session state persistence.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// A session descriptor for a Gen agent run.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenSession {
    pub session_id: String,
    pub agent_profile: String,
    pub mission_control_sync: bool,
    pub turns: Vec<GenTurn>,
}

/// A single turn in a Gen session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenTurn {
    pub role: String,
    pub content: String,
    pub tool_calls: Option<Vec<Value>>,
}

/// 1. Gen Conversational Agent Recipe.
pub struct GenWorkflowRecipe;

impl GenWorkflowRecipe {
    /// Initializes a new session.
    pub fn new_session(session_id: &str, profile: &str, sync: bool) -> GenSession {
        GenSession {
            session_id: session_id.to_string(),
            agent_profile: profile.to_string(),
            mission_control_sync: sync,
            turns: Vec::new(),
        }
    }

    /// Appends a user turn to the session.
    pub fn add_user_message(session: &mut GenSession, message: &str) {
        session.turns.push(GenTurn {
            role: "user".into(),
            content: message.to_string(),
            tool_calls: None,
        });
    }

    /// Appends an assistant response (with optional tool calls).
    pub fn add_assistant_message(
        session: &mut GenSession,
        message: &str,
        tool_calls: Option<Vec<Value>>,
    ) {
        session.turns.push(GenTurn {
            role: "assistant".into(),
            content: message.to_string(),
            tool_calls,
        });
    }

    /// Builds the execution payload for the model API (Enso or Zen).
    pub fn build_agent_request(session: &GenSession, available_tools: &[Value]) -> Value {
        let messages: Vec<Value> = session
            .turns
            .iter()
            .map(|t| {
                let mut m = json!({
                    "role": t.role,
                    "content": t.content
                });
                if let Some(ref tc) = t.tool_calls {
                    m["tool_calls"] = json!(tc);
                }
                m
            })
            .collect();

        json!({
            "model": "enso-pro",
            "messages": messages,
            "tools": available_tools,
            "metadata": {
                "session_id": session.session_id,
                "sync_mc": session.mission_control_sync
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gen_workflow_turn_accumulation() {
        let mut session = GenWorkflowRecipe::new_session("sess_001", "dev_copilot", true);
        assert_eq!(session.turns.len(), 0);

        GenWorkflowRecipe::add_user_message(&mut session, "Analyze warehouse anomaly at dock 4");
        assert_eq!(session.turns.len(), 1);

        let tools = vec![json!({
            "type": "function",
            "function": {
                "name": "query_dock_sensors",
                "description": "Fetch real-time telematics from dock doors",
                "parameters": {"type": "object", "properties": {"dock_id": {"type": "integer"}}}
            }
        })];

        let req = GenWorkflowRecipe::build_agent_request(&session, &tools);
        assert_eq!(req["model"], "enso-pro");
        assert_eq!(req["metadata"]["session_id"], "sess_001");
        assert_eq!(req["tools"].as_array().unwrap().len(), 1);
    }
}
