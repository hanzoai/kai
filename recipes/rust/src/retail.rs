//! Enterprise Retail & Supply Chain Recipes.
//!
//! Production-grade typed decision patterns covering shelf inventory, returns fraud,
//! cross-dock triage, pricing guardrails, and cold-chain IoT.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// 1. Shelf & Ghost Inventory Detection Recipe.
pub struct ShelfInventoryRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct ShelfSlotState {
    pub aisle_id: String,
    pub planogram_id: String,
    pub expected_sku: String,
    pub expected_facings: u32,
    pub observed_facings: u32,
    pub erp_on_hand_qty: i32,
}

impl ShelfInventoryRecipe {
    pub fn build_request(slot: &ShelfSlotState) -> Value {
        json!({
            "model": "kai",
            "state": slot,
            "questions": {
                "on_shelf_status": {
                    "type": "choice",
                    "instructions": "Evaluate shelf replenishment state against planogram",
                    "criteria": {
                        "full_facing": "correct item in stock with proper facing count",
                        "low_facing": "correct item in stock but below minimum threshold (< 2 facings)",
                        "out_of_stock": "slot is empty; void detected on shelf peg/tray",
                        "misplaced_sku": "foreign SKU placed in front of target slot (ghost inventory)"
                    }
                },
                "replenish_priority": {
                    "type": "score",
                    "instructions": "Urgency of associate restock dispatch",
                    "criteria": [
                        "routine: restock on next regular night cycle",
                        "elevated: high-velocity item with low facing",
                        "immediate: empty shelf on primary promotion SKU"
                    ]
                },
                "phantom_inventory_flag": {
                    "type": "noul",
                    "instructions": "Does ERP record positive on-hand inventory while physical shelf is confirmed empty?"
                }
            }
        })
    }
}

/// 2. Returns Fraud & Serial Inspection Recipe.
pub struct ReturnsFraudRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct ReturnInspectionState {
    pub return_id: String,
    pub item_sku: String,
    pub scanned_serial: String,
    pub box_serial: String,
    pub expected_weight_g: f64,
    pub measured_weight_g: f64,
}

impl ReturnsFraudRecipe {
    pub fn build_request(inspection: &ReturnInspectionState) -> Value {
        json!({
            "model": "kai",
            "state": inspection,
            "questions": {
                "fraud_indicator": {
                    "type": "choice",
                    "instructions": "Classify return condition and authenticity signals",
                    "criteria": {
                        "authentic_resalable": "all seals intact, exact serial match, unpowered",
                        "authentic_open_box": "genuine unit, opened packaging, complete accessories",
                        "serial_mismatch": "chassis serial does not match sales record or outer carton",
                        "item_swap_tamper": "weight discrepancy > 10% or non-genuine unit enclosed"
                    }
                },
                "refund_action": {
                    "type": "choice",
                    "instructions": "Cashier workflow decision",
                    "criteria": {
                        "approve_instant": "credit original payment immediately",
                        "manager_review": "escalate to store lead for physical box opening",
                        "hold_investigate": "quarantine item for asset protection investigation"
                    }
                }
            }
        })
    }
}

/// 3. Autonomous Pricing & Discount Guardrail Gate.
pub struct PricingGuardrailRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct PriceChangeState {
    pub sku: String,
    pub current_price: f64,
    pub proposed_price: f64,
    pub category_margin: f64,
}

impl PricingGuardrailRecipe {
    pub fn build_request(state: &PriceChangeState) -> Value {
        let percent_drop = (state.current_price - state.proposed_price) / state.current_price;
        json!({
            "model": "kai",
            "state": {
                "sku": state.sku,
                "current_price": state.current_price,
                "proposed_price": state.proposed_price,
                "percent_drop": percent_drop,
                "category_margin": state.category_margin
            },
            "questions": {
                "guardrail_verdict": {
                    "type": "choice",
                    "instructions": "Corporate safety and price error gate",
                    "criteria": {
                        "allow": "price change within safe 15% promotional envelope",
                        "ask_human_override": "price drop exceeds 30%; requires category manager two-key approval",
                        "deny_hard_stop": "catastrophic price error detected (decimal fat-finger); abort immediately"
                    }
                }
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shelf_inventory_request() {
        let slot = ShelfSlotState {
            aisle_id: "A12-SNACKS".into(),
            planogram_id: "PL-SNACK-01".into(),
            expected_sku: "SKU-PRETZEL-16OZ".into(),
            expected_facings: 4,
            observed_facings: 0,
            erp_on_hand_qty: 38,
        };
        let req = ShelfInventoryRecipe::build_request(&slot);
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["on_shelf_status"].is_object());
    }

    #[test]
    fn test_returns_fraud_request() {
        let ret = ReturnInspectionState {
            return_id: "RET-1092".into(),
            item_sku: "SKU-HEADPHONES-PRO".into(),
            scanned_serial: "SN-991A".into(),
            box_serial: "SN-991B".into(),
            expected_weight_g: 450.0,
            measured_weight_g: 220.0,
        };
        let req = ReturnsFraudRecipe::build_request(&ret);
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["fraud_indicator"].is_object());
    }

    #[test]
    fn test_pricing_guardrail_request() {
        let price = PriceChangeState {
            sku: "SKU-TV-75".into(),
            current_price: 1200.0,
            proposed_price: 120.0, // 90% drop error
            category_margin: 0.22,
        };
        let req = PricingGuardrailRecipe::build_request(&price);
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["guardrail_verdict"].is_object());
    }
}
