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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_low_risk_scenario() {
        let input = RiskInput {
            arb_percent: 1.5,
            total_investment: 100.0,
            stake_distribution: vec![50.0, 50.0],
            bets_per_day: 2,
            books_count: 5,
            sports_count: 2,
            market_types: vec![MarketType::Moneyline],
        };
        let output = compute_risk(input);
        assert_eq!(output.score_a, 10.0);
        assert_eq!(output.score_n, 10.0);
        assert_eq!(output.score_m, 10.0);
        assert_eq!(output.global_score, 10.0);
        assert_eq!(output.level, 1);
    }

    #[test]
    fn test_high_risk_scenario() {
        let input = RiskInput {
            arb_percent: 7.0,
            total_investment: 500.0,
            stake_distribution: vec![250.0, 250.0],
            bets_per_day: 15,
            books_count: 2,
            sports_count: 10,
            market_types: vec![MarketType::SmallMarketTotalHandicap],
        };
        let output = compute_risk(input);
        assert_eq!(output.score_a, 100.0);
        assert_eq!(output.score_n, 100.0);
        assert_eq!(output.score_m, 80.0);
        assert!(output.global_score > 90.0);
        assert_eq!(output.level, 10);
    }

    #[test]
    fn test_market_weighting() {
        let input = RiskInput {
            arb_percent: 2.0,
            total_investment: 100.0,
            stake_distribution: vec![50.0, 50.0],
            bets_per_day: 5,
            books_count: 3,
            sports_count: 3,
            market_types: vec![MarketType::Moneyline, MarketType::SmallMarketTotalHandicap],
        };
        // M = (10*1 + 80*4) / (1+4) = 330 / 5 = 66.0
        let output = compute_risk(input);
        assert_eq!(output.score_m, 66.0);
    }
}
