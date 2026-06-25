---
name: codex-validate
description: Validate the codex, codex-review, and codex-discuss skills end-to-end in a session where the Codex CLI is available — preflight, hook unit tests, and per-skill smoke tests that prove context actually reaches Codex — then self-improve by recording each run and tightening checks when something breaks. Use when codex is installed and you want to confirm the skills still work.
argument-hint: [all | codex | codex-review | codex-discuss | hooks] [--fix]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: bash scripts/validate-codex-command.sh
---

You validate that the sibling Codex skills actually work against a *live* Codex
CLI, and you keep this validation flow sharp over time. The hard part of these
skills isn't running a command — it's proving the **context handoff** works:
`codex exec` is stateless, so every smoke test below is designed to confirm that
what you put in the prompt actually reached Codex, not just that a command exited 0.

## Scope

`$ARGUMENTS`

- No target, or `all` → run preflight, hooks, and all three skill smoke tests.
- `codex` | `codex-review` | `codex-discuss` | `hooks` → run just that suite.
- `--fix` → when a check fails, apply the fix to the offending skill (not only
  this validator) instead of only reporting it. Without `--fix`, propose the fix
  and ask before editing a sibling skill.

The skills under test live at `skills/codex/SKILL.md`,
`skills/codex-review/SKILL.md`, `skills/codex-discuss/SKILL.md`.

## 0. Preflight (always run first)

```bash
command -v codex && codex --version    # must exist — this skill is pointless without it
codex login status                     # must be authenticated
command -v jq                          # the validation hook needs jq
```

If `codex` is missing, **stop** and tell the user — there is nothing to validate.
Do the rest of the work in a throwaway directory so the repo stays clean:

```bash
SANDBOX="$(mktemp -d)"; echo "$SANDBOX"
```

## 1. Hooks suite — the safety gate must hold

Run the allow/block unit tests against **every** script copy (all four:
codex, codex-review, codex-discuss, and this skill's own copy):

```bash
for s in skills/codex skills/codex-review skills/codex-discuss .claude/skills/codex-validate; do
  echo "== $s =="
  echo '{"tool_input":{"command":"codex exec test"}}' | bash "$s/scripts/validate-codex-command.sh"; echo "allow exit=$?"
  echo '{"tool_input":{"command":"codex exec --dangerously-bypass-approvals-and-sandbox test"}}' | bash "$s/scripts/validate-codex-command.sh"; echo "block exit=$?"
done
```

**Pass:** the danger flag blocks (exit 2) everywhere; a plain `codex exec`
is *not* blocked by the script's own rules (in a live session with codex on PATH
and authenticated, the allow case exits 0). **Fail:** any script lets the danger
flag through, or the four scripts diverge — they must stay identical.

## 2. `codex` smoke test — does the brief reach Codex?

The point is to prove the gathered context drives the output, not just that a
file appeared. Plant a unique sentinel in the brief's constraints and assert it
shows up in the result:

```bash
SENT="csv_parse_$RANDOM"     # unique marker the model can only know from the brief
cat > "$SANDBOX/brief.md" <<EOF
## Intent
A working CSV parser exists in parser.py.
## Constraints / conventions
- The function MUST be named exactly: $SENT
## Task
Create parser.py with that one function; parse a comma-separated line into a list.
EOF
codex exec --full-auto --cd "$SANDBOX" --output-last-message "$SANDBOX/out.txt" "$(cat "$SANDBOX/brief.md")"
grep -q "$SENT" "$SANDBOX/parser.py" && echo "PASS: brief reached Codex" || echo "FAIL: sentinel missing — context was dropped"
```

**Pass:** `parser.py` exists and contains the sentinel name. **Fail (the
regression we care about):** the file is missing the sentinel → the brief didn't
reach Codex, i.e. the skill is back to throwing context away. Fix `skills/codex`.

## 3. `codex-review` smoke test — does the diff reach the reviewer?

Feed a diff with one obvious, specific defect and assert the review names it:

```bash
printf 'def charge(amount):\n    API_KEY = "sk-live-1234567890"\n    return bill(API_KEY, amount)\n' > "$SANDBOX/pay.py"
( cd "$SANDBOX" && git init -q && git add pay.py && git commit -qm seed && \
  sed -i 's/return bill/return  bill/' pay.py && git diff > review.diff )
cat > "$SANDBOX/rbrief.md" <<EOF
## Intent
Billing helper; must not leak secrets.
## Instructions
For each finding give severity, category, file:line, problem, and a fix.
## Diff
\`\`\`diff
$(cat "$SANDBOX/review.diff")
\`\`\`
EOF
codex exec --sandbox read-only --output-last-message "$SANDBOX/rout.md" "$(cat "$SANDBOX/rbrief.md")"
grep -qiE 'api_key|secret|hardcoded' "$SANDBOX/rout.md" && echo "PASS: diff reached reviewer" || echo "FAIL: hardcoded secret not flagged — diff was dropped"
```

**Pass:** the review flags the hardcoded key (proving the diff content reached
Codex). **Fail:** generic output with no reference to the planted defect → the
diff was dropped (e.g. passed as a stray second positional arg). Fix `skills/codex-review`.

## 4. `codex-discuss` smoke test — structure and grounding

Run a short, capped discussion on a trivial topic and check the *shape* of the
artifact rather than the conclusion:

```bash
codex exec --sandbox read-only --output-last-message "$SANDBOX/turn.md" \
  "You are the challenger in a design discussion. Read nothing; the proposal is: \
   'store config in a single JSON file'. Raise one substantive objection and end \
   with a line: 'Signal: AGREE | AGREE_WITH_CAVEATS | DISAGREE | NEEDS_INFO'."
grep -qE '^Signal:' "$SANDBOX/turn.md" && echo "PASS: challenger emits a Signal" || echo "FAIL: no Signal line — convergence detection will break"
```

Also confirm by reading `skills/codex-discuss/SKILL.md` that the round-1 prompt
still grounds the challenger in repo context and the loop still defines
CONVERGED / IMPASSE. **Fail:** no `Signal:` line, or the convergence rules went
missing.

## 5. Cleanup & report

```bash
rm -rf "$SANDBOX"
```

Report a table: each suite → PASS / FAIL / SKIPPED, with the one-line reason for
any failure. Lead with failures. End with the path to this skill's validation
log (below) so the user can see the trail.

## Self-improvement (do this every run — it is part of the job)

This skill is the single source of truth for *how we validate*, and it is
expected to get better each time you run it. After reporting:

1. **On any failure, find the root cause and fix the right file.**
   - Skill regression (context dropped, Signal gone, hook weakened) → fix the
     offending sibling skill. With `--fix`, edit it now; otherwise propose the
     diff and ask first. Re-run that suite to confirm green.
   - A flaky check (e.g. an over-strict `grep`) → fix the check *here* so it
     stops crying wolf.

2. **When the Codex CLI surface changes** (a flag renamed, `codex review`
   behavior shifts, a new sandbox mode) and a check breaks because of it: update
   the smoke test here AND the affected skill/`docs/reference.md` to match, so
   the skills track reality.

3. **When you discover a sharper check** — a failure mode these tests would have
   missed — add it as a new step rather than leaving it in your head. The next
   run should catch what this run only caught by luck.

4. **Always append one entry to the log below**, even on a clean pass. Keep it to
   the newest ~10 entries; summarize and drop older ones. This is what makes the
   skill self-improving instead of self-forgetting: each run leaves the next run
   a better map of where these skills tend to break.

Never edit a sibling skill silently — every change you make to one must show up
as a log entry here describing what broke and what you changed.

## Validation log

<!-- Newest first. Template:
### <date> — target: <all|codex|...>  result: <PASS|FAIL>
- Suites: hooks <P/F>, codex <P/F>, codex-review <P/F>, codex-discuss <P/F>
- Failure & root cause: <what broke, in which file>
- Fix applied: <file(s) changed, or "none">
- Check added/changed: <new or tightened check here, or "none">
-->

### (seed) — no runs yet
- This log is filled in by the skill on first execution. Replace this entry with
  the first real run.
