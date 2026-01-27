# Contributing to Codex Agent

This guide explains how to extend and customize the Codex agent for your needs.

## Agent Architecture

The agent consists of:
- **Agent definition** - `./codex-executor.md` (YAML frontmatter + Markdown prompt)
  - Includes tool permissions, model selection, permission mode, and hooks
- **Validation script** - `./scripts/validate-codex-command.sh` (optional safety hook)
- **Settings** - `~/.claude/settings.json` (optional global configuration)

## Customizing the Agent

### Modifying the Agent Definition

Edit `./codex-executor.md`:

#### Change Available Tools

```yaml
---
tools: Bash, Read  # Remove Write, Edit for read-only mode
---
```

or

```yaml
---
tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch  # Add WebFetch for research
---
```

#### Change Model

```yaml
---
model: haiku  # Faster, cheaper for simple delegation
---
```

or

```yaml
---
model: opus  # More sophisticated task analysis
---
```

#### Change Permission Mode

```yaml
---
permissionMode: acceptEdits  # Auto-accept file edits
---
```

Options: `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`

### Modifying the System Prompt

The Markdown content after the YAML frontmatter is the system prompt. Customize it to:

- Add domain-specific knowledge
- Change workflow steps
- Add specialized Codex CLI flags for your use case
- Include project-specific context

Example addition:

```markdown
## Project-Specific Rules

For this project:
- Always use TypeScript strict mode
- Follow the existing naming conventions in `src/`
- Run tests after code generation with `npm test`
- Format code with `npm run format` before committing
```

### Adding Validation Rules

Edit `scripts/validate-codex-command.sh` to add custom validation:

```bash
# Block specific Codex models
if echo "$COMMAND" | grep -q -- "--model gpt-3.5"; then
  echo "Blocked: This project requires gpt-4 or better" >&2
  exit 2
fi

# Require certain flags
if echo "$COMMAND" | grep -q "codex exec" && ! echo "$COMMAND" | grep -q -- "--full-auto"; then
  echo "Warning: Consider using --full-auto for this project" >&2
fi

# Project-specific path restrictions
if echo "$COMMAND" | grep -q -- "--cd /production"; then
  echo "Blocked: Cannot run Codex against production paths" >&2
  exit 2
fi
```

## Creating Additional Agents

You can create multiple agents for different purposes:

### Example: Codex Analyzer Agent

Create `./codex-analyzer.md`:

```yaml
---
name: codex-analyzer
description: Use Codex to analyze code quality, security, and performance without making changes
tools: Bash, Read, Glob, Grep
model: sonnet
permissionMode: default
---

You are a read-only code analyzer using Codex CLI.

Your role is to analyze code without making modifications.

Always use:
- `--sandbox read-only` flag
- `--json` flag for structured output
- `--output-last-message` to capture results

Never modify code, only analyze and report.
```

### Example: Codex Test Generator Agent

Create `./codex-tester.md`:

```yaml
---
name: codex-tester
description: Generate test cases using Codex CLI for existing code
tools: Bash, Read, Write, Glob, Grep
model: sonnet
permissionMode: acceptEdits
---

You are a test generation specialist using Codex CLI.

Your role is to:
1. Analyze existing code
2. Generate comprehensive test cases
3. Follow project's testing conventions
4. Ensure high coverage

Always create tests in the appropriate test directory.
Use the project's testing framework (Jest, PyTest, etc).
```

## Configuring Hooks

Hooks can be configured directly in the agent's YAML frontmatter. This is the recommended approach as it keeps the configuration with the agent definition.

### Agent Lifecycle Hooks

Add to the YAML frontmatter in `codex-executor.md`:

```yaml
---
name: codex-executor
hooks:
  SubagentStart:
    - type: command
      command: echo 'Starting Codex executor agent...' >&2
  SubagentStop:
    - type: command
      command: echo 'Codex executor agent finished.' >&2
---
```

### Tool Usage Hooks

Add to the YAML frontmatter in `codex-executor.md`:

```yaml
---
name: codex-executor
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: ./scripts/validate-codex-command.sh
  PostToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: ./scripts/format-code.sh
---
```

### Alternative: Global Hooks Configuration

If you need hooks to apply across multiple agents, you can still configure them in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "codex-executor",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/setup-codex-env.sh"
          }
        ]
      }
    ]
  }
}
```

## Best Practices

### For Agent Design

- **Keep focused** - One agent, one purpose
- **Clear descriptions** - Help Claude decide when to delegate
- **Appropriate permissions** - Grant only necessary tools
- **Error handling** - Include retry logic in system prompt
- **Documentation** - Explain usage patterns in the prompt

### For System Prompts

- **Be specific** - Detailed instructions produce better results
- **Include examples** - Show concrete command patterns
- **Explain context** - Help agent understand when to use features
- **Provide workflows** - Step-by-step processes
- **Handle errors** - Explicit error handling instructions

### For Validation Scripts

- **Fail safe** - Default to blocking on uncertainty
- **Clear messages** - Explain why something was blocked
- **Exit codes** - Use 0 (allow) and 2 (block) correctly
- **Minimal dependencies** - Avoid requiring exotic tools
- **Fast execution** - Keep validation quick

## Testing Changes

After modifying the agent:

1. **Syntax check** - Ensure YAML is valid
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('./codex-executor.md').read().split('---')[1])"
   ```

2. **Reload agent** - Restart Claude Code or use `/agents` command

3. **Test delegation** - Try a simple task
   ```
   Use the codex-executor agent to create a hello world function
   ```

4. **Verify behavior** - Check that changes took effect

5. **Test hooks** - If modified, verify validation works
   ```bash
   echo '{"tool_input":{"command":"codex exec test"}}' | ./scripts/validate-codex-command.sh
   echo $?  # Should be 0 or 2
   ```

## Advanced Customization

### Dynamic Behavior Based on Project

Add project detection to the system prompt:

```markdown
## Project Detection

Before executing:
1. Check for package.json (Node.js project)
2. Check for pyproject.toml (Python project)
3. Check for Cargo.toml (Rust project)

Adjust Codex commands based on detected project type.
```

### Integration with CI/CD

Create a non-interactive mode:

```markdown
## CI/CD Mode

When running in CI (detect with CI environment variable):
- Use `--json` output always
- Use `--dangerously-bypass-approvals-and-sandbox` with caution
- Save all output to logs
- Exit with non-zero on any failure
```

### Multi-Model Strategy

Use different models for different tasks:

```markdown
## Model Selection

- Use Haiku for simple code generation
- Use Sonnet for refactoring and analysis
- Use Opus for complex architectural changes

Dynamically adjust with `--model` flag based on task complexity.
```

## Sharing Your Customizations

If you create useful modifications:

1. Document them clearly
2. Add examples to `example-usage.md`
3. Update `TESTING.md` with new test cases
4. Share in `./` for team use
5. Consider contributing back to the community

## Troubleshooting Customizations

### Agent not loading

- Check YAML syntax in frontmatter
- Ensure file is in `.` directory and symlinked from `~/.claude/agents`
- Verify file has `.md` extension
- Restart Claude Code

### Tools not available

- Check `tools:` list in frontmatter
- Verify tool names are spelled correctly
- Don't include Task tool (auto-excluded in agents)

### Hooks not triggering

- Verify script has execute permissions
- Check script path is correct (relative to project root)
- Ensure script returns proper exit codes (0 or 2)
- Check for syntax errors in hook script

### Permission issues

- Review `permissionMode` setting
- Check Claude Code settings.json
- Verify sandbox mode is appropriate for task

## Resources

- [Claude Code Agent Docs](https://code.claude.com/docs/en/sub-agents)
- [Codex CLI Reference](https://developers.openai.com/codex/cli/reference)
- [YAML Specification](https://yaml.org/spec/)
- [Bash Exit Codes](https://tldp.org/LDP/abs/html/exitcodes.html)
