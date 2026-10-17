//! Industrial Systems & Fleet Decision Recipes (Generic & Brandless).
//!
//! Folded from domain 'L': generic industrial equipment, fleet powertrain trade studies,
//! sensor telematics, and operational readiness gates.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// 1. Commercial Fleet Powertrain Trade Study (EV vs. Hybrid vs. Diesel).
pub struct PowertrainTradeRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct PowertrainCandidate {
    pub id: String,
    pub name: String,
    pub fuel_economy_mpg: f64,
    pub payload_capacity_kg: f64,
    pub acquisition_cost_usd: f64,
    pub annual_maintenance_usd: f64,
    pub emissions_reduction_pct: f64,
}

impl PowertrainTradeRecipe {
    pub fn build_request(candidates: &[PowertrainCandidate], priority: &str) -> Value {
        json!({
            "model": "kai",
            "state": {
                "fleet_size": 500,
                "annual_miles_per_unit": 65000,
                "priority": priority,
                "candidates": candidates
            },
            "questions": {
                "recommended_powertrain": {
                    "type": "choice",
                    "instructions": "Select optimal fleet powertrain balancing TCO and sustainability",
                    "criteria": {
                        "battery_electric": "lowest operating cost and zero direct emissions; high upfront capital",
                        "hybrid_electric": "balanced range extension, proven reliability, and 30% fuel savings",
                        "clean_diesel": "lowest initial acquisition cost; highest lifetime emissions and fuel expense"
                    }
                },
                "fleet_transition_pace": {
                    "type": "choice",
                    "instructions": "Recommended multi-year rollout cadence",
                    "criteria": {
                        "aggressive_pilot": "convert 25% of depot routes in Year 1",
                        "gradual_lifecycle": "replace vehicles strictly at scheduled end-of-life retirement",
                        "hold_and_monitor": "defer transition until regional megawatt charging infrastructure matures"
                    }
                }
            }
        })
    }
}

/// 2. Industrial Equipment / Telematics Readiness Gate.
pub struct EquipmentReadinessRecipe;

#[derive(Debug, Serialize, Deserialize)]
pub struct SensorReading {
    pub channel: String,
    pub value: f64,
    pub normal_min: f64,
    pub normal_max: f64,
    pub unit: String,
    pub age_seconds: u32,
}

impl EquipmentReadinessRecipe {
    pub fn build_request(asset_id: &str, readings: &[SensorReading], op_report: &str) -> Value {
        json!({
            "model": "kai",
            "state": {
                "asset_id": asset_id,
                "readings": readings,
                "operator_report": op_report
            },
            "questions": {
                "fault_severity": {
                    "type": "choice",
                    "instructions": "Assess diagnostic fault level across telematics channels",
                    "criteria": {
                        "nominal": "all telemetry within allowable operating bands",
                        "caution": "transient or single-sensor minor excursion; safe for continued shift",
                        "warning": "significant thermal or pressure deviation; maintenance intervention required",
                        "critical": "imminent mechanical failure risk; immediate shutdown required"
                    }
                },
                "dispatch_readiness": {
                    "type": "choice",
                    "instructions": "Operational release decision",
                    "criteria": {
                        "go": "equipment certified for full duty cycle",
                        "go_conditional": "equipment permitted for limited local run under monitoring",
                        "no_go": "equipment grounded until maintenance signoff"
                    }
                },
                "human_supervisor_required": {
                    "type": "noul",
                    "instructions": "Does this fault condition mandate licensed engineer physical inspection?"
                }
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_powertrain_trade_request() {
        let candidates = vec![
            PowertrainCandidate {
                id: "ev-1".into(),
                name: "Class-8 EV".into(),
                fuel_economy_mpg: 0.0,
                payload_capacity_kg: 24000.0,
                acquisition_cost_usd: 340000.0,
                annual_maintenance_usd: 8000.0,
                emissions_reduction_pct: 100.0,
            },
            PowertrainCandidate {
                id: "hy-1".into(),
                name: "Class-8 Hybrid".into(),
                fuel_economy_mpg: 11.5,
                payload_capacity_kg: 26000.0,
                acquisition_cost_usd: 210000.0,
                annual_maintenance_usd: 12000.0,
                emissions_reduction_pct: 35.0,
            },
        ];
        let req = PowertrainTradeRecipe::build_request(&candidates, "tco_and_emissions");
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["recommended_powertrain"].is_object());
    }

    #[test]
    fn test_equipment_readiness_request() {
        let readings = vec![
            SensorReading {
                channel: "hydraulic_pressure".into(),
                value: 2950.0,
                normal_min: 2800.0,
                normal_max: 3200.0,
                unit: "psi".into(),
                age_seconds: 2,
            },
            SensorReading {
                channel: "oil_temperature".into(),
                value: 104.2,
                normal_min: 70.0,
                normal_max: 95.0,
                unit: "celsius".into(),
                age_seconds: 1,
            },
        ];
        let req = EquipmentReadinessRecipe::build_request(
            "TURBINE-GEN-04",
            &readings,
            "Slight audible whine during startup phase",
        );
        assert_eq!(req["model"], "kai");
        assert!(req["questions"]["dispatch_readiness"].is_object());
        assert!(req["questions"]["human_supervisor_required"].is_object());
    }
}
