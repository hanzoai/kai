//! Model Routing & Inference Optimization Recipes.
//!
//! Enso/Kai routing patterns: single-shot model suitability prediction,
//! adaptive thinking depth budgeting, and calibrated LLM escalation.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// 1. Single-Shot Model Suitability Routing Recipe.
pub struct ModelSuitabilityRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct TaskComplexityState {
    pub prompt_token_count: usize,
    pub task_domain: String,
    pub requires_formal_reasoning: bool,
    pub requires_code_execution: bool,
    pub latency_deadline_ms: u32,
    pub max_cost_nano_usd: u64,
}

impl ModelSuitabilityRecipe {
    pub fn build_request(task: &TaskComplexityState) -> Value {
        json!({
            "model": "kai",
            "state": task,
            "questions": {
                "selected_tier": {
                    "type": "choice",
                    "instructions": "Predict optimal model tier achieving >= 95% success probability at lowest cost",
                    "criteria": {
                        "edge_fast_3b": "trivial classification or pattern extraction; sub-50ms local inference",
                        "cloud_flash_8b": "standard conversational synthesis or lightweight summarization",
                        "frontier_pro_deep": "complex scientific reasoning, full codebase refactoring, or multi-step logic"
                    }
                },
                "thinking_depth": {
                    "type": "choice",
                    "instructions": "Calibrate reasoning budget depth for the chosen tier",
                    "criteria": {
                        "off": "no chain-of-thought needed; direct token output",
                        "low": "lightweight verification check (< 1,000 tokens)",
                        "medium": "standard step-by-step reasoning",
                        "high": "deep exhaustive exploration with self-reflection (> 8,000 tokens)"
                    }
                }
            }
        })
    }
}

/// 2. Confidence-Gated LLM Escalation.
pub struct ConfidenceGate;

impl ConfidenceGate {
    /// Decides whether a fast Kai decision stands or requires escalation to an LLM.
    ///
    /// If margin (P_top - P_second) >= tau, returns None (Kai decision stands).
    /// If margin < tau, returns Some(target_llm) for fallback escalation.
    pub fn evaluate_escalation(
        probabilities: &[f64],
        tau: f64,
        target_llm: &str,
    ) -> Option<&'static str> {
        if probabilities.len() < 2 {
            return None;
        }
        let mut sorted = probabilities.to_vec();
        sorted.sort_by(|a, b| b.partial_cmp(a).unwrap_or(std::cmp::Ordering::Equal));
        let margin = sorted[0] - sorted[1];
        if margin < tau {
            Some(Box::leak(target_llm.to_string().into_boxed_str()))
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_model_suitability_request() {
        let task = TaskComplexityState {
            prompt_token_count: 520,
            task_domain: "customer_support".into(),
            requires_formal_reasoning: false,
            requires_code_execution: false,
            latency_deadline_ms: 500,
            max_cost_nano_usd: 10000,
        };
        let req = ModelSuitabilityRecipe::build_request(&task);
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["selected_tier"].is_object());
        assert!(req["questions"]["thinking_depth"].is_object());
    }

    #[test]
    fn test_confidence_escalation() {
        // High confidence: margin = 0.85 - 0.10 = 0.75 >= 0.40 -> Stands
        let stand = ConfidenceGate::evaluate_escalation(&[0.85, 0.10, 0.05], 0.40, "zen-6");
        assert!(stand.is_none());

        // Low confidence: margin = 0.48 - 0.45 = 0.03 < 0.40 -> Escalates to Zen
        let escalate = ConfidenceGate::evaluate_escalation(&[0.48, 0.45, 0.07], 0.40, "zen-6");
        assert_eq!(escalate, Some("zen-6"));
    }
}
