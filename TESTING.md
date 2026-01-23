# Testing the Codex Agent

This guide explains how to test and verify the Codex executor agent.

## Prerequisites

1. **Install Codex CLI**
   ```bash
   # Follow instructions at https://developers.openai.com/codex/cli
   npm install -g @openai/codex  # or similar
   ```

2. **Authenticate Codex**
   ```bash
   codex login
   ```

3. **Verify Installation**
   ```bash
   codex --version
   codex login status
   ```

## Testing the Agent

### 1. Check Agent is Available

In Claude Code, run:
```
/agents
```

You should see `codex-executor` listed among available agents.

### 2. Test Simple Delegation

Try a simple task:
```
Use the codex-executor agent to create a hello world function in Python
```

Expected behavior:
- Claude Code delegates to codex-executor agent
- Agent runs `codex exec` command
- Agent reports back with results
- Function is created (if successful)

### 3. Test Automatic Delegation

Try a task without explicitly mentioning the agent:
```
Create a function that calculates the factorial of a number
```

Claude Code should automatically decide whether to use the codex-executor agent based on the task.

### 4. Test with Context

Create a test file first:
```bash
echo "def old_function():\n    pass" > test.py
```

Then ask:
```
Use codex-executor to refactor test.py to use type hints
```

Expected behavior:
- Agent reads the existing file
- Passes context to Codex
- Codex modifies the file
- Agent reports changes

### 5. Test Error Handling

Try a task that might fail:
```
Use codex-executor to implement a nonexistent_framework integration
```

Expected behavior:
- Agent attempts the task
- Codex may fail or ask for clarification
- Agent reports the error clearly
- Agent may suggest next steps

## Validation Hook Testing

If you enable the validation hook (see `.claude/settings.example.json`), test it:

### 1. Test Normal Command (Should Pass)
```
Use codex-executor to create a simple function
```

Should work normally.

### 2. Test Dangerous Flag (Should Block)
```
Use codex-executor with --dangerously-bypass-approvals-and-sandbox
```

Should be blocked by the validation hook unless `CODEX_ALLOW_BYPASS=1` is set.

### 3. Test with Environment Variable
```bash
export CODEX_ALLOW_DANGER_MODE=1
```

Then retry a command with `danger-full-access`. Should now pass.

## Verifying Agent Behavior

### Check Agent Logs

When the agent runs, you should see:
1. Task analysis
2. Context gathering (if needed)
3. Codex CLI command construction
4. Execution output
5. Result summary

### Check File Changes

After code generation/modification:
```bash
git status  # See what changed
git diff    # Review changes
```

### Check Codex Output

If using `--output-last-message`:
```bash
cat /tmp/codex-result.txt
```

## Common Issues

### Issue: "codex: command not found"

**Solution:**
- Ensure Codex CLI is installed
- Add to PATH if necessary
- Verify with `which codex`

### Issue: Authentication errors

**Solution:**
```bash
codex login
codex login status
```

### Issue: Agent not being used

**Possible causes:**
- Task too simple (Claude handles directly)
- Task description doesn't match agent's description field
- Agent file has syntax errors

**Solution:**
- Explicitly request the agent: "Use the codex-executor agent..."
- Check agent file syntax
- Review agent description in `.claude/agents/codex-executor.md`

### Issue: Validation hook blocks all commands

**Solution:**
- Check `scripts/validate-codex-command.sh` permissions
- Ensure script is executable: `chmod +x scripts/validate-codex-command.sh`
- Check for jq dependency: `which jq`
- Review hook configuration in `.claude/settings.local.json`

## Advanced Testing

### Test JSON Output Mode

Ask the agent to analyze something:
```
Use codex-executor to analyze code quality in this directory and provide structured output
```

Agent should use `--json` flag for structured results.

### Test Background Execution

For long tasks:
```
Run this in the background: use codex-executor to refactor the entire codebase
```

Or press `Ctrl+B` during execution.

### Test with Different Models

Edit `.claude/agents/codex-executor.md` and change:
```yaml
model: haiku  # For faster, simpler tasks
# OR
model: opus   # For complex tasks
```

Then test to see if different models affect delegation behavior.

## Debugging

### Enable Verbose Logging

Edit the agent file to add debug output:
```markdown
## Workflow

### Step 0: Debug Output
- Log all inputs and decisions
- Output Codex command before executing
```

### Check Codex Logs

Codex CLI may have its own logging:
```bash
# Check Codex config location
codex --help
# Look for log files in ~/.codex/ or similar
```

### Manual Testing

Test Codex CLI directly:
```bash
codex exec "create a hello world function"
codex exec --full-auto --output-last-message /tmp/test.txt "analyze this file"
```

Compare results with agent's behavior.

## Performance Testing

### Measure Delegation Time

Time how long it takes:
```
Use codex-executor to create 5 utility functions
```

Compare with Claude Code doing it directly (without the agent).

### Measure Output Quality

Compare code quality between:
- Codex executor agent
- Claude Code directly
- Manual Codex CLI usage

## Integration Testing

### Test with Real Projects

1. Clone a real project
2. Navigate to it in Claude Code
3. Ask for complex refactoring
4. Verify the agent handles it appropriately

### Test with Version Control

1. Make changes via codex-executor
2. Review with `git diff`
3. Ensure changes are reasonable
4. Test with pre-commit hooks if configured

## Success Criteria

The agent is working correctly if:

✅ Claude Code successfully delegates appropriate tasks to it
✅ Agent communicates clearly with Codex CLI
✅ Results are captured and summarized properly
✅ File changes are made correctly
✅ Errors are handled gracefully
✅ Validation hooks work as expected
✅ Agent reports useful information back to Claude Code

## Reporting Issues

If you find issues:
1. Document the exact task/prompt used
2. Capture the agent's output
3. Check Codex CLI logs
4. Note any error messages
5. Test Codex CLI directly to isolate the issue
