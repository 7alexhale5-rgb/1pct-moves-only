# Tests — the hook contract, end to end

## Inputs

- `tests/test_1pct_check.py` — 20 unit + integration cases.
- `hooks/1pct-check.py` — the system under test.

## Process

1. `python3 -m unittest discover -s tests` runs every case against the hook's actual scan
   function, not a mock.
2. A new red-flag pattern, a new code-fence edge case, or a strict/non-blocking mode change
   gets its own test added here before `hooks/1pct-check.py` is edited.

## Outputs

- unittest's console pass/fail report. No file artifact — this room has no persisted output.

## Human check

Alex requires a green `python3 -m unittest discover -s tests` run before recommending
`install.sh --hook` to a new session or merging a change to `hooks/1pct-check.py`. A red run
blocks the change; it is never worked around by disabling a test.
