# Testing Codex Skills

Prerequisites: install and authenticate Codex CLI — see [reference.md](./reference.md#prerequisites).

## `/codex`

```
/codex create a hello world function in Python
/codex refactor test.py to use type hints
```

Check results:
```bash
git status
git diff
```

## `/codex-review`

```
/codex-review --uncommitted
/codex-review --base main
/codex-review --commit abc123
```

## Validation Hook

```bash
# Should allow (exit 0)
echo '{"tool_input":{"command":"codex exec test"}}' | bash skills/codex/scripts/validate-codex-command.sh

# Should block (exit 2)
echo '{"tool_input":{"command":"codex exec --dangerously-bypass-approvals-and-sandbox test"}}' | bash skills/codex/scripts/validate-codex-command.sh
```

Set `CODEX_ALLOW_DANGER_MODE=1` or `CODEX_ALLOW_BYPASS=1` to permit dangerous operations.

## Troubleshooting

See [reference.md](./reference.md#troubleshooting).
