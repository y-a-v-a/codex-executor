# Claude Code Codex Agent

A Claude Code subagent that offloads code generation, refactoring, and analysis
to OpenAI Codex CLI — so you can work from Claude Code while burning Codex
tokens instead of Claude tokens on heavy tasks.

## Why

If you have more Codex budget than Claude budget, this agent lets you use
Claude Code as a thin orchestration layer while Codex does the expensive work:
generating code, refactoring files, writing tests, running analysis.

Claude Code stays responsible for planning, answering questions, git operations,
and small edits. The big token-hungry tasks get shipped to Codex.

## Setup

### Prerequisites

- [Claude Code](https://code.claude.com)
- [Codex CLI](https://developers.openai.com/codex/cli) — install and authenticate:

```sh
npm install -g @openai/codex
codex login
```

### Install the Agent

```sh
git clone git@github.com:y-a-v-a/codex-executor.git

# symlink into Claude Code agents directory
ln -s /path/to/codex-executor ~/.claude/agents/codex-executor
```

Verify the symlink:

```sh
ls -l ~/.claude/agents/codex-executor
# codex-executor -> /path/to/codex-executor
```

### Permissions

In `~/.claude/settings.json` or per-project `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Task(codex-executor)"
    ]
  }
}
```

### Verify

Start Claude Code and run `/agents` — you should see `codex-executor` listed.

## Usage

### Explicit delegation

```
"Use the codex-executor to create a REST API endpoint for user authentication"
"Have codex-executor refactor src/auth.ts to use async/await"
```

### Automatic delegation

Claude Code will delegate automatically when the task matches the agent's
description (code generation, refactoring, large modifications). See
`CLAUDE.md` for routing guidance.

### What happens under the hood

1. Claude Code delegates the task to the subagent (runs on Haiku to minimize Claude token cost)
2. The subagent constructs a `codex exec --full-auto` command
3. The validation hook checks the command for safety
4. Codex CLI executes the task, reads files, and writes changes
5. The subagent relays a short summary of what changed

## Key Files

| File | Purpose |
|------|---------|
| `codex-executor.md` | Agent definition (YAML frontmatter + system prompt) |
| `scripts/validate-codex-command.sh` | Safety validation hook |
| `CLAUDE.md` | Routing guidance for Claude Code |

## Customization

### Agent model

Edit `codex-executor.md` frontmatter:

```yaml
model: haiku   # cheap, fast (default — recommended for cost arbitrage)
model: sonnet  # smarter orchestration, costs more Claude tokens
model: opus    # most capable, most expensive
```

### Permission mode

```yaml
permissionMode: default         # standard permission prompts
permissionMode: acceptEdits     # auto-accept file edits
permissionMode: bypassPermissions  # skip all checks
```

### Adding tools back

If you need the subagent to explore the codebase before calling Codex (costs
more Claude tokens):

```yaml
tools: Bash, Read, Glob, Grep
```

### Codex CLI flags

The agent always uses `--full-auto` and `--output-last-message`. Additional
flags:

| Flag | Purpose |
|------|---------|
| `--cd <dir>` | Set working directory |
| `--search` | Enable web search |
| `--model <model>` | Override Codex model |
| `--sandbox <policy>` | `read-only`, `workspace-write`, `danger-full-access` |
| `--json` | Structured JSON output |

### Adding validation rules

Edit `scripts/validate-codex-command.sh`:

```bash
# Block specific models
if echo "$COMMAND" | grep -q -- "--model gpt-3.5"; then
  echo "Blocked: This project requires gpt-4 or better" >&2
  exit 2
fi

# Restrict paths
if echo "$COMMAND" | grep -q -- "--cd /production"; then
  echo "Blocked: Cannot run Codex against production paths" >&2
  exit 2
fi
```

### Creating specialized agents

Copy `codex-executor.md` and adjust. Example read-only analyzer:

```yaml
---
name: codex-analyzer
description: Analyze code quality and security using Codex without making changes.
tools: Bash
model: haiku
---

Run Codex in read-only mode. Always use:
codex exec --full-auto --sandbox read-only --output-last-message /tmp/codex-analysis.md "<task>"
```

## Testing

### Verify agent availability

```
/agents  # in Claude Code
```

### Test delegation

```
"Use the codex-executor agent to create a hello world function in Python"
```

### Test the validation hook

```bash
# Should pass (exit 0)
echo '{"tool_input":{"command":"codex exec --full-auto \"hello\""}}' | ./scripts/validate-codex-command.sh
echo $?

# Should block (exit 2)
echo '{"tool_input":{"command":"codex exec --sandbox danger-full-access \"x\""}}' | ./scripts/validate-codex-command.sh
echo $?

# Run the full test suite
./scripts/test-validation.sh
```

### Validate YAML syntax

```bash
python3 -c "import yaml; yaml.safe_load(open('./codex-executor.md').read().split('---')[1])"
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CODEX_ALLOW_DANGER_MODE` | Allow `danger-full-access` sandbox mode |
| `CODEX_ALLOW_BYPASS` | Allow `--dangerously-bypass-approvals-and-sandbox` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `codex: command not found` | `npm install -g @openai/codex` and verify `which codex` |
| Agent not listed in `/agents` | Check symlink: `ls -l ~/.claude/agents/codex-executor` |
| Agent not delegating | Explicitly request: "Use the codex-executor agent to..." |
| Authentication errors | Run `codex login` |
| Validation blocks everything | `chmod +x scripts/validate-codex-command.sh` and verify `jq` is installed |
| Hook not triggering | Verify script path is relative to project root |

## Resources

- [Claude Code subagent docs](https://code.claude.com/docs/en/sub-agents)
- [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
