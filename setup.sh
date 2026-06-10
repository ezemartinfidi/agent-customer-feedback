#!/usr/bin/env bash
# setup.sh — Configures Claude Code for the agent-customer-feedback skill.
# Safe to run multiple times (idempotent).
set -euo pipefail

CLAUDE_JSON="$HOME/.claude.json"
CONFIG_DIR="$HOME/.fidi-feedback"
CONFIG_FILE="$CONFIG_DIR/config.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }
err()  { echo -e "  ${RED}✗${NC} $*"; }

# ── 1. prerequisite: jq ───────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo ""
  err "jq is required but not installed."
  echo "    Install it with: brew install jq"
  echo ""
  exit 1
fi

echo ""
echo "agent-customer-feedback setup"
echo "════════════════════════════"

# ── 2. create ~/.claude.json if absent ────────────────────────────────────────
if [ ! -f "$CLAUDE_JSON" ]; then
  echo '{}' > "$CLAUDE_JSON"
  ok "Created $CLAUDE_JSON (new Claude Code installation detected)"
fi

# ── 3. backup ─────────────────────────────────────────────────────────────────
cp "$CLAUDE_JSON" "${CLAUDE_JSON}.bak"
ok "Backed up $CLAUDE_JSON → ${CLAUDE_JSON}.bak"

# ── 4. ensure mcpServers key exists ───────────────────────────────────────────
if ! jq -e '.mcpServers' "$CLAUDE_JSON" > /dev/null 2>&1; then
  PATCHED=$(jq '. + {"mcpServers": {}}' "$CLAUDE_JSON")
  echo "$PATCHED" > "$CLAUDE_JSON"
fi

# ── 5. check MCP integrations ────────────────────────────────────────────────
# All integrations are configured through Claude Code or Claude.ai and synced
# automatically. This step checks which ones are present and gives instructions
# for any that are missing.
echo ""
echo "Checking MCP integrations..."

INTEGRATIONS_OK=true
GRANOLA_KEY="granola"
if jq -e --arg k "$GRANOLA_KEY" '.mcpServers | has($k)' "$CLAUDE_JSON" > /dev/null 2>&1; then
  ok "Granola MCP already configured"
else
  warn "Granola MCP not found in $CLAUDE_JSON"
  echo "       → Enable it via Claude Code: Settings → Integrations → Granola"
  echo "       → Requires Granola desktop app: https://granola.ai"
  INTEGRATIONS_OK=false
fi

# ── 6. check claude.ai integrations ──────────────────────────────────────────
# Slack, Gmail, Google Drive, and Notion are configured through Claude.ai's
# web interface and synced automatically to Claude Code. This step only
# checks whether they are already present.
echo ""
echo "Checking Claude.ai integrations..."

check_integration() {
  local label="$1"
  local key="$2"
  local url="$3"
  if jq -e --arg k "$key" '.mcpServers | has($k)' "$CLAUDE_JSON" > /dev/null 2>&1; then
    ok "$label"
  else
    err "$label — not found in $CLAUDE_JSON"
    echo "       → Enable it at: $url"
    INTEGRATIONS_OK=false
  fi
}

check_integration "Slack"        "plugin:slack:slack"       "https://claude.ai/settings?tab=integrations"
check_integration "Gmail"        "claude_ai_Gmail"          "https://claude.ai/settings?tab=integrations"
check_integration "Google Drive" "claude_ai_Google_Drive"   "https://claude.ai/settings?tab=integrations"
check_integration "Notion"       "claude_ai_Notion"         "https://claude.ai/settings?tab=integrations"

if [ "$INTEGRATIONS_OK" = false ]; then
  echo ""
  warn "Some integrations are missing. To enable them:"
  echo "    1. Open Claude.ai → Settings → Integrations"
  echo "    2. Connect each missing service"
  echo "    3. Re-run this script to verify"
  echo ""
  warn "You can continue setup now and add integrations later."
fi

# ── 7. save user identity to ~/.fidi-feedback/config.json ────────────────────
echo ""
echo "Setting up your identity..."

mkdir -p "$CONFIG_DIR"

EXISTING_EMAIL=""
EXISTING_USER_ID=""
EXISTING_COMPANY=""
if [ -f "$CONFIG_FILE" ]; then
  EXISTING_EMAIL=$(jq -r '.slack_email // empty' "$CONFIG_FILE" 2>/dev/null || true)
  EXISTING_USER_ID=$(jq -r '.slack_user_id // empty' "$CONFIG_FILE" 2>/dev/null || true)
  EXISTING_COMPANY=$(jq -r '.company_name // empty' "$CONFIG_FILE" 2>/dev/null || true)
fi

# company_name
if [ -n "$EXISTING_COMPANY" ]; then
  read -r -p "  Company name [$EXISTING_COMPANY]: " COMPANY_INPUT
  COMPANY_NAME="${COMPANY_INPUT:-$EXISTING_COMPANY}"
else
  read -r -p "  Company name (used to find Slack Connect channels, e.g. 'acme'): " COMPANY_NAME
fi

# slack_email
if [ -n "$EXISTING_EMAIL" ]; then
  read -r -p "  Your Slack email [$EXISTING_EMAIL]: " EMAIL_INPUT
  SLACK_EMAIL="${EMAIL_INPUT:-$EXISTING_EMAIL}"
else
  read -r -p "  Your Slack email: " SLACK_EMAIL
fi

# slack_user_id
if [ -n "$EXISTING_USER_ID" ]; then
  read -r -p "  Your Slack user ID [$EXISTING_USER_ID]: " UID_INPUT
  SLACK_USER_ID="${UID_INPUT:-$EXISTING_USER_ID}"
else
  echo ""
  echo "  Find your Slack user ID:"
  echo "  Click your profile photo → View profile → More (•••) → Copy member ID"
  echo ""
  read -r -p "  Your Slack user ID (starts with U): " SLACK_USER_ID
fi

jq -n \
  --arg email   "$SLACK_EMAIL" \
  --arg user_id "$SLACK_USER_ID" \
  --arg company "$COMPANY_NAME" \
  '{"slack_email": $email, "slack_user_id": $user_id, "company_name": $company}' \
  > "$CONFIG_FILE"

ok "Config saved to $CONFIG_FILE"

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════"
if [ "$INTEGRATIONS_OK" = true ]; then
  echo -e "${GREEN}Setup complete!${NC}"
  echo ""
  echo "Run /feedback-clientes in Claude Code to start."
else
  echo -e "${YELLOW}Setup complete (with missing integrations).${NC}"
  echo ""
  echo "Add the missing integrations in Claude.ai, then re-run:"
  echo "  bash setup.sh"
fi
echo ""
