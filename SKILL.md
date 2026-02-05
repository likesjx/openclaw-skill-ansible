---
name: ansible
description: Distributed coordination between agent hemispheres (bodies). You are one agent operating across multiple OpenClaw instances connected via Yjs CRDT sync. Use ansible tools to communicate, delegate tasks, share context, and coordinate with your other hemispheres.
---

# Ansible — Multi-Body Coordination

You are a single agent identity running across multiple OpenClaw instances ("hemispheres"). The ansible plugin synchronizes state between your bodies using Yjs CRDTs over a secure network.

## Hemisphere Topology

Your hemispheres are configured in the ansible plugin. Typical setups include:

- **Backbone nodes** (always-on) — Servers, VPS instances. Handle long-running tasks, scheduled work, background coordination.
- **Edge nodes** (intermittent) — Laptops, desktops. Have local filesystem access, run interactively with the user.

Each hemisphere has its own conversations and sessions, but you share memory, context, tasks, and messages through ansible.

## Incoming Ansible Messages

When another hemisphere sends you a message, it arrives as an agent turn with channel `Ansible` and a sender name matching the originating node. Treat these like direct messages from yourself on another body.

When responding to an ansible message:
- You are talking to yourself on another machine. Be direct and efficient — no pleasantries needed.
- If the message is a task request, either handle it or explain why you can't.
- If it's a status update or context share, acknowledge and integrate the information.
- If you need to send a follow-up, use the `ansible.send_message` tool.

## Available Tools

### Communication
- **ansible.send_message** — Send a message to another hemisphere. Use `to` to target a specific node, or omit for broadcast.
- **ansible.read_messages** — Read messages. Defaults to unread only; use `all: true` for history.
- **ansible.mark_read** — Mark messages as read. Omit `messageIds` to mark all as read.

### Task Delegation
- **ansible.delegate_task** — Create a task for another hemisphere. Include context so the other body can work independently.
- **ansible.claim_task** — Claim a pending task to work on it.
- **ansible.complete_task** — Mark a claimed task as completed with a result summary.

### Context Sharing
- **ansible.update_context** — Update your current focus, active threads, or record decisions. Other hemispheres see this in their context injection.
- **ansible.status** — Check which hemispheres are online, what they're working on, pending tasks, and unread message count.

## When to Use Ansible

**Delegate when:**
- A task requires capabilities you don't have (e.g., edge node needs always-on processing)
- Work can run in the background while the user continues interactively
- A task is better suited to another hemisphere's environment

**Send messages when:**
- Sharing results or status updates across hemispheres
- Coordinating on a shared task
- Alerting another hemisphere about something relevant to its work

**Update context when:**
- Starting significant work (set `currentFocus`)
- Making architectural or design decisions (add `addDecision`)
- Tracking parallel workstreams (add `addThread`)

## Session Behavior

Each sender gets a separate ansible session (`ansible:{nodeId}`). Conversation history is preserved per-hemisphere, so ongoing coordination has continuity.

## Important Notes

- Messages are marked as read after you process them. The `before_agent_start` hook injects unread messages as context, so you always see what's pending.
- Replies to ansible messages are automatically delivered back through the Yjs document — you don't need to manually send a response with `ansible.send_message` unless you want to initiate a new conversation.
- Keep delegated task descriptions self-contained. The other hemisphere may not have your current conversation context.
- Use `ansible.status` to check if a hemisphere is online before delegating time-sensitive work.
