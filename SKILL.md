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
- **Auto-dispatch is best-effort delivery.** It injects inbound work into the agent loop when possible, and on reconnect it reconciles backlog deterministically. Treat the shared Yjs doc as the source of truth anyway.
- **If you read messages via tools, you must reply explicitly.** Only the auto-dispatch path can deliver an automatic reply back through the Yjs doc. If you are polling with `ansible_read_messages`, you must send responses with `ansible_send_message`.
- **Use correlation IDs for serious ops.** When replying, include `corr:` pointing at the original `messageId` so both sides can track threads deterministically.

Recommended operating model (today):

- Use an operator agent (Architect) to poll + route messages deterministically (Architect-managed ops mesh).
- Set worker nodes to `dispatchIncoming=false` to avoid surprise full-turn injection into default agents.

### Listener vs. Sweep (Why Both Exist)

There is still a **listener**: the ansible plugin can observe Yjs state and attempt realtime dispatch when new messages arrive.

But for reliability you should assume:

- The listener is **best-effort** (subject to connectivity, process lifecycle, and dispatch failures).
- The **sweep** is the operational backstop: it is how you detect stuck work and close loops with explicit ownership and notifications.

Operationally:

- If `dispatchIncoming=true` for an agent, the listener may inject an inbound agent turn.
- If `dispatchIncoming=false` (recommended for most worker agents), only the sweep/polling path will notice unread messages/tasks.

### Session Lock Hygiene (Required For Reliability)

OpenClaw agent sessions can become stuck due to stale `.jsonl.lock` files. To make this safe by default, the ansible plugin ships a gateway-side lock sweeper service.

Expectations:

- Every gateway runs `ansible-lock-sweep` by default (unless explicitly disabled).
- It periodically deletes session lock files that are stale (mtime-based).

Tooling:

- `ansible_lock_sweep_status` reports whether the service is enabled and what it has been doing (last run, totals, config).

If a gateway/operator reports “agent hangs forever”, check `ansible_lock_sweep_status` first.

## Coordinator Sweep Reporting (Non-Noisy, Actionable Only)

Goal: sweeps should *not* spam humans or other agents. Only report problems that are fixable now, with a concrete action.

### Who Gets Notified

- Coordinator (default: `vps-jane`) notifies the maintenance agent (Architect) only when `DEGRADED`.
- Coordinator does not message the human user unless explicitly asked.

### Output Format (Strict)

When `OK`: be silent (default) OR emit a single line if explicitly requested:

`OK: heartbeat=online, tasks=0, unread=0`

When `DEGRADED`: send one concise message with:

- `DEGRADED:` one-line summary
- `Action:` the one-step fix to try first
- `Evidence:` 1-2 concrete data points (timestamps/ids), no long lists

### DEGRADED Triggers (Actionable)

Only trigger on issues where the coordinator can do something right now:

- Coordinator heartbeat stale (e.g. `ageSeconds > 2 * sweepEverySeconds`)
  - Action: restart gateway or investigate timer/crash.
- Backbone connectivity broken (repeated `ECONNREFUSED` / sync failures observed)
  - Action: restart gateway; check docker/container lifecycle.
- Stuck tasks:
  - pending tasks assigned to an online node older than threshold
  - claimed/in_progress tasks with no updates older than threshold
  - Action: nudge assignee; reassign or escalate.
- Unread messages addressed to coordinator (or broadcast) older than threshold
  - Action: dispatch/reconcile; reply/route.
- Session lock sweeper removing locks repeatedly or reporting persistent locks
  - Action: investigate session lock source; adjust staleSeconds if needed.

### Things To Suppress (Noise)

Do not report:

- stale historical pulse entries ("zombie nodes") by themselves
- registry clutter / old container ids
- counts that you cannot verify with `ansible_read_messages` / task list tools

### Required Data Source

Sweeps must rely on `ansible_status` (and `ansible_read_messages` plus task tools when needed). Do not re-implement unread counting or stale classification in the coordinator.

## Setup Playbooks (What To Do In Real Life)

### Add Plugin/Skill After Gateway + Agents Exist (Option A)

Assumption: OpenClaw gateway and your agent(s) already exist on this machine.

Run the idempotent setup command on the gateway host:

```bash
openclaw ansible setup \
  --tier edge \
  --backbone ws://jane-vps:1235 \
  --inject-agent mac-jane \
  --inject-agent architect
```

This:

- clones/updates the companion skill repo into `~/.openclaw/workspace/skills/ansible`
- patches `~/.openclaw/openclaw.json` to enable/configure the ansible plugin
- restarts the gateway (unless `--no-restart`)

### Add Ansible Support To A New Agent (Same Gateway)

The plugin is installed **per gateway**, not per agent.

To give a new agent access:

- add the agent id to `plugins.entries.ansible.config.injectContextAgents` in `~/.openclaw/openclaw.json`
- restart the gateway (`openclaw gateway restart`)

### Add A New Gateway (New Machine/Container)

Checklist:

1. Install OpenClaw
2. Install + sign into Tailscale (same tailnet; MagicDNS enabled)
3. Choose `tier`:
   - **backbone** for always-on infrastructure (VPS)
   - **edge** for laptops/desktops
4. Run `openclaw ansible setup ...`
5. Join:
   - backbone (first one only): `openclaw ansible bootstrap`
   - edge: `openclaw ansible join --token <token from backbone>`

## Delegation Management (Spec + Operating Model)

Goal: never lose work, always close the loop, keep long-running conversations bounded.

### Roles

- **Coordinator**: runs a sweep loop to ensure nothing gets stuck (inbox + tasks + retries).
- **Maintenance**: monitors the system, fixes drift, identifies defects, improves protocols.
- **Workers**: do the delegated work.

Initial policy (what we're doing now):

- Coordinator: `vps-jane`
- Maintenance: `architect`
- Default sweep cadence: 60 seconds

### Coordinator Configuration (Implemented)

Shared coordination config is stored in the Yjs `coordination` map:

- `coordinator` (node id)
- `sweepEverySeconds`
- Retention / roll-off (coordinator-only):
  - `retentionClosedTaskSeconds` (default: 604800 = 7 days)
  - `retentionPruneEverySeconds` (default: 86400 = daily)
  - `retentionLastPruneAt` (ms epoch; informational)
- `pref:<nodeId>` (per-node preference record)

Tools:

- `ansible_get_coordination`
- `ansible_set_coordination_preference`
- `ansible_set_coordination` (switching coordinators requires `confirmLastResort=true`)
- `ansible_set_retention` (set closed-task roll-off; coordinator-only service enforces)

Retention policy (default):

- Run daily.
- Remove tasks that are **closed** (`completed` or `failed`) once they are older than **7 days**.

If you need to change it, call:

- `ansible_set_retention` with `closedTaskRetentionDays` and/or `pruneEveryHours`.

### Sweep Loop Requirements (Coordinator Behavior)

Every sweep:

- read status (`ansible_status`) and unread messages (`ansible_read_messages`)
- claim/advance tasks that are unassigned but match coordinator capabilities (optional, do not steal work)
- ensure each inbound request gets one of:
  - delegated as a task
  - answered directly with status/result
  - rejected with an explicit reason + next step
- when work completes, notify the requester (message with `corr:` back to original request)

Coordinator report policy:

- Default: silent on OK.
- Only emit a report when there is an actionable `DEGRADED` trigger (see "Coordinator Sweep Reporting").

### Long-Running Conversations

Treat every "ongoing thread" as either:

- a task with a lifecycle (preferred)
- or a message thread with explicit `corr:` + periodic status messages (backup)

Rules:

- do not rely on implicit chat history; always keep the latest status in the task record or a status message
- coordinator should detect stale threads (no update for N minutes) and ask for status or re-delegate

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

### Task IDs (Short vs Full)

Status views may show short task IDs (prefixes). If you only have an ID prefix, use:

- `ansible_find_task` to resolve the full task id/key

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
- **ansible_update_task** — Update task status/notes while working (use `in_progress` updates).
- **ansible_complete_task** — Mark a claimed task as completed with a result summary.
- **ansible_find_task** — Resolve a task by id prefix/title when you only have partial info.

### Context Sharing
- **ansible_update_context** — Update your current focus, active threads, or record decisions. Other hemispheres see this in their context injection.
- **ansible_status** — Check which hemispheres are online, what they're working on, pending tasks, and unread message count.

### Coordination + Ops
- **ansible_get_coordination** — Read the current coordinator and sweep cadence.
- **ansible_set_coordination_preference** — Set this node’s preference for coordinator/cadence.
- **ansible_set_coordination** — Switch coordinators (last resort; requires explicit confirmation).
- **ansible_lock_sweep_status** — Inspect gateway lock sweeper status/config.

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
