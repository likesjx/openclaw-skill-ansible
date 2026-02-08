---
name: ansible
description: Distributed coordination between OpenClaw nodes (friends/employees or hemispheres). Use ansible tools to communicate, delegate tasks, share context, and coordinate work across machines.
---

# Ansible — Multi-Body Coordination

Ansible is a distributed coordination layer. It can be used in two different relationship modes:

- **Friends/Employees (recommended)**: other nodes are *different* agents with separate memory and boundaries. Treat them like collaborators. Provide context and do not assume shared state.
- **Hemispheres (advanced)**: other nodes are mirrored instances of *you* (shared intent, often shared memory/context). Treat it as self-to-self coordination.

In this workspace, default to **Friends/Employees** unless you have an explicit instruction that a node is a mirrored hemisphere.

## Architect-Managed Mesh (Hard Boundary)

If an "Architect" agent is responsible for ops, and other agents (e.g. mac-jane) must not learn about VPS details:

- Do not mention VPS node names, SSH targets, IPs, tokens, or filesystem paths outside the Architect context.
- Prefer configuring the ansible plugin with:
  - `injectContext=false` (no prompt injection)
  - `dispatchIncoming=false` (no auto-dispatch into the default agent)
- The operator should poll with `ansible_read_messages` and respond with `ansible_send_message`.

## Hemispheres vs. Friends

**Hemispheres** are mirrored instances of YOU — same identity, same memory, same purpose. When you talk to your other hemisphere, you are talking to yourself on another machine. Be direct and efficient.

**Friends or employees** are DIFFERENT agents with their own identity, memory, and purpose. If you encounter another agent that is NOT your hemisphere (different name, different goals), that's a friend or employee — communicate with them as you would with a collaborator, providing context they wouldn't already have.

How to tell the difference:
- Ansible messages from nodes in your hemisphere list → **yourself** (direct, no pleasantries)
- Messages from unknown agents or via different channels → **friend/employee** (provide context, be collaborative)

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
- If you need to send a follow-up, use the `ansible_send_message` tool.

## Available Tools

### Communication
- **ansible_send_message** — Send a message to another hemisphere. Use `to` to target a specific node, or omit for broadcast.
- **ansible_read_messages** — Read messages. Defaults to unread only; use `all: true` for history.
- **ansible_mark_read** — Mark messages as read. Omit `messageIds` to mark all as read.

### Task Delegation
- **ansible_delegate_task** — Create a task for another hemisphere. Include context so the other body can work independently.
- **ansible_claim_task** — Claim a pending task to work on it.
- **ansible_complete_task** — Mark a claimed task as completed with a result summary.

### Context Sharing
- **ansible_update_context** — Update your current focus, active threads, or record decisions. Other hemispheres see this in their context injection.
- **ansible_status** — Check which hemispheres are online, what they're working on, pending tasks, and unread message count.

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
- Replies to ansible messages are automatically delivered back through the Yjs document — you don't need to manually send a response with `ansible_send_message` unless you want to initiate a new conversation.
- Keep delegated task descriptions self-contained. The other hemisphere may not have your current conversation context.
- Use `ansible_status` to check if a hemisphere is online before delegating time-sensitive work.
