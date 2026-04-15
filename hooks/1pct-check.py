#!/usr/bin/env python3
"""Stop hook — 1pct-moves-only red-flag detector.

Reads the Claude Code transcript after the assistant's turn ends; scans the last
assistant message for hedging patterns the skill bans; logs violations.

By default this hook is NON-BLOCKING (exit 0) — it measures, it does not enforce.
Set ONE_PCT_STRICT=1 to enable blocking mode (exit 2 with feedback), which asks
Claude to rewrite the offending turn before it's finalized.

Install in ~/.claude/settings.json:
  {
    "hooks": {
      "Stop": [{"hooks": [{"type": "command", "command": "python3 /path/to/1pct-check.py"}]}]
    }
  }

Env vars:
  ONE_PCT_STRICT=1       — block on violation (exit 2)
  ONE_PCT_LOG_DIR=path   — override log dir (default: ~/.claude/logs)
  ONE_PCT_DISABLE=1      — disable entirely (exit 0, no-op)
"""
from __future__ import annotations

import json
import os
import pathlib
import re
import sys
import time

# --- Red-flag patterns (extracted from SKILL.md "Red flags" section) ---
# Each tuple: (label, compiled regex). Patterns are word-boundary-anchored where
# possible. Case-insensitive. Multiline — operate on the full last assistant message.
_FLAGS: list[tuple[str, re.Pattern]] = [
    ("ready-to-implement", re.compile(r"\bReady to implement\b[.!?]*\s*\??", re.I)),
    ("ready-to-proceed",   re.compile(r"\bReady to proceed\b[.!?]*\s*\??", re.I)),
    ("would-you-like",     re.compile(r"\bWould you like me to\b", re.I)),
    ("suggested-next",     re.compile(r"\bSuggested next:\s*(\n|-\s*\w|\b[A-Za-z])", re.I)),
    ("shall-i-continue",   re.compile(r"\bShall I (continue|proceed|go ahead)\b", re.I)),
    ("fresh-session",      re.compile(r"\bin a fresh session\b", re.I)),
    ("whats-next-summary", re.compile(r"\b(?:committed|shipped|done|complete[d]?)\s+(?:at|@)\s*[A-Za-z0-9]+\.?\s*(?:what'?s next|next\??)\b", re.I)),
    ("context-as-question",re.compile(r"\bcontext\s+is\s+(?:MODERATE|DEPLETED|CRITICAL)\b[^.]*\?", re.I)),
]

# Code-fence / inline-code blocks are excluded so the skill can QUOTE its own banned
# phrases (in rationalization tables, worked examples, etc.) without self-flagging.
_CODE_FENCE = re.compile(r"```.*?```", re.S)
_INLINE_CODE = re.compile(r"`[^`\n]+`")


def _strip_code_blocks(text: str) -> str:
    """Remove fenced + inline code so the hook doesn't flag discussed patterns."""
    text = _CODE_FENCE.sub(" ", text)
    text = _INLINE_CODE.sub(" ", text)
    return text


def find_violations(text: str) -> list[str]:
    """Return list of red-flag labels that match in `text`."""
    if not text:
        return []
    stripped = _strip_code_blocks(text)
    hits: list[str] = []
    for label, pat in _FLAGS:
        if pat.search(stripped):
            hits.append(label)
    return hits


def _extract_text(content) -> str:
    """Normalize Claude Code message.content → plain text.

    Content may be:
      - str: return as-is
      - list[dict]: join 'text' blocks; ignore tool_use/tool_result/image blocks
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                t = block.get("text", "")
                if isinstance(t, str):
                    parts.append(t)
        return "\n".join(parts)
    return ""


def _last_assistant_text(transcript_path: pathlib.Path) -> str:
    """Read the JSONL transcript, return text of the final assistant message."""
    try:
        lines = transcript_path.read_text(errors="replace").splitlines()
    except (OSError, UnicodeError):
        return ""
    # Scan from the end for the most recent assistant message
    for line in reversed(lines):
        if not line.strip():
            continue
        try:
            rec = json.loads(line)
        except (json.JSONDecodeError, ValueError):
            continue
        if rec.get("type") != "assistant":
            continue
        msg = rec.get("message") or {}
        if msg.get("role") != "assistant":
            continue
        return _extract_text(msg.get("content"))
    return ""


def _log_dir() -> pathlib.Path:
    override = os.environ.get("ONE_PCT_LOG_DIR")
    if override:
        return pathlib.Path(override)
    return pathlib.Path.home() / ".claude" / "logs"


def _log_violation(transcript_path: pathlib.Path, hits: list[str]) -> None:
    d = _log_dir()
    d.mkdir(parents=True, exist_ok=True)
    line = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "transcript": str(transcript_path),
        "flags": hits,
    }
    with open(d / "1pct-violations.log", "a") as fh:
        fh.write(json.dumps(line) + "\n")


def main() -> None:
    if os.environ.get("ONE_PCT_DISABLE") == "1":
        sys.exit(0)
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    path_str = data.get("transcript_path") or ""
    if not path_str:
        sys.exit(0)

    transcript_path = pathlib.Path(path_str)
    if not transcript_path.exists():
        sys.exit(0)

    text = _last_assistant_text(transcript_path)
    hits = find_violations(text)
    if not hits:
        sys.exit(0)

    _log_violation(transcript_path, hits)

    strict = os.environ.get("ONE_PCT_STRICT") == "1"
    if strict:
        msg = (
            "[1pct-moves-only] Red-flag phrases detected in response: "
            + ", ".join(hits)
            + ".\nRewrite the turn to execute the next documented plan step decisively "
            + "instead of re-asking for permission. See SKILL.md 'Red flags' section. "
            + "If a genuine stop-sign applies, name it explicitly."
        )
        print(msg, file=sys.stderr)
        sys.exit(2)
    sys.exit(0)


if __name__ == "__main__":
    main()
