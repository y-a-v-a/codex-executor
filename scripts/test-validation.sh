#!/bin/bash
set -uo pipefail

# Test harness for validate-codex-command.sh
# Usage: ./scripts/test-validation.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate-codex-command.sh"
PASS=0
FAIL=0

# Ensure clean environment for tests
unset CODEX_ALLOW_DANGER_MODE 2>/dev/null || true
unset CODEX_ALLOW_BYPASS 2>/dev/null || true

# Create a mock codex binary so the "is codex installed?" check passes
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/codex" << 'MOCK'
#!/bin/bash
exit 0
MOCK
chmod +x "$MOCK_DIR/codex"
export PATH="$MOCK_DIR:$PATH"
trap 'rm -rf "$MOCK_DIR"' EXIT

test_case() {
  local desc="$1" input="$2" expected_exit="$3"
  local actual_exit=0
  echo "$input" | "$VALIDATE" 2>/dev/null || actual_exit=$?
  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (expected exit $expected_exit, got $actual_exit)"
    ((FAIL++))
  fi
}

echo "=== Passthrough (non-codex commands) ==="

test_case "allow plain ls" \
  '{"tool_input":{"command":"ls -la"}}' 0

test_case "allow git status" \
  '{"tool_input":{"command":"git status"}}' 0

test_case "allow npm install" \
  '{"tool_input":{"command":"npm install express"}}' 0

test_case "allow empty command" \
  '{"tool_input":{"command":""}}' 0

test_case "allow missing command field" \
  '{"tool_input":{}}' 0

echo ""
echo "=== Valid codex commands ==="

test_case "allow basic codex exec" \
  '{"tool_input":{"command":"codex exec --full-auto \"hello\""}}' 0

test_case "allow codex exec with output capture" \
  '{"tool_input":{"command":"codex exec --full-auto --output-last-message /tmp/out.md \"task\""}}' 0

test_case "allow codex exec with --cd" \
  '{"tool_input":{"command":"codex exec --full-auto --cd ./src \"refactor\""}}' 0

test_case "allow codex exec with --search" \
  '{"tool_input":{"command":"codex exec --full-auto --search \"lookup best practices\""}}' 0

echo ""
echo "=== Blocked: danger-full-access ==="

test_case "block --sandbox danger-full-access (space)" \
  '{"tool_input":{"command":"codex exec --sandbox danger-full-access \"x\""}}' 2

test_case "block --sandbox=danger-full-access (equals)" \
  '{"tool_input":{"command":"codex exec --sandbox=danger-full-access \"x\""}}' 2

echo ""
echo "=== Blocked: bypass flag ==="

test_case "block --dangerously-bypass-approvals-and-sandbox" \
  '{"tool_input":{"command":"codex exec --dangerously-bypass-approvals-and-sandbox \"x\""}}' 2

echo ""
echo "=== Environment variable overrides ==="

CODEX_ALLOW_DANGER_MODE=1 test_case "allow danger-full-access with env var" \
  '{"tool_input":{"command":"codex exec --sandbox danger-full-access \"x\""}}' 0

CODEX_ALLOW_BYPASS=1 test_case "allow bypass with env var" \
  '{"tool_input":{"command":"codex exec --dangerously-bypass-approvals-and-sandbox \"x\""}}' 0

echo ""
echo "=== Results ==="
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
