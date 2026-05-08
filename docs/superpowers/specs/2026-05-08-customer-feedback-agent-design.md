# Customer Feedback Agent — Design Spec

**Date:** 2026-05-08  
**Status:** Approved  
**First exercise:** Monnet (all history)

---

## Overview

A Claude Code slash command (`/feedback-monnet`) that collects customer signals from three sources — Slack, Granola meeting transcripts, and Gmail — and delivers a structured analysis as a Slack DM to the product owner. Designed to validate output quality before enabling automation or ticket creation.

---

## Trigger modes

| Mode | How | Window |
|---|---|---|
| On-demand | `/feedback-monnet` slash command in Claude Code | Full history (first run) or last 7 days |
| Periodic | Weekly cron via `/schedule` skill, runs every Monday | Last 7 days |

The periodic cron is activated manually after the user validates output quality from the first run.

---

## Data sources

### 1. Slack — `#monnet-fidi`
- Read all messages from the channel (full history on first run; 7-day window on recurring runs)
- Retrieve and read any attached documents in the channel (especially the document containing Monnet's questions)
- Tool: `mcp__plugin_slack_slack__slack_read_channel`, `mcp__plugin_slack_slack__slack_search_public_and_private`

### 2. Granola — Meeting transcripts
- Query all meetings that involve Monnet contacts (full history on first run; 7-day window on recurring)
- Extract transcript content and action items from each meeting
- Tool: `mcp__granola__query_granola_meetings`, `mcp__granola__get_meeting_transcript`

### 3. Gmail — Email threads
- Search for email threads with Monnet contacts (by domain or known email addresses)
- Full history on first run; 7-day window on recurring
- Tool: `mcp__claude_ai_Gmail__search_threads`, `mcp__claude_ai_Gmail__get_thread`

---

## Analysis logic

Claude receives all raw content from the three sources and performs a single synthesis pass:

1. **Deduplicate** — same issue mentioned in Slack, a meeting, and an email counts as one item (note the frequency)
2. **Classify** into three categories:
   - 🐛 **Bugs / errores** — something broken or not working as expected
   - ✨ **Feature requests** — functionality Monnet wants that doesn't exist yet
   - ❓ **Preguntas frecuentes** — recurring questions that suggest unclear UX or missing docs
3. **Discard noise** — greetings, scheduling, off-topic messages
4. **Note frequency** — if an item appears in multiple sources or messages, mention it ("mencionado 3 veces")

---

## Output format

A single Slack DM to `@ezequiel.martin` (ezequiel.martin@gmail.com):

```
🔍 *Feedback Monnet — [período]*
_[N] fuentes · [N] señales analizadas_

*Bugs / errores reportados*
• [descripción concreta del problema]
• ...

*Feature requests*
• [descripción concreta del pedido]
• ...

*Preguntas frecuentes*
• [pregunta o tema recurrente]
• ...
```

Rules for the bullets:
- One line per item, max ~15 words
- Concrete and specific — no vague summaries
- If an item appears in multiple sources, note it: "(Slack + reunión)"
- If a category has no items, omit it entirely

---

## Implementation

A single file: `.claude/commands/feedback-monnet.md`

This file is a Claude Code custom command. When the user runs `/feedback-monnet`, Claude Code loads the prompt and executes it using the available MCP tools in the session.

The command prompt instructs Claude to:
1. Collect data from all three sources (with full-history or 7-day scope depending on context)
2. Synthesize and classify
3. Send the DM via Slack MCP

---

## Validation gate

Before activating the weekly cron or Jira integration:
- Run `/feedback-monnet` manually against full Monnet history
- User evaluates: accuracy of classification, usefulness of bullets, signal/noise ratio
- If quality is acceptable: activate cron + add Jira ticket creation to the command
- If not: refine the analysis prompt and re-run

---

## Out of scope (for now)

- Jira ticket creation (enabled after quality validation)
- Multi-client support (Monnet only in this iteration)
- Notion output
- Aggregated cross-client reports
