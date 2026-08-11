//! Certificador para a derivada da confiança (análogo a ξ')
use nalgebra::{DMatrix, SymmetricEigen};
use crate::inertia_certifier::InertiaCertifier;

pub struct DerivativeCertifier {
    pub threshold_simple_deriv: f64,   // 0.86864 (quártica)
    pub threshold_distinct_deriv: f64, // 0.93432 (quártica)
}

impl DerivativeCertifier {
    pub fn new() -> Self {
        Self {
            threshold_simple_deriv: 0.86864,
            threshold_distinct_deriv: 0.93432,
        }
    }

    /// Certifica a derivada da matriz de coerência
    pub fn certify_derivative(&self, matrix: &DMatrix<f64>, matrix_prev: &DMatrix<f64>, dt: f64) -> DerivativeCertificate {
        let deriv = (matrix - matrix_prev) / dt;
        let eigen = SymmetricEigen::new(deriv.clone());
        let vals = eigen.eigenvalues;
        let n = matrix.nrows() as f64;
        let trace = vals.sum();
        let frob_norm = vals.iter().map(|v: &f64| v.powi(2)).sum::<f64>().sqrt();

        let s_simple_deriv = f64::max(4.0 * trace - 2.0 * n - frob_norm.powi(2), 0.0) / n;
        let s_distinct_deriv = f64::max(0.5 * (4.0 * trace - n - frob_norm.powi(2)), 0.0) / n;

        DerivativeCertificate {
            s_simple_deriv,
            s_distinct_deriv,
            simple_achieved: s_simple_deriv >= self.threshold_simple_deriv,
            distinct_achieved: s_distinct_deriv >= self.threshold_distinct_deriv,
        }
    }
}

pub struct DerivativeCertificate {
    pub s_simple_deriv: f64,
    pub s_distinct_deriv: f64,
    pub simple_achieved: bool,
    pub distinct_achieved: bool,
}
