# meshops-control-plane

Secure mesh control-plane skill for gateway operations, capability contracts, and delegation/execution skill-pair lifecycle management.

Display name:

- MeshOps Control Plane

## What It Provides

1. preflight checks (`preflight`)
2. plugin install/setup/verification (`setup-ansible-plugin`)
3. log collection (`collect-logs`)
4. capability/delegation architecture references aligned to real plugin tools
5. explicitly gated high-risk actions (`run-cmd`, `deploy-skill`)

## Delegation Pair Contract

1. delegation skill defines requester behavior and task shaping
2. execution skill defines claim/execute/reply behavior
3. capability publish wires both refs into routing and lifecycle evidence
4. unpublish removes eligibility and preserves operator audit trail

## High-Risk Gates

1. `OPENCLAW_ALLOW_HIGH_RISK=1`
2. `OPENCLAW_ALLOW_RUN_CMD=1` for `run-cmd`
3. `OPENCLAW_ALLOW_DEPLOY_SKILL=1` for `deploy-skill`
4. caller allowlist via `OPENCLAW_ALLOWED_CALLERS`

## Capability Alignment

See `docs/plugin-capabilities-actual-v2026-03-03.md` for inventory from actual plugin code.
