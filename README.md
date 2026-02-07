# openclaw-skill-ansible

OpenClaw skill for the [ansible plugin](https://github.com/likesjx/openclaw-plugin-ansible) — teaches your agent how to coordinate across multiple OpenClaw instances ("hemispheres").

## What This Skill Does

When the ansible plugin is installed, your agent gets tools for inter-hemisphere communication, task delegation, and context sharing. This skill provides the behavioral instructions the agent needs to use those tools effectively:

- **Identity awareness** — How to recognize hemisphere messages (self-to-self) vs. messages from other agents (friends/employees)
- **Communication patterns** — When to be direct (hemispheres) vs. when to provide context (other agents)
- **Tool usage guidance** — When to delegate tasks, send messages, or update shared context
- **Session behavior** — How ansible sessions and message routing work under the hood

Without this skill, the agent has the tools but doesn't know the conventions for using them effectively.

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
