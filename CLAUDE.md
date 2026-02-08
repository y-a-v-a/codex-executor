# Codex Executor — Agent Guidance

## Task Routing

This project includes a codex-executor subagent that offloads work to OpenAI
Codex CLI. Use it to conserve Claude tokens on expensive tasks.

**Delegate to codex-executor:**
- New file creation (functions, classes, modules, tests)
- Refactoring across multiple files
- Code generation from specifications or descriptions
- Large analysis tasks (security audits, performance reviews)
- Test generation for existing code

**Handle directly (do NOT delegate):**
- Answering questions about code
- Small edits (fewer than ~20 lines in a single file)
- Git operations (commit, push, branch, diff)
- File reading and exploration
- Conversation, planning, and clarification

## When Delegating

Pass specific context in the task description: file paths, function names,
constraints, and the desired outcome. The subagent does not explore the
codebase — it passes your description straight to Codex.

## Validation

All Bash commands run through `scripts/validate-codex-command.sh` which blocks
dangerous sandbox modes and missing Codex installation. No action needed unless
you see a validation error in the hook output.
