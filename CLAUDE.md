# 1% Moves Only

> Status: active | Type: skill

A Claude Code skill that stops hedging once a plan is approved — a Stop hook measures it,
promptfoo scores it against a real baseline (232 violations / 118 sessions / 14 days).

## Where to go

| Task                                                     | Go to                                | Read                              | Skills |
| -------------------------------------------------------- | ------------------------------------ | --------------------------------- | ------ |
| Change what counts as a hedge, tune blocking mode        | [hooks/CONTEXT.md](hooks/CONTEXT.md) | `hooks/1pct-check.py`, `SKILL.md` | —      |
| Measure whether hedging actually dropped                 | [evals/CONTEXT.md](evals/CONTEXT.md) | `evals/BASELINE.md`               | —      |
| Audit real transcript history, wire the statusline badge | [bin/CONTEXT.md](bin/CONTEXT.md)     | `bin/audit-sessions.sh`           | —      |
| Add or run hook contract tests                           | [tests/CONTEXT.md](tests/CONTEXT.md) | `tests/test_1pct_check.py`        | —      |

Root files that stay put: `SKILL.md` (the doctrine, installed verbatim to
`~/.claude/skills/1pct-moves-only/`), `README.md`, `CHANGELOG.md`, `RESEARCH.md`, `LICENSE`,
`install.sh`, `templates/feedback_1pct_ship_velocity.md` (single file, not a room).

## Naming

kebab-case files. Dated research stays in `RESEARCH.md`; version history in `CHANGELOG.md`.
