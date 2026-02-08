# Project Evaluation: codex-executor

An honest architectural and design review, refined with the understanding that
the primary use case is **cost arbitrage**: the user has more Codex tokens than
Claude Code tokens and wants to use Claude Code as a thin orchestration layer
while offloading heavy work to Codex.

---

## Revised Verdict: The Idea is Sound

With cost arbitrage as the motivation, the project makes sense. You want Claude
Code's superior UX and orchestration but can't afford to burn Claude tokens on
every code generation, refactoring, and analysis task. Codex becomes your
workhorse; Claude Code becomes your foreman. That's a legitimate and pragmatic
architecture.

**But the project isn't built for this.** It's built as a generic "delegate
coding tasks" wrapper without any awareness of token economics. The result is
a design that actually *wastes* Claude tokens on things it shouldn't be doing.

---

## What's Wrong Right Now

### 1. The subagent burns too many Claude tokens

The agent is set to `model: sonnet`. Every time it runs, you're paying Sonnet
prices for the subagent to:

- Read files (Claude tokens)
- Grep the codebase (Claude tokens)
- Think about how to construct a Codex command (Claude tokens)
- Parse and summarize results (Claude tokens)

For a cost-arbitrage use case, this is backwards. The subagent should be as
**thin and cheap as possible**. Its only job is to construct the right `codex
exec` command and relay results. That's a Haiku-tier task.

### 2. The subagent gathers context that Codex will re-gather

The system prompt (Step 2: "Prepare Context") tells the subagent to use Read,
Glob, and Grep to gather code context before passing it to Codex. But Codex
in `--full-auto` mode has its own file access. It will read the same files
itself. You're paying for context gathering twice: once in Claude tokens (the
subagent reads files), once in Codex tokens (Codex reads files).

For cost arbitrage, let Codex do the discovery. Just point it at the right
directory and describe the task.

### 3. The description field is too vague for aggressive routing

If you want to maximize delegation to Codex (to save Claude tokens), the
`description` field needs to clearly signal when to delegate. The current
description ("Delegate coding tasks... Particularly useful for tasks where
Codex's code generation capabilities would be valuable") is circular and
doesn't help Claude Code make routing decisions.

You want Claude Code to think: "This is a code generation/modification task.
I should delegate to save tokens." The description should make that trigger
obvious.

### 4. Over-documentation burns human time and adds no value

Five documentation files totaling 800+ lines for a 144-line agent definition
and a 73-line script. The content is repetitive -- CLI flags, hook config, and
troubleshooting appear in multiple files. This doesn't just waste reader time;
it actively confuses. A user (or AI agent) reading the docs doesn't know which
file is authoritative.

### 5. No token-awareness in the design

There's no guidance on what to delegate vs. what to keep in Claude Code. Quick
questions ("what does this function do?") shouldn't go to Codex -- the overhead
of spawning a subagent + Codex CLI is more expensive than Claude answering
directly. Large code generation tasks should. The project doesn't help the user
or Claude Code make this distinction.

### 6. Validation script issues (unchanged from prior review)

- Missing `set -euo pipefail`
- `--sandbox.*danger-full-access` grep misses space-separated form
- Auth check warns but doesn't block (noise)
- Codex installation check is ordered after pattern checks (should be first)

---

## Improvement Plan

Ordered by impact. Each item has a clear rationale tied to the cost-arbitrage
use case.

### Phase 1: Stop Wasting Claude Tokens (Immediate)

**1.1 Switch subagent model to haiku**

```yaml
model: haiku
```

The subagent's job is mechanical: construct a CLI command, run it, relay
results. This does not require Sonnet-level intelligence. Haiku is 10-20x
cheaper per token. This single change probably saves more Claude tokens than
everything else combined.

**1.2 Strip context-gathering from the system prompt**

Remove the "Prepare Context" step. Don't tell the subagent to Read/Glob/Grep
before calling Codex. Codex in `--full-auto` mode reads files itself. You're
paying for file reads in Claude tokens that Codex will redo in Codex tokens.

Exception: if the *parent* Claude Code session already has relevant context in
its conversation, pass it in the delegation prompt. But the *subagent* shouldn't
independently go exploring.

**1.3 Remove Read, Write, Edit, Glob, Grep from the tools list**

If the subagent shouldn't gather context, don't give it the tools to do so.

```yaml
tools: Bash
```

Bash is all it needs to run `codex exec`. Fewer tools = less temptation for the
subagent to burn Claude tokens exploring.

**1.4 Make the system prompt lean**

The current prompt is ~120 lines of guidance. For a Haiku-powered "run this CLI
command" agent, you need ~30 lines. Cut the examples, cut the best practices,
cut the safety considerations (that's what the hook is for). The prompt itself
consumes Claude tokens on every invocation.

### Phase 2: Sharpen the Routing (This Week)

**2.1 Rewrite the description for clear delegation triggers**

Current (vague):
> Delegate coding tasks to OpenAI Codex CLI for implementation.

Proposed (specific):
> Offload code generation, file creation, refactoring, and large code
> modifications to Codex CLI. Use for tasks that involve writing or changing
> code across files. Do NOT use for quick questions, code explanations, or
> small edits that Claude can handle directly.

This tells Claude Code *when* to delegate and *when not to*. The "do NOT use
for" part is critical -- it prevents wasteful delegation of cheap tasks.

**2.2 Add token-aware routing guidance to CLAUDE.md**

Put guidance in the project's CLAUDE.md (or the user's global one) that tells
Claude Code the economics:

```markdown
## Task Routing

Prefer delegating to the codex-executor agent for:
- New file creation (functions, classes, modules, tests)
- Refactoring across multiple files
- Code generation from specifications
- Large analysis tasks

Handle directly (don't delegate) for:
- Answering questions about code
- Small edits (< 20 lines)
- Git operations
- File reading and exploration
- Conversation and planning
```

This keeps the cheap stuff in Claude Code and pushes the expensive stuff to
Codex.

### Phase 3: Consolidate Documentation (This Week)

**3.1 Merge everything into README.md**

Kill QUICKREF.md, example-usage.md, TESTING.md, CONTRIBUTING.md. Merge the
non-redundant content into a single README.md with clear sections:

- Why (cost arbitrage, model diversity)
- Setup (install, symlink, permissions)
- Usage (examples)
- Customization (model, tools, hooks, validation)
- Testing (validation script tests)
- Troubleshooting

One file. No hunting. No repetition.

### Phase 4: Harden the Validation Script (Next Sprint)

**4.1 Fix the script**

```bash
set -euo pipefail
```

Reorder: check codex installation first, then parse input, then validate
patterns. Fix the sandbox grep to handle both `--sandbox=danger-full-access`
and `--sandbox danger-full-access`.

**4.2 Add automated tests**

Create `scripts/test-validation.sh`:

```bash
#!/bin/bash
# Test cases for validate-codex-command.sh
PASS=0; FAIL=0

test_case() {
  local desc="$1" input="$2" expected="$3"
  echo "$input" | ./scripts/validate-codex-command.sh 2>/dev/null
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    ((PASS++))
  else
    echo "FAIL: $desc (expected $expected, got $actual)"
    ((FAIL++))
  fi
}

test_case "allow normal codex command" \
  '{"tool_input":{"command":"codex exec --full-auto \"hello\""}}' 0

test_case "allow non-codex command" \
  '{"tool_input":{"command":"ls -la"}}' 0

test_case "block danger-full-access" \
  '{"tool_input":{"command":"codex exec --sandbox danger-full-access \"x\""}}' 2

test_case "block bypass flag" \
  '{"tool_input":{"command":"codex exec --dangerously-bypass-approvals-and-sandbox \"x\""}}' 2

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

Takes 20 minutes to write, adds real confidence.

### Phase 5: Make It AI-Agent Friendly (Later)

**5.1 Structured output by default**

Always use `--output-last-message /tmp/codex-result.md`. The subagent reads
that file and relays it. Predictable, parseable, no stdout truncation issues.

**5.2 Default to --full-auto**

Hardcode it. Every invocation should use `--full-auto`. If someone wants a
different mode, they can customize the agent. Don't make the subagent "decide"
-- that decision burns Claude tokens.

**5.3 Consider killing the subagent entirely**

Controversial but worth considering: put the Codex usage instructions directly
in CLAUDE.md as a rule. Claude Code calls `codex exec` via Bash itself, no
subagent needed. You save the entire subagent invocation cost (Haiku prompt +
response tokens). The validation hook still works because it's a PreToolUse
hook on Bash.

The subagent layer only adds value if the orchestration logic is complex enough
to justify a separate context. For "construct a CLI command and run it," it
probably isn't.

---

## Summary of Token Economics

| Current Design               | Token Cost        |
|------------------------------|-------------------|
| Subagent prompt (Sonnet)     | ~2K Claude tokens |
| Context gathering by subagent| ~5-20K Claude tokens per task |
| Subagent reasoning           | ~1-2K Claude tokens |
| Result summary               | ~500-1K Claude tokens |
| **Total Claude overhead/task**| **~8-24K tokens** |

| Proposed Design (Phase 1)    | Token Cost        |
|------------------------------|-------------------|
| Subagent prompt (Haiku)      | ~800 Haiku tokens |
| No context gathering         | 0                 |
| Subagent reasoning           | ~200-500 Haiku tokens |
| Result relay                 | ~200-500 Haiku tokens |
| **Total Claude overhead/task**| **~1-2K Haiku tokens** |

That's roughly a 10-20x reduction in Claude token spend per delegation, before
even considering Haiku's lower per-token price.

---

## The Honest Bottom Line

The cost-arbitrage use case gives this project a reason to exist. But the
current implementation is designed as if Claude tokens are free. Every design
choice -- Sonnet model, context gathering, verbose system prompt, 6 tools --
burns the very tokens you're trying to conserve.

Phase 1 (switch to Haiku, strip tools, lean prompt) can be done in an hour and
will immediately make the project do what you actually need it to do: be a
cheap, thin pipe from Claude Code to Codex.

The documentation consolidation (Phase 3) is the other quick win. Five files
for a project this size is overhead, not professionalism. One clear README
serves both humans and AI agents better.

The project's bones are good. The hook system, the YAML config, the agent
pattern -- all solid. It just needs to be rebuilt around the actual use case
instead of a generic "delegate coding tasks" framing.
