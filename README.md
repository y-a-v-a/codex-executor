# Claude Code Codex Agent

This project contains an agent to be used with Claude Code. The agent puts OpenAI Codex to work with tasks. Claude Code can hand over these tasks to the Codex Agent.

## Quick Start

The Codex executor agent is located at `.claude/agents/codex-executor.md` and is automatically available when using Claude Code in this directory.

### Usage

Simply ask Claude Code to perform coding tasks, and it will automatically delegate to the Codex agent when appropriate:

```
"Create a REST API endpoint for user authentication"
"Refactor this module to use async/await"
"Analyze the codebase for security vulnerabilities"
```

Or explicitly request the agent:

```
"Use the codex-executor agent to implement a CSV parser"
```

See [example-usage.md](./example-usage.md) for detailed examples and usage patterns.

## Agent Features

- **Automatic delegation** - Claude Code knows when to use Codex
- **Intelligent CLI usage** - Selects appropriate flags and sandbox settings
- **Context gathering** - Reads relevant code before delegating
- **Clear reporting** - Summarizes what Codex accomplished
- **Error handling** - Retries with adjusted parameters on failure

## Prerequisites

- [Claude Code CLI](https://code.claude.com) installed and configured
- [Codex CLI](https://developers.openai.com/codex/cli) installed and authenticated
- Both CLIs should be in your PATH

## File Structure

```
.
├── .claude/
│   ├── agents/
│   │   └── codex-executor.md    # The Codex agent definition
│   └── settings.local.json       # Project settings
├── README.md                     # This file
└── example-usage.md              # Usage examples and patterns
```

## Documentation

- Agent documentation: https://code.claude.com/docs/en/sub-agents
- Codex CLI reference: https://developers.openai.com/codex/cli/reference

## Customization

Edit `.claude/agents/codex-executor.md` to customize:
- Tool access permissions
- Model selection (sonnet, opus, haiku)
- Permission modes
- System prompt behavior
- Workflow steps
