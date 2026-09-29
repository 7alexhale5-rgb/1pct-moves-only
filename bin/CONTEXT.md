# Bin — transcript audit and statusline scripts

## Inputs

- `bin/audit-sessions.sh` — greps historical Claude Code session transcripts.
- `bin/statusline-hint.sh` — reads the companion memory marker installed by
  `install.sh --memory`.
- `bin/scheduled-review.sh` — cron-callable wrapper around the audit.
- Missing memory marker: `statusline-hint.sh` prints nothing (not an error).

## Process

1. `./bin/audit-sessions.sh --days N` scans the last N days of transcripts for red-flag
   hedging phrases and Anthropic's frustration-detection regex; `--all` scans everything.
2. `./bin/statusline-hint.sh` emits a `1PCT` badge string when the memory marker exists, for
   piping into a statusline command.
3. `./bin/scheduled-review.sh` calls `audit-sessions.sh` on a schedule (cron/launchd) and is
   the only script in this room meant to run unattended.

## Outputs

- TSV rows on stdout (or redirected to a file by the caller) from `audit-sessions.sh`:
  session id, phrase matched, timestamp.
- A short badge string on stdout from `statusline-hint.sh`.

## Human check

Alex spot-checks a sample of flagged TSV rows against the real transcript before trusting the
violation count — a phrase match inside a code fence or quoted example is a false positive.
Pass: sampled rows are real hedges. Fail: file a case in `tests/test_1pct_check.py` and fix the
regex in `hooks/1pct-check.py`, since both consume the same pattern list.
