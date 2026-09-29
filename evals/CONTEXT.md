# Evals — does the doctrine actually reduce hedging

## Inputs

- `evals/promptfooconfig.yaml` — 10-scenario regression suite (phase transitions, deviation
  paths, stop signs, context-bracket non-events, approval expiration, drift, scope ambiguity).
- `evals/scenarios/_system_prompt.txt` — shared system prompt for every scenario.
- `evals/BASELINE.md` — the measured pathology this skill exists to move (232 violations
  across 118 sessions in 14 days, 1,392 transcripts scanned).
- Requires `ANTHROPIC_API_KEY` in the shell environment. Missing key: promptfoo fails closed;
  do not report a pass rate from a partial run.

## Process

1. `npx promptfoo eval -c evals/promptfooconfig.yaml` runs the regression suite.
2. Compare the run's pass rate against the number last recorded in `evals/BASELINE.md`.
3. Only rewrite `evals/BASELINE.md` after a fresh `bin/audit-sessions.sh` pass produces a new
   real-transcript measurement — never from a promptfoo run alone, which is synthetic.

## Outputs

- promptfoo's local result store (`.promptfoo/`, not versioned).
- An updated `evals/BASELINE.md` only when a new transcript-audit baseline is recorded, with
  its own date and scanned-session count.

## Human check

Alex compares both numbers — the new promptfoo pass rate and the new `bin/audit-sessions.sh`
violation count — against the prior recorded baseline before claiming the skill is working.
Either number alone is not evidence. Pass: both move the right direction. Fail: the doctrine in
`SKILL.md` or the hook regex needs a revision, not the baseline.
