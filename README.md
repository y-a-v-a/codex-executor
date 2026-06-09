# Claude Code Codex Skills

Claude Code skills that collaborate with OpenAI Codex CLI: delegate coding tasks,
run cross-model code reviews, and reach agreement on a plan through a turn-based
discussion. Claude proposes and acts; Codex — a different model — challenges and
reviews, so work gets a second opinion instead of self-review.

## Quick Start

Install prerequisites: [Claude Code](https://code.claude.com) and [Codex CLI](https://developers.openai.com/codex/cli)

```sh
# clone repository
git clone git@github.com:y-a-v-a/codex-executor.git

# symlink skills into Claude Code (adjust path to where you cloned the repo)
ln -s /path/to/codex-executor/skills/codex ~/.claude/skills/codex
ln -s /path/to/codex-executor/skills/codex-review ~/.claude/skills/codex-review
ln -s /path/to/codex-executor/skills/codex-discuss ~/.claude/skills/codex-discuss
```

Set permissions in `~/.claude/settings.json` or in `.claude/settings.local.json` at the project level:

```json
{
  "permissions": {
    "allow": [
      "Skill(codex *)",
      "Skill(codex-review *)",
      "Skill(codex-discuss *)"
    ]
  }
}
```

## Usage

### `/codex` — Task execution

Delegate a coding task to Codex:

```
/codex create a REST API endpoint for user authentication
/codex refactor this module to use async/await
/codex analyze security vulnerabilities in the codebase
```

### `/codex-review` — Cross-model code review

A different model reviews the diff; findings are triaged by severity and
contested findings are reconciled with Codex before you act:

```
/codex-review --uncommitted
/codex-review --base main --focus security
/codex-review --commit abc123 --intent "make the parser handle empty input"
```

### `/codex-discuss` — Agent discussion

Work through a design or plan with Codex in a shared markdown file. You propose,
Codex challenges, and the loop runs autonomously until you converge (or reach a
recorded impasse) — before any code is written:

```
/codex-discuss should we cache at the request layer or the data layer?
/codex-discuss design the migration from callbacks to async
```

The discussion is written to `codex-discussions/<slug>.md` in the current repo so
the reasoning trail can be committed or ignored as you prefer.

## Key Files

| Path | Purpose |
|------|---------|
| `skills/codex/SKILL.md` | Codex task execution skill |
| `skills/codex/scripts/validate-codex-command.sh` | Command validation hook |
| `skills/codex-review/SKILL.md` | Cross-model code review skill |
| `skills/codex-discuss/SKILL.md` | Agent discussion skill |
| `skills/codex-discuss/scripts/validate-codex-command.sh` | Command validation hook |

## Documentation

- **[docs/reference.md](./docs/reference.md)** — Complete reference: CLI flags, configuration, hooks, troubleshooting
- **[docs/testing.md](./docs/testing.md)** — Testing and verification guide
- [Claude Code skills docs](https://code.claude.com/docs/en/skills)
- [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
