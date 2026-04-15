# Changelog

All notable changes to the 1pct-moves-only skill.

## [3.0.0] — 2026-04-14 — Enforcement + measurement + composition

### Added
- **Enforcement.** Stop hook `hooks/1pct-check.py` reads the transcript after each turn, scans the last assistant message for red-flag patterns, logs violations to `~/.claude/logs/1pct-violations.log`. Non-blocking by default. Set `ONE_PCT_STRICT=1` to block + feed back for re-attempt. Set `ONE_PCT_DISABLE=1` to no-op.
- **Eval harness.** `evals/promptfooconfig.yaml` with 10 scenarios covering phase-transitions, post-review verdicts, deviation paths, stop signs, context-bracket non-events, approval expiration, long-horizon drift, scope ambiguity, and re-summary suppression. Run with `npx promptfoo eval`.
- **Transcript audit.** `bin/audit-sessions.sh` greps Claude Code transcripts for red-flag patterns + Anthropic's frustration-detection regex (per the 2026-03-31 source leak). TSV output, summary line.
- **Test suite.** `tests/test_1pct_check.py` — 20 unit + integration tests covering 8 red-flag patterns, 5 legitimate non-violations, and the full Stop-hook protocol (stdin parsing, transcript reading, exit codes, structured content arrays, env vars).
- **Skill-friends section** in `SKILL.md` — explicit composition rules with `/planning-stack`, `superpowers:executing-plans`, `/build-stack`, `/review-stack`, `/commit`, `/ship`, `/closeout-stack`.
- **Long-horizon drift rule** in `SKILL.md` — re-read plan after ≥15 turns or ≥45 minutes; state inline in 1 line and continue.
- **3 adversarial cases** in `SKILL.md` — silent mid-plan scope creep, two equally-ordered next steps, falsified precondition.
- **Statusline integration.** `bin/statusline-hint.sh` emits `1PCT` badge when companion memory marker present.
- **One-liner installer.** `install.sh` with `--hook` and `--memory` opt-ins. Idempotent. Backs up `settings.json` before merging.
- **Companion memory template.** `templates/feedback_1pct_ship_velocity.md` ready-to-copy.
- **Baseline doc.** `evals/BASELINE.md` defines metrics, run cadence, and interpretation rules.
- **Version field** in SKILL.md frontmatter.

### Changed
- SKILL.md trailer notes v3 additions and points at hooks/evals.

## [2.0.0] — 2026-04-14 — Doctrine + scope + deviation path

### Changed
- Reframed from "override" to "doctrine" — opens with Auftragstaktik (commander's intent) and OODA ("you are already Oriented"). Council found v1's rule-list framing brittle (whack-a-mole risk) — doctrine generalizes better.
- Replaced `>1 question mark` rule with `>1 distinct decision point`. Punctuation count ≠ decision count.
- Replaced vague "irreversible on shared state" fence with the **one-way door** test (Bezos): "if you cannot reverse this within 5 minutes, confirm."
- Split warnings into **Stop signs** (always confirm) vs **Speed bumps** (never surface as question).

### Added
- **"Productivity override, not safety override"** disclaimer at top — Grok 4 refused v1 as a suspected jailbreak; this is the fix.
- **"What is a 1% move?"** definition (DeepSeek-R1).
- **Scope of approval** with explicit expiration rules — new top-level question, plan modification, falsified assumption, >1 day idle (GPT-5.1).
- **Silent pre-send self-audit** — 6-item checklist replacing flat phrase-bans (council consensus: behavior-level beats phrase-level).
- **Mid-execution deviation path** — `Deviation: using B instead of A because X. Continuing.` (council consensus).
- **Rationalization table** — added "Legitimate alternative" column so the boundary is visible (was all-negative in v1).
- **Worked examples** — 5 BAD/GOOD pairs including legitimate clarification (rare but real).
- **Evaluation metrics** — 5 measurable signals (mid-flow question rate, false-pause rate, false-override rate, omission harm, frustration-regex fire). Metrics defined; not yet automated (v3 adds the harness).
- **Delegate-don't-ask rule** + **Rejection-as-signal rule** (from claude-code issue #22557 root cause).
- `RESEARCH.md` with full source trail across deep research, council critique, last-30-days trend scan.

## [1.0.0] — 2026-04-14 — Initial publication

- Original SKILL.md: "override" framing with rationalization table, red flags, and output-shape examples.
- Born from a single session's frustration with Claude pausing for permission at phase boundaries already approved by the documented skill flow.
