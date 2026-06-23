#!/usr/bin/env bats
# Tests for setup.sh
# Run with: bats tests/setup.bats
# Install bats: brew install bats-core

setup() {
  # Isolated temp home so tests never touch the real ~/.claude.json
  ORIG_HOME="$HOME"
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  CLAUDE_JSON="$TEST_HOME/.claude.json"
  CONFIG_FILE="$TEST_HOME/.fidi-feedback/config.json"

  # Pre-fill identity prompts via stdin (email, user id — company is hardcoded)
  IDENTITY_INPUT=$'test@acme.com\nU0TEST123\n'
}

teardown() {
  rm -rf "$TEST_HOME"
  export HOME="$ORIG_HOME"
}

# ── helper: run setup.sh non-interactively ────────────────────────────────────
run_setup() {
  echo "$IDENTITY_INPUT" | run bash "$BATS_TEST_DIRNAME/../setup.sh"
}

# ─────────────────────────────────────────────────────────────────────────────

@test "fails clearly when jq is not installed" {
  PATH_WITHOUT_JQ="$(echo "$PATH" | tr ':' '\n' | grep -v '/usr/local/bin\|/opt/homebrew/bin' | tr '\n' ':')"
  run bash -c "PATH='$PATH_WITHOUT_JQ:/nonexistent' bash '$BATS_TEST_DIRNAME/../setup.sh'" <<< "$IDENTITY_INPUT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"jq"* ]]
}

@test "creates ~/.claude.json when absent (new install)" {
  [ ! -f "$CLAUDE_JSON" ]  # precondition: file does not exist
  run_setup
  [ -f "$CLAUDE_JSON" ]
}

@test "backup creates .bak file" {
  echo '{"mcpServers":{}}' > "$CLAUDE_JSON"
  run_setup
  [ -f "${CLAUDE_JSON}.bak" ]
}

@test "backup content matches original" {
  ORIGINAL='{"mcpServers":{"existing":{"command":"echo"}}}'
  echo "$ORIGINAL" > "$CLAUDE_JSON"
  run_setup
  [ "$(cat "${CLAUDE_JSON}.bak")" = "$ORIGINAL" ]
}

@test "adds Granola MCP when absent" {
  echo '{}' > "$CLAUDE_JSON"
  run_setup
  jq -e '.mcpServers.granola' "$CLAUDE_JSON"
}

@test "idempotent: second run does not duplicate Granola entry" {
  echo '{}' > "$CLAUDE_JSON"
  echo "$IDENTITY_INPUT" | bash "$BATS_TEST_DIRNAME/../setup.sh"
  echo "$IDENTITY_INPUT" | bash "$BATS_TEST_DIRNAME/../setup.sh"
  COUNT=$(jq '[.mcpServers | to_entries[] | select(.key == "granola")] | length' "$CLAUDE_JSON")
  [ "$COUNT" -eq 1 ]
}

@test "idempotent: second run does not increase total mcpServers count" {
  echo '{}' > "$CLAUDE_JSON"
  echo "$IDENTITY_INPUT" | bash "$BATS_TEST_DIRNAME/../setup.sh"
  FIRST_COUNT=$(jq '.mcpServers | length' "$CLAUDE_JSON")
  echo "$IDENTITY_INPUT" | bash "$BATS_TEST_DIRNAME/../setup.sh"
  SECOND_COUNT=$(jq '.mcpServers | length' "$CLAUDE_JSON")
  [ "$SECOND_COUNT" -eq "$FIRST_COUNT" ]
}

@test "preserves existing mcpServers entries" {
  echo '{"mcpServers":{"my-other-mcp":{"command":"echo"}}}' > "$CLAUDE_JSON"
  run_setup
  jq -e '.mcpServers["my-other-mcp"]' "$CLAUDE_JSON"
}

@test "saves config to ~/.fidi-feedback/config.json" {
  echo '{}' > "$CLAUDE_JSON"
  run_setup
  [ -f "$CONFIG_FILE" ]
}

@test "config contains expected fields" {
  echo '{}' > "$CLAUDE_JSON"
  run_setup
  jq -e '.slack_email'   "$CONFIG_FILE"
  jq -e '.slack_user_id' "$CONFIG_FILE"
  jq -e '.company_name'  "$CONFIG_FILE"
}

@test "config values match provided input" {
  echo '{}' > "$CLAUDE_JSON"
  run_setup
  EMAIL=$(jq -r '.slack_email' "$CONFIG_FILE")
  USER_ID=$(jq -r '.slack_user_id' "$CONFIG_FILE")
  COMPANY=$(jq -r '.company_name' "$CONFIG_FILE")
  [ "$EMAIL"   = "test@acme.com" ]
  [ "$USER_ID" = "U0TEST123" ]
  [ "$COMPANY" = "fidi" ]
}

@test "second run preserves config when user presses enter (keeps defaults)" {
  echo '{}' > "$CLAUDE_JSON"
  echo "$IDENTITY_INPUT" | bash "$BATS_TEST_DIRNAME/../setup.sh"
  # Second run: press Enter for all prompts (keep existing values)
  printf '\n\n' | bash "$BATS_TEST_DIRNAME/../setup.sh"
  EMAIL=$(jq -r '.slack_email' "$CONFIG_FILE")
  [ "$EMAIL" = "test@acme.com" ]
}

@test "output is non-zero on missing jq" {
  run bash -c "PATH=/nonexistent bash '$BATS_TEST_DIRNAME/../setup.sh'" <<< ""
  [ "$status" -ne 0 ]
}
