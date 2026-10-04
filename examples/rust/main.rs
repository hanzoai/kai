use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let api_key = std::env::var("HANZO_API_KEY").expect("HANZO_API_KEY required");
    let client = reqwest::Client::new();

    let res = client
        .post("https://api.hanzo.ai/v1/decisions")
        .bearer_auth(api_key)
        .json(&json!({
            "model": "kai",
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
        .await?
        .text()
        .await?;

    println!("Decision output: {}", res);
    Ok(())
}
