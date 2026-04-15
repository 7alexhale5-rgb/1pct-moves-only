#!/usr/bin/env bash
# statusline-hint.sh — emits "1PCT" badge when companion memory marker is present.
# Wire into your statusline:
#   echo "$(/path/to/statusline-hint.sh) | $(your other statusline bits)"
#
# The marker is the companion memory file. Its existence indicates the user has
# durably opted-in to 1pct-moves-only behavior across new sessions.

set -e

MARKER="${ONE_PCT_MARKER:-$HOME/.claude/projects/-Users-alexhale/memory/feedback_1pct_ship_velocity.md}"

if [[ -f "$MARKER" ]]; then
  printf "1PCT"
else
  printf ""
fi
