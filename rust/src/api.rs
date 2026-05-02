use crate::risk::{compute_risk, MarketType, RiskInput, RiskOutput};

#[flutter_rust_bridge::frb(sync)]
pub fn ping() -> String {
    "pong".to_owned()
}

#[flutter_rust_bridge::frb(sync)]
pub fn calculate_risk(input: RiskInput) -> RiskOutput {
    compute_risk(input)
}
