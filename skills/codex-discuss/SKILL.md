---
name: codex-discuss
description: Reach agreement with OpenAI Codex on a design, plan, or approach through a turn-based discussion in a shared markdown file. Use during ideation or planning when you want a second model to challenge and sharpen an approach before any code is written.
argument-hint: [topic or question to work through]
disable-model-invocation: true
allowed-tools: Bash(codex *), Read, Write, Edit, Glob, Grep
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: bash scripts/validate-codex-command.sh
---

You drive a structured, turn-based discussion with OpenAI Codex to converge on a
plan **before** implementation. A second model that argues the other side is
worth more than a second model that agrees with you — so the roles are
deliberately adversarial.

## Topic

$ARGUMENTS

## Why two models

You review your own work with a positive bias and review others' work with a
critical one. This skill exploits that: **you propose, Codex challenges.** Codex
is instructed to find the weakest part of each proposal, not to validate it.
Agreement only counts once the objections have actually been answered.

## The shared file

One markdown file is the entire conversation. **You are the only writer** —
Codex runs read-only, reads the file from disk, and returns its turn as text,
which you append. This keeps a single source of truth and prevents write races.

Create it in the invoking repo so the reasoning trail can be committed (or
ignored) as the user sees fit:

```
codex-discussions/<slug>.md      # slug = short kebab-case topic, e.g. caching-strategy
```

Template:

```markdown
# Discussion: <Topic>

- **Started:** <date>
- **Participants:** Claude (proposer) · Codex (challenger)
- **Status:** IN_PROGRESS    <!-- IN_PROGRESS | CONVERGED | IMPASSE -->
- **Round:** 1 / <max>

## Goal
<the decision to be made, in one or two sentences>

## Constraints
- <hard requirements, non-negotiables, context>

## Repo context
- <relevant files you found and what each implies>
- <conventions / invariants the challenger must not break>

---

## Turn 1 — Claude (proposer)
<the proposal and the reasoning behind it>

**Signal:** PROPOSE
**Questions for Codex:** <what you most want pressure-tested>
```

## The loop (autonomous)

Run to a conclusion without pausing for the user. Each round:

1. **Codex's turn.** Capture it to a temp file, then append it verbatim under a
   `## Turn N — Codex (challenger)` heading:

   ```bash
   codex exec --sandbox read-only --skip-git-repo-check --cd "$(pwd)" \
     --output-last-message /tmp/codex-turn.md \
     "You are the challenger in a design discussion. Read the discussion file at \
      codex-discussions/<slug>.md, AND open the actual repo files it lists under \
      '## Repo context' — argue from the code itself, not from the proposer's \
      summary of it. Respond with ONLY your next turn as markdown: attack the \
      latest proposal — surface risks, edge cases, hidden costs, and a concrete \
      alternative where you have one. End with a line: \
      'Signal: AGREE | AGREE_WITH_CAVEATS | DISAGREE | NEEDS_INFO'. \
      On the first round you MUST raise at least one substantive objection — do not \
      agree yet. Do not modify any files."
   ```

   `--cd "$(pwd)"` runs Codex in the repo so it can read those files directly;
   `--skip-git-repo-check` avoids the trusted-directory refusal.

   **Round 1 only — point the challenger at the code; don't summarize it for
   it.** Codex runs read-only and starts cold. Write the `## Repo context`
   section as an **index of files to read** — each path plus one line on why it
   matters and any invariant it must not break. This list is a *pointer*, **not
   the evidence**: the prompt above `--cd`s Codex into the repo and tells it to
   open those files itself, so its objections are anchored to the actual code —
   including the negative space (an omitted invariant, a stale command, a
   sibling-skill mismatch) that a prose digest silently hides. Never let the
   digest stand in for the read.

2. **Your turn.** Read Codex's turn. Address each objection honestly — concede
   what's right, defend what's wrong with reasons, revise the proposal. Append a
   `## Turn N+1 — Claude (proposer)` heading ending in a `**Signal:**` line.

3. **Check convergence** (see below). If not converged and under the round cap,
   re-run Codex.

### Convergence
- **CONVERGED** when the two most recent turns (one from each side) both signal
  `AGREE` or `AGREE_WITH_CAVEATS` *and* no objection in the thread is still open.
- **IMPASSE** when the round cap is hit (default **5** round-trips) without
  convergence, or the same disagreement repeats two rounds running.

When the loop ends, fill in an `## Outcome` section:

```markdown
## Outcome
- **Result:** CONVERGED | IMPASSE
- **Decision:** <the agreed approach, or "no agreement">
- **Agreed plan:**
  1. <concrete, ordered steps both sides accept>
- **Caveats / risks accepted:** <from AGREE_WITH_CAVEATS>
- **Unresolved (impasse only):** <the specific points still in dispute, each
  side's position, and what would settle it>
```

## Variations
- **Codex proposes.** When you want Codex's design instead, write the goal and
  ask Codex for Turn 1; you take the challenger role. Same loop, roles swapped.
- **Deeper context.** Add `--search` to let Codex consult external sources, or
  `--model <model>` to pick the reviewer model.

## Reporting
After the loop, tell the user: the **result** (converged or impasse), the
**agreed plan** (or the open disagreements with both positions), the number of
rounds, and the **path to the discussion file**. Do not start implementing
unless the user asks — converging on the plan is the deliverable.
