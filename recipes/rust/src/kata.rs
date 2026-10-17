//! Hanzo Kata Recipes: Autonomous Coding Agent Loop & CI/CD Triage Patterns.
//!
//! State machines for autonomous repo exploration, patch generation, test gating,
//! and self-healing repair loops.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// State of a failing repository or CI build to triage.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodingTriageState {
    pub repo_name: String,
    pub branch: String,
    pub failing_step: String,
    pub stdout_stderr: String,
    pub files_modified: Vec<String>,
    pub max_attempts: u32,
    pub current_attempt: u32,
}

/// Action verdict produced by the triage engine.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TriageAction {
    ApplyPatch {
        target_file: String,
        patch_diff: String,
    },
    ReRunTests {
        filter: Option<String>,
    },
    EscalateToHuman {
        reason: String,
    },
}

/// 1. Kata Autonomous Repair Recipe.
pub struct KataAgentLoopRecipe;

impl KataAgentLoopRecipe {
    /// Builds a prompt payload for a frontier coding LLM (e.g. `zen5-coder` or `enso`).
    pub fn build_patch_prompt(state: &CodingTriageState) -> Value {
        json!({
            "model": "zen5-coder",
            "messages": [
                {
                    "role": "system",
                    "content": "You are Hanzo Kata, an expert autonomous software engineer. Generate minimal unified diff patches that fix bugs without altering unrelated logic or style."
                },
                {
                    "role": "user",
                    "content": format!(
                        "Repository: {}\nFailing Step: {}\nAttempt: {}/{}\n\nError Output:\n```\n{}\n```\n\nModified Files: {:?}\n\nProvide the exact patch in unified diff format.",
                        state.repo_name,
                        state.failing_step,
                        state.current_attempt,
                        state.max_attempts,
                        state.stdout_stderr,
                        state.files_modified
                    )
                }
            ],
            "temperature": 0.0,
            "max_tokens": 4096
        })
    }

    /// Evaluates test execution exit code to decide the next loop state.
    pub fn evaluate_test_result(
        exit_code: i32,
        current_attempt: u32,
        max_attempts: u32,
    ) -> TriageAction {
        if exit_code == 0 {
            TriageAction::ReRunTests { filter: None }
        } else if current_attempt >= max_attempts {
            TriageAction::EscalateToHuman {
                reason: format!("Exceeded maximum repair attempts ({max_attempts}) without passing tests"),
            }
        } else {
            TriageAction::ApplyPatch {
                target_file: "src/lib.rs".into(),
                patch_diff: "// automated patch applied".into(),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_kata_patch_prompt_building() {
        let state = CodingTriageState {
            repo_name: "hanzoai/gateway".into(),
            branch: "fix/timeout".into(),
            failing_step: "cargo test --all".into(),
            stdout_stderr: "error[E0308]: mismatched types: expected usize, found u64".into(),
            files_modified: vec!["src/connection.rs".into()],
            max_attempts: 3,
            current_attempt: 1,
        };

        let payload = KataAgentLoopRecipe::build_patch_prompt(&state);
        assert_eq!(payload["model"], "zen5-coder");
        let messages = payload["messages"].as_array().unwrap();
        assert_eq!(messages.len(), 2);
        assert!(messages[1]["content"].as_str().unwrap().contains("error[E0308]"));
    }

    #[test]
    fn test_kata_test_evaluation_loop() {
        let passing = KataAgentLoopRecipe::evaluate_test_result(0, 1, 3);
        assert_eq!(passing, TriageAction::ReRunTests { filter: None });

        let failing_retry = KataAgentLoopRecipe::evaluate_test_result(1, 1, 3);
        match failing_retry {
            TriageAction::ApplyPatch { .. } => {}
            _ => panic!("Expected ApplyPatch on retryable failure"),
        }

        let failing_exhausted = KataAgentLoopRecipe::evaluate_test_result(1, 3, 3);
        match failing_exhausted {
            TriageAction::EscalateToHuman { reason } => {
                assert!(reason.contains("Exceeded maximum repair attempts"));
            }
            _ => panic!("Expected EscalateToHuman when attempts are exhausted"),
        }
    }
}
