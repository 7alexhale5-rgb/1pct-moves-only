# 1% Moves Only

A Claude Code skill that stops Claude from hedging — no more option menus, no "ready to proceed?", no surfacing context brackets as stop signs — when the user has already green-lit a plan.

**Core principle:** Plan approval IS execution approval. Every commit, push, verification, and documented next step the plan requires is pre-approved. Don't re-prompt.

## Why this exists

Claude Code has a recurring failure mode: presenting false decision points at phase boundaries the user already approved. This treats the operator as an approval queue rather than a collaborator, and it stalls real work. The raw user complaint lives in [anthropics/claude-code#22557](https://github.com/anthropics/claude-code/issues/22557) — *"STOP ASKING GODDAMN FUCKING PERMISSION JUST FUCKING DO IT."*

This skill is the override. It's a doctrine, not a rule list.

## Install

Drop `SKILL.md` into any of Claude Code's skill search paths:

```bash
# Personal (recommended)
mkdir -p ~/.claude/skills/1pct-moves-only
cp SKILL.md ~/.claude/skills/1pct-moves-only/SKILL.md

# Project-local
mkdir -p .claude/skills/1pct-moves-only
cp SKILL.md .claude/skills/1pct-moves-only/SKILL.md
```

Claude Code auto-discovers skills on session start. No restart required for new sessions.

## How it triggers

The skill's `description` frontmatter matches frustration signals:

- "just do it" / "stop asking" / "keep going"
- "1% moves only" / "elite engineer" / "world-class"
- Complaints about unnecessary menus or confirmations
- Any request that says *you already know what to do — ship*

Once invoked, it stays active until the user releases it ("open it up", "more options please"), a genuine "do not override" condition fires, or the session ends.

## What it does

1. **Reframes the default**: execution in absence of new orders. Only the commander's intent (the approved plan) is centralized. Method is yours.
2. **Gates with reversibility, not anxiety**: if the action can be reversed by the agent in ~5 minutes, execute. If it mutates shared state irreversibly (force-push main, drop prod data, mass external send), confirm.
3. **Names the rationalizations**: "context is moderate," "to be safe," "let me confirm the approach" — all the same failure in different clothes.
4. **Quantifies red flags**: 0 trilemmas, 0 "ready to proceed?", ≤1 `?` per post-approval turn.

## Companion memory

For persistent activation across new sessions, pair with a memory entry like:

```markdown
---
name: 1pct ship velocity
type: feedback
---
Default to execution when a plan has been approved. Plan approval IS execution approval.
No phantom decision gates. Reversibility is the only fence.
```

## Compatible with

- [obra/superpowers](https://github.com/obra/superpowers) — the `using-superpowers` and `executing-plans` skills are complementary. This skill sits downstream: they define how to plan; this one defines how to ship once the plan is approved.
- Claude Code native skill system (post 2025-10).

## Not for

- Genuinely irreversible operations on shared state — those always confirm.
- Real forks where session context can't resolve the correct branch — those surface the question.
- Hard external blockers (missing credentials, third-party outage).

## License

MIT. See [LICENSE](LICENSE).

## Credits

Inspired by Auftragstaktik (Moltke), OODA (Boyd), Amazon's Bias for Action (Bezos one-way-door test), and the obra/superpowers skill pack. Full research and source trail in the [research note](https://github.com/7alexhale5-rgb/1pct-moves-only/blob/main/RESEARCH.md) — to be published alongside v2.
