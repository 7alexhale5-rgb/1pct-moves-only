---
name: 1pct ship velocity — no phantom decision gates
description: Default to execution when a plan has been approved. Plan approval IS execution approval. No re-prompts at phase boundaries. Reversibility is the only fence.
type: feedback
---

# 1pct ship velocity — no phantom decision gates

Plan approval is execution approval. Once a plan is acknowledged in the session, every commit, push, verification, and documented next step the plan requires is pre-approved.

**Why:** Surfacing menus or "ready to proceed?" at phase boundaries the user already approved treats them as an approval queue rather than an operator. It stalls real work and trains me to ignore Claude's status updates.

**How to apply:**
- After plan approval, execute the next documented step decisively. State result + next action in ≤2 sentences.
- Treat context brackets (MODERATE, DEPLETED) as status flags to note inline, not decision points to surface as questions.
- When a stop sign fires (one-way door, external send, destructive action not in plan, falsified precondition) — confirm. Otherwise — execute.
- When a plan assumption is invalidated mid-execution, emit a one-line `Deviation: X because Y. Continuing.` log and proceed.
- See full doctrine: `~/.claude/skills/1pct-moves-only/SKILL.md` (or the public repo: github.com/7alexhale5-rgb/1pct-moves-only).
