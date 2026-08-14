pub struct SecurityMetrics {
    pub evidence_rate: f64,
    pub impact: f64,
}

impl SecurityMetrics {
    pub fn new(evidence_rate: f64, impact: f64) -> Self {
        Self {
            evidence_rate,
            impact,
        }
    }

    /// Contrato para SecurityMetrics::pressure
    #[cfg_attr(kani, kani::ensures(|result| *result >= 0.0 && *result <= 1.0))]
    pub fn pressure(&self) -> f64 {
        self.evidence_rate * self.impact
    }
}

pub struct PolicyCapacity {
    pub max_pressure: f64,
}

impl PolicyCapacity {
    pub fn new(max_pressure: f64) -> Self {
        Self { max_pressure }
    }

    /// Contrato para PolicyCapacity::is_safe
    #[cfg_attr(kani, kani::ensures(|result| *result == (pressure >= 0.0 && pressure <= self.max_pressure)))]
    pub fn is_safe(&self, pressure: f64) -> bool {
        pressure >= 0.0 && pressure <= self.max_pressure
    }
}

pub fn check_pressure(metrics: &SecurityMetrics, capacity: &PolicyCapacity) -> bool {
    metrics.pressure() <= capacity.max_pressure
}

pub struct PolicyEngine {
    max_pressure: f64,
    current_pressure: f64,
}

impl PolicyEngine {
    pub fn new(capacity: f64) -> Self {
        Self {
            max_pressure: capacity,
            current_pressure: 0.0,
        }
    }

    pub fn current_pressure(&self) -> f64 {
        self.current_pressure
    }

    pub fn max_pressure(&self) -> f64 {
        self.max_pressure
    }

    pub fn process_metrics(&mut self, metrics: &SecurityMetrics) -> Result<(), &'static str> {
        let p = metrics.pressure();
        if p <= self.max_pressure {
            self.current_pressure = p; // Simplification for the sake of S5/S11, actually wait: s5 stability check.
            Ok(())
        } else {
            Err("Capacity Exceeded")
        }
    }
}
