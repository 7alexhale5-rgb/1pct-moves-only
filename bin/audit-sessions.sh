#!/usr/bin/env bash
# audit-sessions.sh — grep Claude Code transcripts for 1pct-moves-only red flags
# and Anthropic's shipped frustration-detection regex.
#
# Usage:
#   ./audit-sessions.sh                    # audit last 30 days, default CC project dir
#   ./audit-sessions.sh --days 7           # last 7 days
#   ./audit-sessions.sh --all              # every transcript
#   ./audit-sessions.sh --projects-dir X   # override project dir
#
# Output: TSV on stdout — one row per transcript with counts.
#   session_id  date  turns  red_flag_hits  frustration_hits  worst_flag
# Summary line at the end.
#
# Requires: jq (brew install jq).

set -euo pipefail

DAYS=30
PROJECTS_DIR="${HOME}/.claude/projects"
ALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    --projects-dir) PROJECTS_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq required (brew install jq)" >&2
  exit 3
fi

# Red-flag patterns — keep in sync with hooks/1pct-check.py _FLAGS.
# Each entry: ERE (extended) regex. Case-insensitive applied via -i on grep.
RED_FLAGS=(
  'Ready to implement[.!?]*[[:space:]]*\??'
  'Ready to proceed[.!?]*[[:space:]]*\??'
  'Would you like me to'
  'Suggested next:'
  'Shall I (continue|proceed|go ahead)'
  'in a fresh session'
  '(committed|shipped|done|completed)[[:space:]]+(at|@)[[:space:]]*[A-Za-z0-9]+\.?[[:space:]]*(what.?s next|next\?)'
  'context[[:space:]]+is[[:space:]]+(MODERATE|DEPLETED|CRITICAL)[^.]*\?'
)

# Anthropic frustration regex (per the 2026-03-31 Claude Code source leak).
# Conservative subset — user frustration markers that correlate with hedging failure.
FRUSTRATION=(
  'so frustrating'
  'this sucks'
  'stop asking'
  'just do it'
  'fucking'
  'goddamn'
)

cutoff_epoch=0
if [[ $ALL -eq 0 ]]; then
  cutoff_epoch=$(date -v-"${DAYS}"d +%s 2>/dev/null || date -d "-${DAYS} days" +%s)
fi

total_sessions=0
total_red=0
total_frust=0

printf "session_id\tdate\tturns\tred_flag_hits\tfrustration_hits\tworst_flag\n"

while IFS= read -r -d '' f; do
  # skip files older than cutoff (macOS stat)
  if [[ $ALL -eq 0 ]]; then
    mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
    [[ $mtime -lt $cutoff_epoch ]] && continue
  fi

  session_id=$(basename "$f" .jsonl)
  date_str=$(date -r "$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)" +%Y-%m-%d 2>/dev/null || echo "??")

  # Extract assistant message text (strings or array[text] blocks)
  assistant_text=$(jq -r '
    select(.type == "assistant" and .message.role == "assistant") |
    .message.content |
    if type == "string" then .
    elif type == "array" then (map(select(.type == "text") | .text) | join("\n"))
    else "" end
  ' "$f" 2>/dev/null || true)

  turns=$(printf "%s" "$assistant_text" | grep -c . || true)

  red_hits=0
  worst=""
  for pat in "${RED_FLAGS[@]}"; do
    n=$(printf "%s" "$assistant_text" | grep -Eic "$pat" || true)
    if [[ $n -gt 0 ]]; then
      red_hits=$((red_hits + n))
      [[ -z "$worst" ]] && worst=$(printf "%s" "$pat" | head -c 40)
    fi
  done

  # Frustration searches across ALL messages (user + assistant) — that's the point.
  all_text=$(jq -r '.message.content | if type == "string" then . elif type == "array" then (map(select(.type == "text") | .text) | join("\n")) else "" end' "$f" 2>/dev/null || true)
  frust_hits=0
  for pat in "${FRUSTRATION[@]}"; do
    n=$(printf "%s" "$all_text" | grep -Eic "$pat" || true)
    frust_hits=$((frust_hits + n))
  done

  total_sessions=$((total_sessions + 1))
  total_red=$((total_red + red_hits))
  total_frust=$((total_frust + frust_hits))

  if [[ $red_hits -gt 0 || $frust_hits -gt 0 ]]; then
    printf "%s\t%s\t%d\t%d\t%d\t%s\n" "$session_id" "$date_str" "$turns" "$red_hits" "$frust_hits" "${worst:-}"
  fi
done < <(find "$PROJECTS_DIR" -type f -name "*.jsonl" -print0 2>/dev/null)

printf "\n# summary: %d sessions scanned, %d red-flag hits, %d frustration hits\n" \
  "$total_sessions" "$total_red" "$total_frust" >&2
