# Project Evaluation: codex-executor

An honest architectural and design review of the codex-executor project.

## Summary

The codex-executor is a Claude Code subagent that delegates coding tasks to
OpenAI's Codex CLI. It consists of a 144-line agent definition (YAML
frontmatter + system prompt), a 73-line bash validation script, and ~800 lines
of documentation across 5 files.

## Core Question: Why?

The project has a fundamental identity problem. It uses one frontier AI coding
agent (Claude Code) to orchestrate another (Codex). The documentation never
convincingly answers why a user would want this instead of just using Claude
Code directly.

Legitimate answers that *could* be articulated but aren't:

- **Model diversity** -- second opinion from a different model family
- **Sandboxing** -- Codex's own sandbox model for untrusted execution
- **Specific strengths** -- if Codex is measurably better at certain tasks
- **Cost arbitrage** -- cheaper for certain workloads
- **Parallel execution** -- run tasks through multiple models simultaneously

## Architecture Assessment

### What works

- **System prompt quality** -- clear workflow, good examples, appropriate flags
- **Hook-based safety** -- PreToolUse validation is the right pattern
- **Clean separation** -- config (YAML), behavior (prompt), safety (script)
- **Extensibility** -- easy to create derived agents for specific purposes

### What doesn't

1. **Lossy delegation model** -- context gathered by the parent session is lost.
   The subagent re-gathers it, constructs a natural language prompt, and Codex
   re-interprets it. Each hop loses fidelity.

2. **No feedback loop** -- fire-and-forget delegation with no mechanism for
   iterative correction while preserving context.

3. **Misleading "automatic delegation"** -- the description field is too broad
   ("coding tasks") for meaningful routing. It either matches everything or
   nothing.

4. **Over-documented, under-built** -- ~6x more documentation than actual
   project content, with significant repetition across 5 doc files.

5. **No automated tests** -- 293-line TESTING.md but zero actual test cases.

### Validation Script Issues

- Missing `set -euo pipefail`
- `--sandbox.*danger-full-access` grep misses space-separated form
- Auth check warns but doesn't block (just noise)
- Codex installation check happens too late in the validation order

## Recommendations

### High Impact

1. **Articulate the value proposition** -- pick one clear use case and build for it
2. **Cut documentation to one file** -- merge 5 docs into a single README
3. **Add structured I/O protocol** -- machine-readable task format instead of
   freeform natural language piping
4. **Add automated tests** -- validation script test harness at minimum

### Medium Impact

5. **Make output actionable** -- structured results (diffs, files changed,
   confidence) instead of prose summaries
6. **Question the subagent layer** -- a simple shell script might achieve the
   same result with less overhead
7. **Tighten the system prompt** -- more structured, machine-parseable sections
   with explicit success/failure criteria

### For AI Agent Friendliness

8. **Define output schemas** -- so parent agents know what data shape to expect
9. **Add dry-run mode** -- construct but don't execute, for parent review
10. **Include explicit evaluation criteria** -- how should the agent judge success?

## Verdict

The project demonstrates solid understanding of Claude Code's subagent system.
The system prompt is competent and the validation hook is the right pattern. But
it's a thin wrapper with unclear value proposition, and the documentation
volume far exceeds the substance. The most impactful improvement would be
ruthlessly answering "why Codex through Claude instead of just Claude?" and
building specifically for that answer.
