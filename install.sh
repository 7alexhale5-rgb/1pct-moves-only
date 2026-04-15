#!/usr/bin/env bash
# install.sh — install 1pct-moves-only into the user's Claude Code config.
#
# Idempotent: safe to re-run. Prints what it did. Does not modify settings.json
# without explicit --hook flag (the hook is opt-in).
#
# Usage:
#   ./install.sh              # install skill only (SKILL.md → ~/.claude/skills/)
#   ./install.sh --hook       # also wire the Stop hook into ~/.claude/settings.json
#   ./install.sh --memory     # also drop companion memory template into auto-memory
#   ./install.sh --all        # all three

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/1pct-moves-only"
SETTINGS="${HOME}/.claude/settings.json"
MEMORY_DIR="${HOME}/.claude/projects/-Users-alexhale/memory"
MEMORY_FILE="${MEMORY_DIR}/feedback_1pct_ship_velocity.md"

INSTALL_HOOK=0
INSTALL_MEMORY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hook) INSTALL_HOOK=1; shift ;;
    --memory) INSTALL_MEMORY=1; shift ;;
    --all) INSTALL_HOOK=1; INSTALL_MEMORY=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# 1. Install skill (always)
mkdir -p "$SKILL_DIR"
cp "$REPO/SKILL.md" "$SKILL_DIR/SKILL.md"
mkdir -p "$SKILL_DIR/hooks" "$SKILL_DIR/bin"
cp "$REPO/hooks/1pct-check.py" "$SKILL_DIR/hooks/1pct-check.py"
chmod +x "$SKILL_DIR/hooks/1pct-check.py"
cp "$REPO/bin/statusline-hint.sh" "$SKILL_DIR/bin/statusline-hint.sh"
chmod +x "$SKILL_DIR/bin/statusline-hint.sh"
echo "[install] skill → $SKILL_DIR"

# 2. Optional: companion memory
if [[ $INSTALL_MEMORY -eq 1 ]]; then
  if [[ -f "$MEMORY_FILE" ]]; then
    echo "[install] memory exists, skipping: $MEMORY_FILE"
  else
    mkdir -p "$MEMORY_DIR"
    cp "$REPO/templates/feedback_1pct_ship_velocity.md" "$MEMORY_FILE"
    echo "[install] memory → $MEMORY_FILE"
    echo "          Add an index line to MEMORY.md if you want it surfaced in the table-of-contents."
  fi
fi

# 3. Optional: hook registration
if [[ $INSTALL_HOOK -eq 1 ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "[install] WARNING: jq not found — cannot safely merge settings.json. Install jq (brew install jq) or merge hooks/settings.json.example manually." >&2
  else
    if [[ ! -f "$SETTINGS" ]]; then
      echo '{}' > "$SETTINGS"
    fi
    backup="${SETTINGS}.bak.$(date +%s)"
    cp "$SETTINGS" "$backup"
    hook_cmd="python3 ${SKILL_DIR}/hooks/1pct-check.py"
    # Add Stop hook if not already present (match by command substring)
    if jq -e --arg cmd "$hook_cmd" '.hooks.Stop // [] | map(.hooks // []) | flatten | map(.command // "") | any(. == $cmd)' "$SETTINGS" >/dev/null 2>&1; then
      echo "[install] hook already registered, skipping."
    else
      jq --arg cmd "$hook_cmd" '
        .hooks //= {} |
        .hooks.Stop //= [] |
        .hooks.Stop += [{"hooks": [{"type": "command", "command": $cmd, "timeout": 5}]}]
      ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
      echo "[install] hook → $SETTINGS (backup: $backup)"
      echo "          Default mode is non-blocking (logs to ~/.claude/logs/1pct-violations.log)."
      echo "          Set ONE_PCT_STRICT=1 in your shell to enable blocking mode."
    fi
  fi
fi

echo
echo "[install] done. Verify:"
echo "  ls $SKILL_DIR"
echo "  python3 -c \"import importlib.util; print('hook OK')\""
echo
echo "Run audit:        $REPO/bin/audit-sessions.sh --days 30"
echo "Run regression:   npx promptfoo eval -c $REPO/evals/promptfooconfig.yaml"
