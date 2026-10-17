//! Hanzo Kai Recipes: Modular, production-grade decision patterns.
//!
//! Reusable recipes across retail, industrial systems, commerce, and intelligent routing.

pub mod gen;
pub mod industrial;
pub mod kata;
pub mod retail;
pub mod routing;
pub mod zen;

pub use gen::{GenSession, GenTurn, GenWorkflowRecipe};
pub use industrial::{EquipmentReadinessRecipe, PowertrainTradeRecipe};
pub use kata::{CodingTriageState, KataAgentLoopRecipe, TriageAction};
pub use retail::{PricingGuardrailRecipe, ReturnsFraudRecipe, ShelfInventoryRecipe};
pub use routing::{ConfidenceGate, ModelSuitabilityRecipe};
pub use zen::{ChatMessage, ZenChatConfig, ZenChatRecipe, ZenStreamAccumulator};
