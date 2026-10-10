// reqwest rather than the hanzo-client crate: its newest release, 8.5.156, has no /v1/decisions.
use serde_json::{json, Value};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let api_key = std::env::var("HANZO_API_KEY").map_err(|_| "HANZO_API_KEY environment variable required")?;
    let model = std::env::var("KAI_MODEL").unwrap_or_else(|_| "kai".to_string()); // "kai" or "typesafe/jev-1.13"
    let base_url = std::env::var("HANZO_BASE_URL").unwrap_or_else(|_| "https://api.hanzo.ai".to_string());
    let url = format!("{}/v1/decisions", base_url.trim_end_matches('/'));

    let client = reqwest::Client::new();

    let res = client
        .post(&url)
        .bearer_auth(api_key)
        .json(&json!({
            "model": model,
            "state": "Kubernetes pod evicted: OOMKilled",
            "questions": {
                "triage": {
                    "type": "choice",
                    "instructions": "Identify next step",
                    "criteria": {
                        "increase_limits": "raise memory requests and limits",
                        "restart": "restart pod on clean node",
                        "profile_memory": "attach memory profiler to inspect leak"
                    }
                }
            }
        }))
        .send()
        .await?;

    let status = res.status();
    if !status.is_success() {
        let err_text = res.text().await?;
        eprintln!("HTTP {} Error: {}", status, err_text);
        std::process::exit(1);
    }

    let decision: Value = res.json().await?;

    println!("Model: {}", decision["model"].as_str().unwrap_or("unknown"));
    println!("Decision ID: {}", decision["id"].as_str().unwrap_or(""));
    println!("Latency: {}ms", decision["latency_ms"]);

    let ans = &decision["answers"]["triage"];
    let choice = ans["choice"].as_str().ok_or_else(|| format!("no choice answer for \"triage\" in {}", decision))?;
    println!("Triage Choice: {}", choice);
    println!("Confidence: {:.4}", ans["confidence"].as_f64().unwrap_or_default());
    println!("Probabilities:");
    for (opt, prob) in ans["probabilities"].as_object().into_iter().flatten() {
        println!("  - {}: {:.2}%", opt, prob.as_f64().unwrap_or_default() * 100.0);
    }

    Ok(())
}
