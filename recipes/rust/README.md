# Hanzo Kai Recipes (Modular Rust Decision Blueprints)

Production-grade, modular decision recipes in Rust for **Hanzo Kai** (`/v1/decisions`).

Unlike rigid end-to-end Decision Programs (in [`examples/`](../examples)), **Recipes** are composable building blocks that applications can import, customize, and execute directly in Rust or serialize to JSON for HTTP endpoints.

---

## Architecture Overview

```
                            ┌────────────────────────────────────────┐
                            │          Operational State             │
                            │  (Telemetry, Shelf Scan, Pricing, Task)│
                            └───────────────────┬────────────────────┘
                                                │
                                    ┌───────────▼───────────┐
                                    │     Recipe Builder    │
                                    │ (Typed Rust Structs)  │
                                    └───────────┬───────────┘
                                                │
                                    ┌───────────▼───────────┐
                                    │    POST /v1/decisions │
                                    │     or libkai in-proc │
                                    └───────────┬───────────┘
                                                │
                                    ┌───────────▼───────────┐
                                    │  Calibrated Decision  │
                                    │   (Sub-90ms latency)  │
                                    └───────────────────────┘
```

---

## Available Recipe Modules

### 1. `recipes::retail` (Omnichannel Retail & Supply Chain)
* **`ShelfInventoryRecipe`**: Real-time triage of out-of-stock items, low facings, and misplaced SKUs.
* **`ReturnsFraudRecipe`**: Serial mismatch verification, packaging tamper detection, and cashier quarantine directives.
* **`PricingGuardrailRecipe`**: High-speed corporate safety ceiling preventing catastrophic pricing fat-finger errors (e.g. 90% drops).

### 2. `recipes::industrial` (Generic Industrial Equipment & Fleets)
* **`PowertrainTradeRecipe`**: Multi-criteria trade study evaluating Battery Electric vs. Hybrid vs. Clean Diesel fleets.
* **`EquipmentReadinessRecipe`**: Sensor telematics fault diagnosis, severity scoring, and go/no-go operational release gates.

### 3. `recipes::routing` (Inference Optimization & Confidence Gating)
* **`ModelSuitabilityRecipe`**: Single-shot task complexity classification predicting whether a query requires edge quantized models vs. cloud frontier models.
* **`ConfidenceGate`**: Evaluates Kai decision margins ($\Delta = P_{(1)} - P_{(2)}$) against a threshold $\tau$. If confidence is high, the fast 90ms Kai decision stands; if low, it escalates to an LLM like Zen.

### 4. `recipes::zen` (Generative LLM & Streaming SSE)
* **`ZenChatRecipe`**: Builds OpenAI-compatible chat completions requests for Zen foundation models (`zen5`, `zen5-pro`, `zen5-coder`) with configurable reasoning effort (`reasoning_effort: "high"`).
* **`ZenStreamAccumulator`**: Real-time SSE chunk parser extracting streaming thought process tokens (`reasoning_content`) and final markdown response.
* **`ZenToolCallRecipe`**: Declarative tool/function schema generator for LLM agent actions.

### 5. `recipes::kata` (Autonomous Coding & CI/CD Gating)
* **`KataAgentLoopRecipe`**: Self-healing test-and-repair state machine that ingests failing compiler/test output, queries code generation models, and produces minimal unified diffs.
* **`GateEvaluation`**: Evaluates test exit codes, enforces attempt limits, and gates automated git commit vs. human escalation.

### 6. `recipes::gen` (Conversational Assistant & MCP Dispatch)
* **`GenWorkflowRecipe`**: Stateful multi-turn conversational agent harness managing turn history, tool execution callbacks, and sync tokens for Hanzo Mission Control.

---

## Usage in Rust

Add `recipes` to your `Cargo.toml`:
```toml
[dependencies]
recipes = { path = "recipes" }
```

```rust
use recipes::retail::{ShelfInventoryRecipe, ShelfSlotState};

let slot = ShelfSlotState {
    aisle_id: "A12-SNACKS".into(),
    planogram_id: "PL-SNACK-01".into(),
    expected_sku: "SKU-PRETZEL-16OZ".into(),
    expected_facings: 4,
    observed_facings: 0,
    erp_on_hand_qty: 38,
};

let request_body = ShelfInventoryRecipe::build_request(&slot);
// Send request_body to http://localhost:8080/v1/decisions or call in-process via libkai
```

---

## Testing

Run all recipes through the test suite:
```bash
cargo test -p recipes
```
