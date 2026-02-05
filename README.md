# openclaw-skill-ansible

OpenClaw skill for the [ansible plugin](https://github.com/likesjx/openclaw-plugin-ansible) — teaches your agent how to coordinate across multiple OpenClaw instances ("hemispheres").

## What it does

When the ansible plugin is installed, your agent gets tools for inter-hemisphere communication, task delegation, and context sharing. This skill provides the instructions the agent needs to use those tools effectively:

- How to handle incoming ansible messages (treat them as self-to-self communication)
- When to delegate tasks vs. send messages vs. update shared context
- How ansible sessions and message routing work
- Best practices for multi-body coordination

## Install

Clone into your OpenClaw skills directory:

```bash
cd ~/.openclaw/workspace/skills
git clone https://github.com/likesjx/openclaw-skill-ansible.git ansible
```

Restart your OpenClaw gateway to pick up the skill.

## Prerequisites

Requires the [openclaw-plugin-ansible](https://github.com/likesjx/openclaw-plugin-ansible) plugin to be installed and configured.

## License

MIT
