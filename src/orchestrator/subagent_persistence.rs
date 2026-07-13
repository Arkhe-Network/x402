//! Cathedral ARKHE v28.3.2 — Subagent Persistence
//! Serialização e persistência de subagentes para suspensão/retomada.
//! Selo: CATHEDRAL-ARKHE-v28.3.2-SUBAGENT-PERSISTENCE-2026-06-17

use std::sync::Arc;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

use crate::orchestrator::subagent_spawner::{Subagent, SubagentIdentity};
use crate::orchestrator::context::{Context, ContextEntry};
use crate::memory::TrajectoryStore;
use crate::attestation::PolicyDescriptor;
use crate::attestation::AttestationSigner;

// ============================================================================
// 1. Estado Serializável
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubagentState {
    pub identity: SubagentIdentity,
    pub policies: Vec<PolicyDescriptor>,
    pub context_entries: Vec<ContextEntry>,
    pub tools: Vec<String>,
    pub is_active: bool,
    pub last_activity: DateTime<Utc>,
    pub parent_id: String,
}

impl SubagentState {
    /// Cria um estado a partir de um subagente ativo.
    pub async fn from_subagent(subagent: &Subagent) -> Self {
        let entries = subagent.context.get_entries().await;
        Self {
            identity: subagent.identity.clone(),
            policies: subagent.policies.clone(),
            context_entries: entries,
            tools: subagent.tools.clone(),
            is_active: subagent.is_active,
            last_activity: subagent.last_activity,
            parent_id: subagent.identity.parent_id.clone(),
        }
    }

    /// Reconstrói um subagente a partir do estado.
    pub async fn into_subagent(
        self,
        parent_signer: Arc<dyn AttestationSigner + Send + Sync>,
        trajectory_store: Arc<TrajectoryStore>,
    ) -> Subagent {
        let ctx = Arc::new(Context::new(&self.identity.id));
        for entry in &self.context_entries {
            let _ = ctx.add(&entry.content, entry.role.clone(), entry.importance).await;
        }
        Subagent {
            identity: self.identity,
            policies: self.policies,
            context: ctx,
            tools: self.tools,
            parent_signer,
            trajectory_store,
            is_active: self.is_active,
            last_activity: self.last_activity,
        }
    }
}
