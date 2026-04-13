#[derive(Debug, Clone, Copy)]
pub enum MarketType {
    Moneyline,
    MainTotalHandicapSpread,
    SmallMarketTotalHandicap,
}

#[derive(Debug, Clone)]
pub struct RiskInput {
    pub arb_percent: f64,
    pub total_investment: f64,
    pub stake_distribution: Vec<f64>,
    pub bets_per_day: u32,
    pub books_count: u32,
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

pub fn compute_risk(input: RiskInput) -> RiskOutput {
    let score_a = match input.arb_percent {
        p if p <= 2.0 => 10.0,
        p if p <= 3.0 => 30.0,
        p if p <= 5.0 => 50.0,
        p if p <= 6.0 => 80.0,
        _ => 100.0,
    };

    let score_n = match input.sports_count {
        n if n <= 2 => 10.0,
        3 => 20.0,
        4 => 40.0,
        5 => 60.0,
        6 => 70.0,
        _ => 100.0,
    };

    let (sum_m, sum_w) = input.market_types.iter().fold((0.0, 0.0), |(sm, sw), m| {
        let (val, weight) = match m {
            MarketType::Moneyline => (10.0, 1.0),
            MarketType::MainTotalHandicapSpread => (30.0, 2.0),
            MarketType::SmallMarketTotalHandicap => (80.0, 4.0),
        };
        (sm + val * weight, sw + weight)
    });

    let score_m = if sum_w > 0.0 { sum_m / sum_w } else { 0.0 };

    let global_score = (score_a + score_n + score_m) / 3.0;

    let level = match global_score {
        s if s <= 10.0 => 1,
        s if s <= 20.0 => 2,
        s if s <= 30.0 => 3,
        s if s <= 40.0 => 4,
        s if s <= 50.0 => 5,
        s if s <= 60.0 => 6,
        s if s <= 70.0 => 7,
        s if s <= 80.0 => 8,
        s if s <= 90.0 => 9,
        _ => 10,
    };

    RiskOutput {
        score_a,
        score_n,
        score_m,
        global_score,
        level,
    }
}
