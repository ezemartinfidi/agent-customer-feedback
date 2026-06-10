# agent-customer-feedback — Claude Code context

## Project overview

This repo contains two Claude Code skills:
- `/feedback-clientes` — collects customer feedback from Slack Connect, Granola, Gmail, Notion and sends a DM summary
- `/fidi-setup` — setup wizard that runs `setup.sh` and verifies each MCP integration

Skills live in `.claude/skills/[skill-name]/SKILL.md`. They are markdown prompt files — no build step, no runtime.

## Key files

| File | Purpose |
|---|---|
| `setup.sh` | Idempotent bash installer: configures MCPs and saves `~/.fidi-feedback/config.json` |
| `.claude/skills/feedback-clientes/SKILL.md` | Main agent skill prompt |
| `.claude/skills/fidi-setup/SKILL.md` | Setup wizard skill prompt |
| `tests/setup.bats` | bats tests for setup.sh |

## Dev workflow

```bash
# Test setup.sh
brew install bats-core
bats tests/setup.bats

# Edit a skill → test it immediately in Claude Code
# /feedback-clientes 7 --max-clients 2
```

## Config file written by setup.sh

`~/.fidi-feedback/config.json` — stored outside the repo, never committed:
```json
{
  "slack_user_id": "U0XXXXXXX",
  "slack_email": "you@company.com",
  "company_name": "acme"
}
```

## MCP integrations required

| Integration | Key in ~/.claude.json | How to enable |
|---|---|---|
| Granola | `granola` | Added automatically by setup.sh |
| Slack | `plugin:slack:slack` | Claude.ai → Settings → Integrations |
| Gmail | `claude_ai_Gmail` | Claude.ai → Settings → Integrations |
| Google Drive | `claude_ai_Google_Drive` | Claude.ai → Settings → Integrations |
| Notion | `claude_ai_Notion` | Claude.ai → Settings → Integrations |
