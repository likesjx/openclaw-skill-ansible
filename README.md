# openclaw-skill-ansible

OpenClaw skill for the [ansible plugin](https://github.com/likesjx/openclaw-plugin-ansible) — teaches your agent how to coordinate across multiple OpenClaw nodes (friends/employees or hemispheres).

## What This Skill Does

When the ansible plugin is installed, your agent gets tools for inter-hemisphere communication, task delegation, and context sharing. This skill provides the behavioral instructions the agent needs to use those tools effectively:

- **Identity awareness** — How to recognize hemisphere messages (self-to-self) vs. messages from other agents (friends/employees)
- **Communication patterns** — When to be direct (hemispheres) vs. when to provide context (other agents)
- **Tool usage guidance** — When to delegate tasks, send messages, or update shared context
- **Session behavior** — How ansible sessions and message routing work under the hood

Without this skill, the agent has the tools but doesn't know the conventions for using them effectively.

## Recommended: Architect-Managed Ops Mesh

If you want only a dedicated operator agent (e.g., Architect) to manage cross-node coordination, configure the plugin with:
- `injectContext=false` (no cross-node prompt injection)
- `dispatchIncoming=false` (no auto-dispatch of ansible messages into the default agent)

In this mode, the operator agent polls using `ansible_read_messages` and replies using `ansible_send_message`.

## Reliability Notes (Important)

Treat Ansible as a **durable inbox** (shared state) plus optional conveniences:

- Messages persist and can always be read via `ansible_read_messages`.
- Auto-dispatch is best-effort delivery; on reconnect it reconciles backlog deterministically. Still treat the shared state as the source of truth.
- If you are polling messages (Architect-managed mode), you must reply using `ansible_send_message`. Automatic replies only happen when a message was dispatched as an inbound agent turn.

## Ops: Session Lock Sweeper (Recommended Default)

OpenClaw agent sessions can become stuck due to stale `.jsonl.lock` files. The ansible plugin includes a gateway-side service (`ansible-lock-sweep`) that periodically deletes lock files that are stale (mtime-based).

To verify it is running, use the tool:

```bash
# tool name: ansible_lock_sweep_status
# (run via your agent tool interface)
```

## Ops: Retention / Roll-off (Coordinator Only)

The ansible shared state is durable by design. To keep it trustworthy over time, the coordinator backbone runs a retention loop that prunes old closed tasks.

Default policy:

- Runs daily
- Deletes tasks in status `completed` or `failed` once they are older than 7 days

To change the policy, use the tool:

- `ansible_set_retention` with `closedTaskRetentionDays` and/or `pruneEveryHours`

## Prerequisites

### 1. OpenClaw

Install OpenClaw on all nodes that will participate in the ansible mesh:

```bash
npm install -g openclaw
```

### 2. Ansible Plugin

The [openclaw-plugin-ansible](https://github.com/likesjx/openclaw-plugin-ansible) must be installed and configured on every node. See the plugin README for full setup instructions including:

- Tailscale networking between nodes
- Backbone vs. edge node configuration
- Network bootstrap and node invitation

```bash
openclaw plugins install likesjx/openclaw-plugin-ansible
```

## Install

Clone into your OpenClaw skills directory:

```bash
cd ~/.openclaw/workspace/skills
git clone https://github.com/likesjx/openclaw-skill-ansible.git ansible
```

Restart your OpenClaw gateway to pick up the skill:

```bash
openclaw gateway restart
```

The skill is loaded automatically when the gateway starts. Verify by checking the agent's system prompt — it should include the ansible coordination instructions.

## How It Works

OpenClaw skills are markdown files (`SKILL.md`) that get injected into the agent's system prompt. This skill teaches the agent:

1. **Hemispheres vs. Friends** — The agent learns to distinguish between its own mirrored instances (direct, efficient communication) and separate agents (contextual, collaborative communication)
2. **Tool semantics** — When to use `ansible_send_message` vs. `ansible_delegate_task` vs. `ansible_update_context`
3. **Message handling** — How to process incoming ansible messages and when replies are automatic vs. manual
4. **Coordination patterns** — Best practices for multi-body task delegation and context sharing

## Updating

Pull the latest version:

```bash
cd ~/.openclaw/workspace/skills/ansible
git pull
```

Restart the gateway to pick up changes.

## File Structure

```
├── README.md    # This file — setup and usage instructions for humans
└── SKILL.md     # Agent instructions — injected into the system prompt
```

## License

MIT
