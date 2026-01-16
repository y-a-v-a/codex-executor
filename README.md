# Claude Code Codex Agent

A Claude Code agent that delegates coding tasks to OpenAI Codex CLI.

## Quick Start

1. Install prerequisites: [Claude Code](https://code.claude.com) and [Codex CLI](https://developers.openai.com/codex/cli)
2. The agent at `.claude/agents/codex-executor.md` is automatically available
3. Ask Claude Code to perform coding tasks:
   ```
   "Create a REST API endpoint for user authentication"
   "Refactor this module to use async/await"
   ```

The agent automatically delegates when appropriate, gathering context and executing Codex with the right flags.

## Key Files

- `.claude/agents/codex-executor.md` - Agent definition
- `.claude/settings.example.json` - Example configuration with safety hooks
- `scripts/validate-codex-command.sh` - Command validation for safety

## Documentation

- **[QUICKREF.md](./QUICKREF.md)** - Complete reference: CLI flags, configuration, hooks, troubleshooting
- **[example-usage.md](./example-usage.md)** - Usage patterns and workflow examples
- [Claude Code agent docs](https://code.claude.com/docs/en/sub-agents)
- [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
