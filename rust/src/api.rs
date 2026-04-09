use crate::risk::{RiskInput, RiskOutput, compute_risk as compute_risk_inner};

#[flutter_rust_bridge::frb(sync)]
pub fn ping() -> String {
    "pong".to_owned()
}

#[flutter_rust_bridge::frb(sync)]
pub fn compute_risk(input: RiskInput) -> RiskOutput {
    compute_risk_inner(input)
}

#[cfg(test)]
mod tests {
    use super::ping;

    #[test]
    fn ping_returns_pong() {
        assert_eq!(ping(), "pong");
    }
}
