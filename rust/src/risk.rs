#[derive(Debug, Clone, Copy)]
pub enum MarketType {
    Moneyline,
    MainTotalHandicapSpread,
    SmallMarketTotalHandicap,
}

#[derive(Debug, Clone)]
pub struct RiskInput {
    pub arb_percent: f64,
    pub sports_count: u32,
    pub market_types: Vec<MarketType>,
}

#[derive(Debug, Clone, Copy)]
pub struct RiskOutput {
    pub score_a: f64,
    pub score_n: f64,
    pub score_m: f64,
    pub global_score: f64,
    pub level: u32,
}

pub fn compute_risk(_input: RiskInput) -> RiskOutput {
    RiskOutput {
        score_a: 0.0,
        score_n: 0.0,
        score_m: 0.0,
        global_score: 0.0,
        level: 1,
    }
}
