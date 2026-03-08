# Codex Skills Reference

## Examples

### `/codex` — Task Execution

```
/codex create a function to parse CSV files with error handling
/codex implement a REST API endpoint for user authentication
/codex refactor the authentication module to use modern async patterns
/codex convert this callback-based code to use promises
/codex analyze security vulnerabilities in the codebase
/codex generate unit tests for the UserService class
/codex fix the race condition in the connection pool
```

### `/codex-review` — Code Review

```
/codex-review --uncommitted          # Review working tree changes
/codex-review --base main            # Review branch vs base branch
/codex-review --commit abc123        # Review a specific commit
```

## Prerequisites

```bash
npm install -g @openai/codex
codex login
codex --version
```

## File Locations

| File | Purpose |
|------|---------|
| `skills/codex/SKILL.md` | Codex task execution skill |
| `skills/codex/scripts/validate-codex-command.sh` | Safety validation hook |
| `skills/codex-review/SKILL.md` | Code review skill |

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

## Skill Frontmatter Fields

```yaml
---
name: skill-name
description: When to use this
argument-hint: [what to pass]
disable-model-invocation: true   # prevent auto-invocation
context: fork                    # isolated context (no conversation history)
agent: Explore                   # read-only agent
allowed-tools: Bash(codex *), Read
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: bash scripts/validate-codex-command.sh
---
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `CODEX_ALLOW_DANGER_MODE` | Allow `danger-full-access` sandbox mode |
| `CODEX_ALLOW_BYPASS` | Allow bypassing all approvals and sandboxing |
| `CI` | Detected for CI/CD mode behavior |

## Customization

Restrict tools in `skills/codex/SKILL.md`:
```yaml
allowed-tools: Bash(codex *), Read, Grep, Glob
```

Add project rules to the Markdown body of `skills/codex/SKILL.md`:
```markdown
## Project Rules
- Always use TypeScript
- Run `npm test` after changes
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `codex: command not found` | Install Codex CLI and add to PATH |
| Skill not appearing | Check symlink: `ls -la ~/.claude/skills/codex` |
| Authentication errors | Run `codex login` |
| Validation blocks everything | `chmod +x skills/codex/scripts/validate-codex-command.sh` |
| Hooks not working | Verify script path is relative to skill directory |

## Resources

- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Codex CLI Reference](https://developers.openai.com/codex/cli/reference)
