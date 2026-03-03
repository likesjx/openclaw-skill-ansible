---
name: meshops-control-plane
description: Operate and secure mesh workflows across gateways, including plugin bootstrap, invite/join auth handshake, resilient routing, capability contract lifecycle, and delegation/execution skill-pair deployment with explicit high-risk gates.
---

# MeshOps Control Plane

This skill is a secure operations surface for gateway-level mesh management.

It is intentionally paired with `openclaw-plugin-ansible`, so the skill instructions, contracts, and actions stay aligned to the plugin's real tool surface.

## Positioning

Preferred public name:

1. MeshOps Control Plane

Why:

1. Describes actual behavior (gateway operations + control loops).
2. Avoids confusion with third-party product names.

## Actual Plugin Coverage

This skill maps to concrete capabilities from `openclaw-plugin-ansible`.
Reference: `docs/plugin-capabilities-actual-v2026-03-03.md`.

High-level coverage includes:

1. gateway invite/join and auth-gate exchange bootstrap
2. message + task transport with heartbeat reconciliation
3. capability lifecycle (publish, unpublish, list, health, evidence)
4. delegation policy distribution + ACK tracking
5. admin/backpressure/SLA governance controls

## Delegation Skill Pair Lifecycle

Capability contracts are deployed as a pair:

1. Delegation skill (requester side):
  - defines when to delegate, task envelope format, and expected ACK/completion semantics
2. Execution skill (executor side):
  - defines accept-to-close workflow, result payload contract, and error/timeout handling

Lifecycle expectations:

1. publish capability contract with both skill refs
2. distribute/install across eligible agents
3. wire routing + track lifecycle evidence
4. monitor health/SLA, then update or unpublish with rollback evidence

## Action Map

1. `preflight`
  - validate binaries/env/gates before maintenance work
2. `setup-ansible-plugin`
  - install/update plugin + run setup + verify status
3. `collect-logs`
4. `run-cmd` (high-risk, disabled by default)
5. `deploy-skill` (high-risk, disabled by default)

## Gate Model (Explicit)

Global high-risk gate:

1. `OPENCLAW_ALLOW_HIGH_RISK=1`

Per-action gates:

1. `OPENCLAW_ALLOW_RUN_CMD=1` for `run-cmd`
2. `OPENCLAW_ALLOW_DEPLOY_SKILL=1` for `deploy-skill`

Caller authorization:

1. `OPENCLAW_ALLOWED_CALLERS` (default `architect,chief-of-staff`)

Both global and per-action gates must be enabled for high-risk actions to execute.

## Required Binaries

1. `openclaw`
2. `jq`
3. `curl`
4. `tar`
5. `sha256sum` or `shasum`
6. `timeout`
7. `git`

## Required Environment Variables

1. `OPENCLAW_ALLOWED_CALLERS`
2. `OPENCLAW_ALLOW_HIGH_RISK`
3. `OPENCLAW_ALLOW_RUN_CMD`
4. `OPENCLAW_ALLOW_DEPLOY_SKILL`
5. `OPENCLAW_RUN_CMD_ALLOWLIST`
6. `OPENCLAW_ARTIFACT_ROOT`

## Deployment Safety

1. `deploy-skill` requires HTTPS + mandatory SHA-256 digest.
2. `deploy-skill` writes into `/opt/openclaw/skills`, so operator filesystem privileges are required.
3. Prefer plugin-manager installs where possible.

## run-cmd Safety

1. Disabled unless explicit gates are enabled.
2. Strict allowlist exact-match policy (`OPENCLAW_RUN_CMD_ALLOWLIST`, `;`-separated commands).
3. Intended for controlled maintenance windows only.
