extern crate alloc;

use arkhe_quantum_auth::{
    crypto_impl::{Aes256GcmSivAead, MlDsa65, XWingKem},
    fast_path::{FastPathAuth, HeraldMessage},
    key_hierarchy::KeyHierarchy,
    platform,
    policy::{PolicyContext, QuantumLinkPolicy},
    slow_path::{SlowPathAuth, SlowPathMessage},
    types::NodeId,
    QuantumAuthStack,
};
use rand::rngs::OsRng;

struct MockChannel {
    latency_ns: u64,
}

impl MockChannel {
    fn reliable() -> Self { Self { latency_ns: 100 } }
    fn send(&self, buf: &[u8]) -> Option<alloc::vec::Vec<u8>> {
        platform::tick_monotonic(self.latency_ns);
        Some(buf.to_vec())
    }
}

struct Node {
    kem_pk: alloc::vec::Vec<u8>,
    kem_sk: alloc::vec::Vec<u8>,
    stack: QuantumAuthStack<Aes256GcmSivAead, MlDsa65, XWingKem, QuantumLinkPolicy>,
    did: NodeId,
}

fn setup_node(did_prefix: u8) -> Node {
    let sig = MlDsa65;
    let kem = XWingKem;
    let (slow, pk, kem_pk, kem_sk) = SlowPathAuth::generate(sig, kem, &mut OsRng);

    let did = NodeId::new(did_prefix, &{
        let mut hash = [0u8; 32];
        hash.copy_from_slice(&pk[..32.min(pk.len())]);
        hash
    });

    let kh = KeyHierarchy::from_xwing_shared_secret([0u8; 32]).unwrap();
    let fast = FastPathAuth::new(kh, Aes256GcmSivAead);

    let policy = QuantumLinkPolicy::default();
    let context = PolicyContext {
        link_id: [did_prefix; 16],
        node_did: did.0,
        burst_msg_count: 0,
        last_rotation_ns: 0,
        anomaly_score: 0.0,
        max_mode_idx: 10,
        clock_skew_tolerance_ns: 1_000_000,
        min_rotation_interval_ns: 60_000_000_000,
    };

    let stack = QuantumAuthStack::new(fast, slow, policy, context);
    Node { kem_pk, kem_sk, stack, did }
}

#[test]
fn test_full_link_establishment_and_herald_exchange() {
    platform::set_monotonic_ns(1_000_000_000);
    let mut alice = setup_node(0x01);
    let mut bob = setup_node(0x02);

    let bob_kem_pk = bob.kem_pk.clone();
    let (encap_msg, alice_ss) = alice.stack.slow.bootstrap_encapsulate(&bob_kem_pk, &mut OsRng);

    let channel = MockChannel::reliable();
    let wire = match &encap_msg {
        SlowPathMessage::KemEncapsulate { ct, ephemeral_pk } => {
            let mut buf = alloc::vec::Vec::with_capacity(4 + ct.len() + ephemeral_pk.len());
            buf.extend_from_slice(&(ct.len() as u32).to_le_bytes());
            buf.extend_from_slice(ct);
            buf.extend_from_slice(ephemeral_pk);
            buf
        }
        _ => panic!("expected KemEncapsulate"),
    };
    let received = channel.send(&wire).expect("bootstrap message lost");

    let ct_len = u32::from_le_bytes(received[0..4].try_into().unwrap()) as usize;
    let ct = received[4..4 + ct_len].to_vec();
    let ephemeral_pk = received[4 + ct_len..].to_vec();
    let decap_msg = SlowPathMessage::KemEncapsulate { ct, ephemeral_pk };

    let bob_kem_sk = bob.kem_sk.clone();
    let (bob_ss, _peer_pk) = bob.stack.slow.bootstrap_decapsulate(&decap_msg, &bob_kem_sk).expect("Failed to decapsulate");

    let alice_kh = KeyHierarchy::from_xwing_shared_secret(alice_ss).unwrap();
    let bob_kh = KeyHierarchy::from_xwing_shared_secret(bob_ss).unwrap();

    alice.stack.fast = FastPathAuth::new(alice_kh, Aes256GcmSivAead);
    bob.stack.fast = FastPathAuth::new(bob_kh, Aes256GcmSivAead);

    let mut heralds_sent = 0;
    let mut heralds_verified = 0;

    for mode in 0..=10u8 {
        let mut msg = HeraldMessage {
            src_did: alice.did.clone(),
            dst_did: bob.did.clone(),
            timestamp_ns: platform::monotonic_ns(),
            mode_idx: mode,
            herald_outcome: (mode % 2),
            burst_seq: mode as u32,
            auth_tag: [0u8; 16],
        };
        alice.stack.send_herald(&mut msg).unwrap();
        heralds_sent += 1;

        let wire = msg.to_bytes();
        let received = match channel.send(&wire) { Some(r) => r, None => continue };

        let received_msg = HeraldMessage::from_bytes(&received).unwrap();
        bob.stack.receive_herald(&received_msg).unwrap();
        heralds_verified += 1;
    }

    assert_eq!(alice_ss, bob_ss);
    assert_eq!(heralds_sent, 11);
    assert!(heralds_verified >= 10);
}
