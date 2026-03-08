# Contributing to Codex Skills

## Architecture

Each skill is a directory under `skills/<name>/` containing:
- `SKILL.md` — YAML frontmatter + Markdown system prompt
- Supporting scripts (e.g. `scripts/validate-codex-command.sh`)

| Skill | Path | Purpose |
|-------|------|---------|
| `/codex` | `skills/codex/SKILL.md` | Delegate coding tasks to Codex CLI |
| `/codex-review` | `skills/codex-review/SKILL.md` | Run code reviews via Codex CLI |

## Customizing Skills

Edit `skills/codex/SKILL.md` frontmatter to change behavior:

```yaml
---
allowed-tools: Bash(codex *), Read, Glob, Grep, WebFetch
context: fork      # isolated context, no conversation history
agent: Explore     # read-only agent
---
```

Add project-specific rules to the Markdown body (after the frontmatter):

```markdown
## Project Rules

- Always use TypeScript strict mode
- Run `npm test` after code generation
- Format with `npm run format` before committing
```

### Custom Validation Rules

Edit `skills/codex/scripts/validate-codex-command.sh`:

```bash
# Block a specific model
if echo "$COMMAND" | grep -q -- "--model gpt-3.5"; then
  echo "Blocked: requires gpt-4 or better" >&2
  exit 2
fi

# Block production paths
if echo "$COMMAND" | grep -q -- "--cd /production"; then
  echo "Blocked: cannot run against production" >&2
  exit 2
fi
```

## Creating New Skills

Create `skills/<name>/SKILL.md`:

```yaml
---
name: codex-analyzer
description: Analyze code quality without making changes
argument-hint: [analysis target]
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools: Bash(codex *)
---

You are a read-only code analyzer. Always use --sandbox read-only and --json.

Analyze: $ARGUMENTS
```

Then symlink: `ln -s ~/Projects/codex-executor/skills/codex-analyzer ~/.claude/skills/codex-analyzer`

## Hooks

Hooks are defined in the skill's YAML frontmatter:

```yaml
---
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: bash scripts/validate-codex-command.sh
---
```

For hooks across multiple skills, use `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash skills/codex/scripts/validate-codex-command.sh" }]
      }
    ]
  }
}
```

## Testing Changes

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('skills/codex/SKILL.md').read().split('---')[1])"

# Test validation hook
echo '{"tool_input":{"command":"codex exec test"}}' | bash skills/codex/scripts/validate-codex-command.sh
echo $?  # 0 = allow, 2 = block
```

Restart Claude Code to pick up skill changes, then invoke with `/codex ...`.

## Best Practices

- One skill, one purpose
- Use `disable-model-invocation: true` for skills with side effects or cost
- Use `context: fork` for self-contained tasks
- Use `allowed-tools` to grant only necessary tools
- Default to blocking in validation scripts; exit 2 with a clear message
- Keep validation scripts fast with minimal dependencies
