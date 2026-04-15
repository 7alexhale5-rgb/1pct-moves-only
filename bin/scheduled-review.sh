#!/usr/bin/env bash
# scheduled-review.sh — one-shot 14-day post-install audit comparison.
#
# Fires from launchd (com.prettyfly.1pct-audit-review.plist) on 2026-04-28 8am CDT.
# After running, self-unloads the launchd job so it doesn't fire again next year.
#
# Outputs:
#   - Appends a "## 14-day re-audit" subsection to evals/BASELINE.md
#   - Writes raw TSV to ~/.claude/logs/1pct-review-2026-04-28.tsv
#   - macOS notification with summary

set -euo pipefail

REPO="${REPO:-$HOME/Projects/1pct-moves-only}"
DATE_STAMP=$(date +%Y-%m-%d)
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/1pct-review-$DATE_STAMP.log"
TSV_FILE="$LOG_DIR/1pct-review-$DATE_STAMP.tsv"
BASELINE_MD="$REPO/evals/BASELINE.md"
PLIST="$HOME/Library/LaunchAgents/com.prettyfly.1pct-audit-review.plist"

# Hardcoded baseline numbers from 2026-04-14 v3 ship
BASELINE_SESSIONS=1392
BASELINE_RED=232
BASELINE_FRUST=81
BASELINE_VIOLATING=118
BASELINE_DATE="2026-04-14"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1
echo
echo "=== $(date) — scheduled review run ==="

if [[ ! -x "$REPO/bin/audit-sessions.sh" ]]; then
  echo "ERROR: audit script not found at $REPO/bin/audit-sessions.sh"
  osascript -e 'display notification "1pct-moves-only audit: script missing — see ~/.claude/logs" with title "1pct review FAILED"'
  exit 1
fi

# Run the audit
"$REPO/bin/audit-sessions.sh" --days 14 > "$TSV_FILE" 2> "$TSV_FILE.summary"
NEW_SESSIONS=$(grep -oE '[0-9]+ sessions scanned' "$TSV_FILE.summary" | grep -oE '[0-9]+' || echo 0)
NEW_RED=$(grep -oE '[0-9]+ red-flag hits' "$TSV_FILE.summary" | grep -oE '[0-9]+' || echo 0)
NEW_FRUST=$(grep -oE '[0-9]+ frustration hits' "$TSV_FILE.summary" | grep -oE '[0-9]+' || echo 0)
NEW_VIOLATING=$(tail -n +2 "$TSV_FILE" | grep -c . || echo 0)

# Compute deltas
delta_red=$(( NEW_RED - BASELINE_RED ))
delta_frust=$(( NEW_FRUST - BASELINE_FRUST ))

if [[ $NEW_SESSIONS -gt 0 ]]; then
  new_red_rate=$(awk "BEGIN { printf \"%.3f\", $NEW_RED / $NEW_SESSIONS }")
  baseline_red_rate=$(awk "BEGIN { printf \"%.3f\", $BASELINE_RED / $BASELINE_SESSIONS }")
else
  new_red_rate="0.000"
  baseline_red_rate=$(awk "BEGIN { printf \"%.3f\", $BASELINE_RED / $BASELINE_SESSIONS }")
fi

# Verdict
if [[ $delta_red -lt 0 ]]; then
  verdict="✅ IMPROVED — red-flag hits down $((delta_red * -1))"
elif [[ $delta_red -eq 0 ]]; then
  verdict="➖ FLAT — no change in red-flag hits"
else
  verdict="⚠️  WORSE — red-flag hits up $delta_red"
fi

# Append delta block to BASELINE.md
cat >> "$BASELINE_MD" <<EOF

## 14-day re-audit ($DATE_STAMP)

$verdict

| Metric | Baseline ($BASELINE_DATE) | Re-audit ($DATE_STAMP) | Delta |
|---|---|---|---|
| Sessions scanned | $BASELINE_SESSIONS | $NEW_SESSIONS | $((NEW_SESSIONS - BASELINE_SESSIONS)) |
| Red-flag hits | $BASELINE_RED | $NEW_RED | $delta_red |
| Frustration hits | $BASELINE_FRUST | $NEW_FRUST | $delta_frust |
| Violating sessions | $BASELINE_VIOLATING | $NEW_VIOLATING | $((NEW_VIOLATING - BASELINE_VIOLATING)) |
| Red-flag rate (per session) | $baseline_red_rate | $new_red_rate | — |

Hook captures during this window: \`wc -l $HOME/.claude/logs/1pct-violations.log\` if present.
Raw TSV: \`$TSV_FILE\`
EOF

# Notify
osascript -e "display notification \"$verdict (red Δ$delta_red, frust Δ$delta_frust)\" with title \"1pct-moves-only review\" subtitle \"BASELINE.md updated\"" || true

echo "--- delta written to $BASELINE_MD ---"
echo "verdict: $verdict"

# Self-disable so this doesn't fire next year
if [[ -f "$PLIST" ]]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  mv "$PLIST" "$PLIST.fired-$DATE_STAMP"
  echo "--- self-disabled launchd job (renamed plist) ---"
fi

exit 0
