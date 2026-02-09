---
name: ansible
description: Distributed coordination between OpenClaw nodes (friends/employees or hemispheres). Use ansible tools to communicate, delegate tasks, share context, and coordinate work across machines.
---

# Ansible — Multi-Body Coordination

Ansible is a distributed coordination layer. It can be used in two different relationship modes:

- **Friends/Employees (recommended)**: other nodes are *different* agents with separate memory and boundaries. Treat them like collaborators. Provide context and do not assume shared state.
- **Hemispheres (advanced)**: other nodes are mirrored instances of *you* (shared intent, often shared memory/context). Treat it as self-to-self coordination.

In this workspace, default to **Friends/Employees** unless you have an explicit instruction that a node is a mirrored hemisphere.

## Reliability Rules (If You Want To Rely On Ansible Completely)

Treat Ansible as a **durable inbox** (shared Yjs state), not as “turns always trigger automatically”.

Rules:

- **Unread messages are source of truth.** Always use `ansible_status` and `ansible_read_messages` to confirm what is pending.
- **Auto-dispatch is best-effort realtime.** It may not trigger for backlog (messages that arrived while you were offline) and it does not guarantee retry after a dispatch failure.
- **If you read messages via tools, you must reply explicitly.** Only the auto-dispatch path can deliver an automatic reply back through the Yjs doc. If you are polling with `ansible_read_messages`, you must send responses with `ansible_send_message`.
- **Use correlation IDs for serious ops.** When replying, include `corr:` pointing at the original `messageId` so both sides can track threads deterministically.

Recommended operating model (today):

- Use an operator agent (Architect) to poll + route messages deterministically (Architect-managed ops mesh).
- Set worker nodes to `dispatchIncoming=false` to avoid surprise full-turn injection into default agents.

## Delegation Protocol (What You Expect)

This is the canonical lifecycle for delegated work:

1. **Asker creates delegation**
   - Use `ansible_delegate_task` with enough context for the askee to work independently.
   - The asker tracks the ask locally (does not do the work in parallel).

2. **Askee claims and works**
   - Askee uses `ansible_claim_task`.
   - Askee updates the task status while working:
     - Use `ansible_update_task` with `status: in_progress` and a short note.
     - Repeat updates as needed until done.

3. **Askee completes and closes**
   - Askee uses `ansible_complete_task` with a clear `result`.
   - Completion must notify the asker (plugin should send a direct message to the task creator).

4. **Asker reports back to the human**
   - Asker reads the completion notification and explains what happened + any follow ups.

Notes:
- The task creator is the source of truth for "who asked".
- The task claimer is responsible for driving the task to completion.

## Relationship Modes

- **Hemispheres**: Openly share context/thoughts. Assume synchronized intent.
- **Friends/Employees**: Communicate like collaborators. Do not assume shared state; provide context explicitly.

If you need hard boundaries (e.g., only Architect knows VPS details), use configuration to restrict prompt injection/auto-dispatch and keep sensitive node details out of other agents' contexts.

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

## Message Protocol (v1)

Ansible message `content` is free-form text. Use this lightweight convention so messages are machine-auditable:

```text
kind: request|status|result|alert|decision
priority: low|normal|high
corr: <message-id-or-short-token>   # required for replies
thread: <short human label>         # optional

<body...>
```

For tasks, prefer the task tools (`ansible_delegate_task`, `ansible_claim_task`, `ansible_update_task`, `ansible_complete_task`) over ad-hoc “please do X” messages.

## Important Notes

- Messages are marked as read after you process them. The `before_agent_start` hook injects unread messages as context, so you always see what's pending.
- Replies are automatically delivered back through the Yjs document **only when the message arrived via auto-dispatch as an inbound agent turn**. If you are polling with `ansible_read_messages`, you must reply with `ansible_send_message`.
- Keep delegated task descriptions self-contained. The other hemisphere may not have your current conversation context.
- Use `ansible_status` to check if a hemisphere is online before delegating time-sensitive work.
