# Baseline — 1pct-moves-only

Methodology and latest measurements. Re-run with:

```bash
# Transcript audit (no API cost)
./bin/audit-sessions.sh --days 30

# Promptfoo suite (~$0.05 per run on Sonnet)
npx promptfoo eval -c evals/promptfooconfig.yaml
```

## Latest run

| Run date | Sessions scanned | Sessions with violations | Red-flag hits | Frustration hits | Worst pattern |
|---|---|---|---|---|---|
| 2026-04-14 (v3 ship, 14d window) | 1,392 | 118 (8.5%) | 232 (0.17/session) | 81 | "Ready to implement?" — by far the most common, exactly the v1-birthing violation |

**Interpretation:** The skill addresses a real, measured pathology. 8.5% of recent sessions contain at least one hedging violation; the most common pattern is the literal phrase that birthed the skill. Frustration regex fired 81 times in 14 days — confirming user-side cost.

### Pattern breakdown (top from 14d audit)
- "Ready to implement?" — dominant
- "in a fresh session" — second-most common (false-pause toward fresh session when current fits)
- "Would you like me to" — present in agent transcripts especially
- "Suggested next:" — rarer but high-friction when it appears

### Eval pass rate

**2026-04-14 attempt: BLOCKED — Anthropic API credit balance depleted.** Re-run when credits top up. Command:

```bash
npx promptfoo eval -c evals/promptfooconfig.yaml
```

The harness, scenarios, and assertions are in place; only the LLM provider call is gated. Estimated cost when unblocked: ~$0.05/run on Sonnet. This eval is the load-bearing missing piece — until it runs, the pass-rate column above is unverified.

## Metrics defined

- **Eval pass rate:** `(passing scenarios) / (total scenarios)` from promptfoo. Target: >90%.
- **Transcript red-flag rate:** total red-flag hits / sessions-scanned. Target: trend ↓ over time.
- **Frustration-regex rate:** sessions containing Anthropic's shipped frustration markers. Target: 0.
- **Omission harm** (manual): for each session with an approved plan, count pre-approved steps left unexecuted at turn end. Target: 0. This one requires human review — no automated proxy yet.

## Interpreting results

| Red-flag rate | Interpretation |
|---|---|
| 0 hits across 30d | Either the skill is perfectly enforced, or the audit isn't catching real violations — spot-check 5 sessions manually |
| 1-5 hits | Baseline for an actively-developing codebase. Acceptable. |
| 6-20 hits | Skill is advisory but not sticking. Consider enabling `ONE_PCT_STRICT=1` for the hook. |
| 20+ hits | Skill isn't being invoked or is being ignored. Re-read SKILL.md, add to companion memory. |

## Not measured here

- Commission harm (wrong actions taken). Covered by the `--review` gate after `/build-stack`, not this skill.
- Scope creep (unsolicited extra work). Detectable via `git diff` against plan-listed files; out of scope for this baseline.
