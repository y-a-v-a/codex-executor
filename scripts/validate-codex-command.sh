#!/bin/bash
set -euo pipefail

# Validation hook for Codex CLI commands
# Exit codes:
#   0 - Allow operation
#   2 - Block operation (stderr message returned to Claude)

# --- Dependencies ---

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for command validation but not found in PATH" >&2
  exit 2
fi

# --- Parse input ---

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  # No command found in input, allow (nothing to validate)
  exit 0
fi

# --- Non-codex commands pass through ---

if ! echo "$COMMAND" | grep -qE '\bcodex\b'; then
  exit 0
fi

# --- Codex must be installed ---

if ! command -v codex &> /dev/null; then
  echo "Blocked: 'codex' command not found in PATH" >&2
  echo "Install: npm install -g @openai/codex" >&2
  exit 2
fi

# --- Validation rules ---

# Block danger-full-access sandbox (handles both --sandbox=X and --sandbox X)
if echo "$COMMAND" | grep -qE -- '--sandbox[= ]danger-full-access'; then
  if [ -z "${CODEX_ALLOW_DANGER_MODE:-}" ]; then
    echo "Blocked: danger-full-access requires CODEX_ALLOW_DANGER_MODE=1" >&2
    exit 2
  fi
fi

# Block bypass flag
if echo "$COMMAND" | grep -q -- "--dangerously-bypass-approvals-and-sandbox"; then
  if [ -z "${CODEX_ALLOW_BYPASS:-}" ]; then
    echo "Blocked: --dangerously-bypass-approvals-and-sandbox requires CODEX_ALLOW_BYPASS=1" >&2
    exit 2
  fi
fi

# Warn about missing output capture (non-blocking)
if echo "$COMMAND" | grep -q "codex exec" && ! echo "$COMMAND" | grep -q -- "--output-last-message"; then
  echo "Warning: Consider using --output-last-message to capture results" >&2
fi

# All checks passed
exit 0
