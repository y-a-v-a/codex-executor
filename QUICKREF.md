# Codex Agent Quick Reference

Complete reference for configuring and using the Codex agent.

> **Usage Examples**: For workflow examples and common patterns, see [example-usage.md](./example-usage.md)

## File Locations

| File | Purpose |
|------|---------|
| `codex-executor.md` | Main agent definition |
| `scripts/validate-codex-command.sh` | Safety validation hook |
| `README.md` | Overview and quick start |
| `example-usage.md` | Usage patterns and examples |
| `TESTING.md` | Testing and verification guide |
| `CONTRIBUTING.md` | Customization guide |

## Usage Patterns

### Automatic Delegation
```
"Create a REST API endpoint for users"
"Refactor this module to use async/await"
"Analyze security vulnerabilities"
```

Claude Code automatically delegates to codex-executor when appropriate.

### Explicit Delegation
```
"Use the codex-executor agent to implement a CSV parser"
"Have codex-executor analyze this codebase"
```

### View Available Agents
```
/agents
```

## Codex CLI Flags

| Flag | Purpose |
|------|---------|
| `--full-auto` | Low-friction mode (recommended for most tasks) |
| `--json` | Structured JSON output |
| `--output-last-message <file>` | Save results to file |
| `--model <model>` | Override model selection |
| `--sandbox <policy>` | Set permissions (read-only, workspace-write, danger-full-access) |
| `--cd <dir>` | Set working directory |
| `--search` | Enable web search |

## Agent Frontmatter Fields

```yaml
---
name: agent-name                # Required: unique identifier
description: When to use this   # Required: helps Claude decide when to delegate
tools: Bash, Read, Write        # Optional: available tools (inherits all if omitted)
model: sonnet                   # Optional: sonnet, opus, haiku, inherit
permissionMode: default         # Optional: default, acceptEdits, dontAsk, bypassPermissions, plan
---
```

## Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Read-only exploration mode |

## Hook Events

| Event | When Triggered |
|-------|---------------|
| `SubagentStart` | Agent begins execution |
| `SubagentStop` | Agent completes |
| `PreToolUse` | Before tool execution |
| `PostToolUse` | After tool execution |

### Hook Exit Codes
- **0** - Allow operation
- **2** - Block operation (return stderr to Claude)

## Validation Script Usage

```bash
# Test validation script
echo '{"tool_input":{"command":"codex exec test"}}' | ./scripts/validate-codex-command.sh
echo $?  # 0 = allow, 2 = block

# Allow dangerous operations (in safe environments only)
export CODEX_ALLOW_DANGER_MODE=1
export CODEX_ALLOW_BYPASS=1
```

## Common Tasks

### Enable Validation Hook

Edit `.claude/settings.local.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "./scripts/validate-codex-command.sh"}
        ]
      }
    ]
  }
}
```

### Customize Agent Model

Edit `./codex-executor.md`:
```yaml
---
model: haiku  # For speed
# or
model: opus   # For complexity
---
```

### Limit Agent Permissions

Edit `./codex-executor.md`:
```yaml
---
tools: Bash, Read, Grep, Glob  # Read-only (no Write/Edit)
permissionMode: dontAsk
---
```

### Add Project-Specific Rules

Edit the system prompt in `./codex-executor.md`:

```markdown
## Project Rules

For this project:
- Always use TypeScript
- Follow existing code style
- Run `npm test` after changes
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "codex: command not found" | Install Codex CLI and add to PATH |
| Agent not delegating | Explicitly request: "Use the codex-executor agent..." |
| Authentication errors | Run `codex login` |
| Validation blocks everything | Check script permissions: `chmod +x scripts/validate-codex-command.sh` |
| Hooks not working | Verify script path is relative to project root |

## Prerequisites

```bash
# Install and authenticate Codex CLI
npm install -g @openai/codex
codex login
codex login status

# Verify setup
codex --version
which codex
```

## Testing

```bash
# Quick test
claude  # Start Claude Code
# Then: "Use codex-executor to create a hello world function"

# Test validation hook
./scripts/validate-codex-command.sh <<< '{"tool_input":{"command":"codex exec test"}}'

# Check agent syntax
python3 -c "import yaml; yaml.safe_load(open('./codex-executor.md').read().split('---')[1])"
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CODEX_ALLOW_DANGER_MODE` | Allow `danger-full-access` sandbox mode |
| `CODEX_ALLOW_BYPASS` | Allow bypassing all approvals and sandboxing |
| `CI` | Detected for CI/CD mode behavior |

## Best Practices

- Use `--full-auto` for most development tasks
- Save output with `--output-last-message`
- Provide clear, specific task descriptions
- Include context about existing code
- Verify changes after delegation
- Use appropriate sandbox settings
- Enable validation hooks for safety
- Document project-specific rules in agent prompt

## Resources

- **Agent Documentation**: https://code.claude.com/docs/en/sub-agents
- **Codex CLI Reference**: https://developers.openai.com/codex/cli/reference
- **Project README**: [README.md](./README.md)
- **Usage Examples**: [example-usage.md](./example-usage.md)
- **Testing Guide**: [TESTING.md](./TESTING.md)
- **Customization Guide**: [CONTRIBUTING.md](./CONTRIBUTING.md)
