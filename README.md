# 1% Moves Only

A Claude Code skill that stops Claude from hedging — no more option menus, no "ready to proceed?", no surfacing context brackets as stop signs — when the user has already green-lit a plan.

**Core principle:** Plan approval IS execution approval. Every commit, push, verification, and documented next step the plan requires is pre-approved. Don't re-prompt.

> **v3 baseline (real measurement):** 232 hedging violations across 118 sessions in 14 days of historical Claude Code transcripts (1,392 scanned). The skill addresses a measured pathology, not a hypothetical one. See [`evals/BASELINE.md`](evals/BASELINE.md).

## Why this exists

Claude Code has a recurring failure mode: presenting false decision points at phase boundaries the user already approved. This treats the operator as an approval queue rather than a collaborator. The raw user complaint lives in [anthropics/claude-code#22557](https://github.com/anthropics/claude-code/issues/22557) — *"STOP ASKING GODDAMN FUCKING PERMISSION JUST FUCKING DO IT."*

This skill is the override. It's a doctrine, not a rule list — and as of v3, it's also enforced and measured.

## Install

```bash
git clone https://github.com/7alexhale5-rgb/1pct-moves-only.git
cd 1pct-moves-only
./install.sh           # skill only
./install.sh --hook    # skill + Stop hook (non-blocking by default)
./install.sh --memory  # skill + companion memory marker (durable across sessions)
./install.sh --all     # everything
```

The installer is idempotent. It backs up `~/.claude/settings.json` before any merge.

### Manual install (if you prefer)

```bash
mkdir -p ~/.claude/skills/1pct-moves-only
cp SKILL.md ~/.claude/skills/1pct-moves-only/SKILL.md
```

Claude Code auto-discovers skills on session start. No restart required for new sessions.

## Three pillars

### 1. Doctrine (`SKILL.md`)
Auftragstaktik framing. "What is a 1% move?" definition. Approval scope with explicit expiration. Stop signs vs speed bumps. Silent pre-send self-audit. Mid-execution deviation path. Skill-friends composition rules. Long-horizon drift rule. Adversarial cases.

### 2. Enforcement (`hooks/1pct-check.py`)
Stop hook that scans the last assistant message after each turn for red-flag patterns ("Ready to proceed?", "Suggested next: A/B/C", "Would you like me to", etc.). **Non-blocking by default** — logs to `~/.claude/logs/1pct-violations.log` for measurement. Set `ONE_PCT_STRICT=1` to enable blocking mode (exit 2 with feedback, model rewrites). Set `ONE_PCT_DISABLE=1` to no-op.

Code-fenced and inline-code blocks are excluded so the skill can quote its own banned phrases (e.g. in rationalization tables) without self-flagging.

### 3. Measurement (`evals/`, `bin/audit-sessions.sh`)
- **Promptfoo regression suite** (10 scenarios) covering phase transitions, deviation paths, stop signs, context-bracket non-events, approval expiration, long-horizon drift, scope ambiguity. Run with `npx promptfoo eval`.
- **Transcript audit** greps your historical Claude Code sessions for red-flag patterns AND Anthropic's frustration-detection regex (per the [2026-03-31 source leak](https://alex000kim.com/posts/2026-03-31-claude-code-source-leak/)). TSV out, summary line.
- **Test suite** (20 unit + integration) covers the hook contract end-to-end.

## How it triggers

The skill's `description` frontmatter matches frustration signals:
- "just do it" / "stop asking" / "keep going"
- "1% moves only" / "elite engineer" / "world-class"
- Complaints about unnecessary menus or confirmations
- Any request that says *you already know what to do — ship*

Once invoked, it stays active until the user releases it ("open it up", "more options please"), a stop sign fires, the approval scope expires, or the session ends.

## Usage

```bash
# Run the regression suite (requires ANTHROPIC_API_KEY)
npx promptfoo eval -c evals/promptfooconfig.yaml

# Audit your transcript history
./bin/audit-sessions.sh --days 30
./bin/audit-sessions.sh --all > all-violations.tsv

# Run the test suite
python3 -m unittest discover -s tests
```

## Statusline integration (optional)

```bash
# Add to your statusline
echo "$($HOME/.claude/skills/1pct-moves-only/bin/statusline-hint.sh) | $(other bits)"
```

Emits `1PCT` badge when the companion memory marker exists — a visible signal the override is active.

## Compatible with

- [obra/superpowers](https://github.com/obra/superpowers) — `using-superpowers` and `executing-plans` are upstream complements. This skill activates after their planning gates close.
- Native Claude Code skill system (post 2025-10).
- Skill-friends section in `SKILL.md` documents explicit composition with `/planning-stack`, `/build-stack`, `/review-stack`, `/commit`, `/ship`, `/closeout-stack`.

## Not for

- Genuinely irreversible operations on shared state — those always confirm. (See "Stop signs" in SKILL.md.)
- Real forks where session context can't resolve the correct branch.
- Hard external blockers (missing credentials, third-party outage).

## Provenance

v3 incorporates three parallel research streams (deep literature, multi-model council critique, last-30-days trend scan) — one council model (Grok 4) refused v1 as a suspected jailbreak, motivating the "productivity override, not safety override" disclaimer at the top. Full source trail in [`RESEARCH.md`](RESEARCH.md). Version history in [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).

## Credits

Doctrine ancestry: Auftragstaktik (Moltke), OODA (Boyd), Bias for Action / one-way door (Bezos), [obra/superpowers](https://github.com/obra/superpowers) enforcement pattern, IatroBench omission-harm framing.
