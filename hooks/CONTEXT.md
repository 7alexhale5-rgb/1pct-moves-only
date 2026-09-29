# Hooks — the Stop-hook enforcement engine

## Inputs

- `hooks/1pct-check.py` — scans the last assistant message after each turn for red-flag
  hedging phrases ("Ready to proceed?", "Suggested next: A/B/C", "Would you like me to").
- `hooks/settings.json.example` — the merge template `install.sh --hook` writes into
  `~/.claude/settings.json` (installer backs up the existing file first).
- Env switches read at hook runtime: `ONE_PCT_STRICT=1` (blocking, exit 2 with feedback),
  `ONE_PCT_DISABLE=1` (no-op). Neither set: non-blocking, log-only.
- Missing transcript / no assistant message yet: the hook is a no-op for that turn.

## Process

1. `install.sh --hook` merges `hooks/settings.json.example` into `~/.claude/settings.json`.
2. On the Stop event, `1pct-check.py` reads the last assistant message and scans for banned
   phrases, explicitly skipping code-fenced and inline-code spans so the doctrine can quote its
   own banned phrases without self-flagging.
3. Default mode logs every hit and exits 0; strict mode exits 2 so Claude Code re-prompts the
   model with the violation.

## Outputs

- `~/.claude/logs/1pct-violations.log` — one line per detected violation (non-blocking mode).
- Hook exit code (0 or 2) consumed by the Claude Code Stop-hook contract directly, not a file.

## Human check

Alex reads the violation log's trend after a session where `SKILL.md` was active. Pass:
violations trend down relative to `evals/BASELINE.md`. Fail: the hook is either silent (regex
too narrow) or flagging code-fenced doctrine quotes (regex too broad) — fix in
`hooks/1pct-check.py` and add the missed case to `tests/test_1pct_check.py`.
