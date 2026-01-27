# Claude Code Codex Agent

A Claude Code agent that delegates coding tasks to OpenAI Codex CLI.

## Quick Start

Install prerequisites: [Claude Code](https://code.claude.com) and [Codex CLI](https://developers.openai.com/codex/cli)

```sh
# clone repository
git clone git@github.com:y-a-v-a/codex-executor.git

# symlink directory from claude agents
cd ~/.claude/agents
ln -s ~/Projects/codex-executor
```

When you `ls -l` the output should be something like 

`codex-executor -> /Users/vincentb/Projects/codex-executor`

Set permissions correctly in `~/.claude/settings.json` or on project level from the project root in `.claude/settings.local.json`

```json
{
  "permissions": {
    "allow": [
      "Task(codex-executor)"
    ]
  }
}
```

Now one can ask Claude Code to offload a task to the codex subagent:

```
"Use the codex-executor to create a REST API endpoint for user authentication"
"Refactor this module to use async/await using the codex-executor agent"
```

The agent automatically delegates when appropriate, gathering context and executing Codex with the right flags.

## Key Files

- `./codex-executor.md` - Agent definition
- `./scripts/validate-codex-command.sh` - Command validation for safety

## Documentation

- **[QUICKREF.md](./QUICKREF.md)** - Complete reference: CLI flags, configuration, hooks, troubleshooting
- **[example-usage.md](./example-usage.md)** - Usage patterns and workflow examples
- [Claude Code agent docs](https://code.claude.com/docs/en/sub-agents)
- [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
