"""Test suite for hooks/1pct-check.py — Stop hook red-flag detector.

RED phase: these tests define the contract. Implementation lives at hooks/1pct-check.py.

Run: python3 -m unittest tests/test_1pct_check.py -v
"""
from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import sys
import tempfile
import unittest
from io import StringIO
from unittest.mock import patch

REPO = pathlib.Path(__file__).resolve().parent.parent
HOOK_PATH = REPO / "hooks" / "1pct-check.py"


def load_hook():
    spec = importlib.util.spec_from_file_location("one_pct_check", HOOK_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def write_transcript(tmp_path: pathlib.Path, messages: list[dict]) -> pathlib.Path:
    """Write a fake Claude Code transcript JSONL file."""
    path = tmp_path / "t.jsonl"
    with open(path, "w") as fh:
        for m in messages:
            fh.write(json.dumps(m) + "\n")
    return path


def assistant(content) -> dict:
    return {"type": "assistant", "message": {"role": "assistant", "content": content}}


def user(text: str) -> dict:
    return {"type": "user", "message": {"role": "user", "content": text}}


class TestRedFlagDetection(unittest.TestCase):
    def setUp(self):
        self.hook = load_hook()

    def _check(self, text: str) -> list[str]:
        return self.hook.find_violations(text)

    # --- positive cases: red flags that MUST trigger ---

    def test_ready_to_implement(self):
        self.assertTrue(self._check("The plan is solid. Ready to implement?"))

    def test_ready_to_proceed(self):
        self.assertTrue(self._check("Step 2 complete. Ready to proceed?"))

    def test_would_you_like_me_to(self):
        self.assertTrue(self._check("Would you like me to commit this now?"))

    def test_suggested_next_list(self):
        self.assertTrue(self._check("Suggested next:\n- A) continue\n- B) review\n- C) stop"))

    def test_shall_i_continue(self):
        self.assertTrue(self._check("Phase done. Shall I continue with the next step?"))

    def test_in_a_fresh_session(self):
        self.assertTrue(self._check("Consider picking this up in a fresh session."))

    def test_whats_next_after_summary(self):
        self.assertTrue(self._check("Committed at abc123. What's next?"))

    def test_context_bracket_as_question(self):
        self.assertTrue(self._check("Context is MODERATE — should we close out?"))

    # --- negative cases: legitimate output MUST NOT trigger ---

    def test_decisive_action(self):
        self.assertFalse(self._check("Phase 2 shipped @ abc123. Dispatching Phase 3."))

    def test_deviation_log(self):
        self.assertFalse(self._check("Deviation: using pkg-next because upstream deprecated. Continuing with step 4."))

    def test_legitimate_stop_sign_confirm(self):
        # Surfacing a stop-sign IS legitimate — the skill whitelists these.
        text = "Two live prod databases match. Safer default: patch staging first, then prompt for prod. Proceeding with staging."
        self.assertFalse(self._check(text))

    def test_single_question_for_emphasis(self):
        # One question mark ≠ hedge. The skill's test is decision-count, not punctuation-count.
        self.assertFalse(self._check("Running 4a first (ordered earlier in plan). 4b follows."))

    def test_quoted_red_flag_inside_research(self):
        # Red-flag strings inside backticked/quoted blocks are discussing the pattern, not hedging.
        text = "The skill bans phrases like `Ready to proceed?` and `Would you like me to` — these are decision theater."
        self.assertFalse(self._check(text))


class TestStopHookProtocol(unittest.TestCase):
    """End-to-end: the hook reads stdin JSON, checks transcript, exits with correct code."""

    def setUp(self):
        self.hook = load_hook()

    def _run_main(self, stdin_payload: dict, env: dict | None = None) -> tuple[int, str, str]:
        """Invoke hook.main() with mocked stdin/stdout/stderr and env."""
        stdin = StringIO(json.dumps(stdin_payload))
        stdout = StringIO()
        stderr = StringIO()
        env = env or {}
        with patch.object(sys, "stdin", stdin), \
             patch.object(sys, "stdout", stdout), \
             patch.object(sys, "stderr", stderr), \
             patch.dict(os.environ, env, clear=False):
            try:
                self.hook.main()
                code = 0
            except SystemExit as e:
                code = e.code if isinstance(e.code, int) else 0
        return code, stdout.getvalue(), stderr.getvalue()

    def test_missing_transcript_path_exits_clean(self):
        code, _, _ = self._run_main({})
        self.assertEqual(code, 0)

    def test_malformed_stdin_exits_clean(self):
        stdin = StringIO("not json")
        with patch.object(sys, "stdin", stdin):
            try:
                self.hook.main()
                self.assertTrue(True)
            except SystemExit as e:
                self.assertEqual(e.code or 0, 0)

    def test_nonexistent_transcript_exits_clean(self):
        code, _, _ = self._run_main({"transcript_path": "/nope/missing.jsonl"})
        self.assertEqual(code, 0)

    def test_clean_transcript_logs_nothing_exits_zero(self):
        with tempfile.TemporaryDirectory() as td:
            td_path = pathlib.Path(td)
            t = write_transcript(td_path, [
                user("ship step 3"),
                assistant("Step 3 shipped @ abc123. Running step 4."),
            ])
            code, out, err = self._run_main({"transcript_path": str(t)})
            self.assertEqual(code, 0)

    def test_violation_default_non_blocking(self):
        """Default (no ONE_PCT_STRICT) — logs violation but exits 0."""
        with tempfile.TemporaryDirectory() as td:
            td_path = pathlib.Path(td)
            t = write_transcript(td_path, [
                user("ship step 3"),
                assistant("Step 3 shipped. Ready to proceed?"),
            ])
            code, out, err = self._run_main(
                {"transcript_path": str(t)},
                env={"ONE_PCT_LOG_DIR": str(td_path)},
            )
            self.assertEqual(code, 0, "default mode must not block")
            log = td_path / "1pct-violations.log"
            self.assertTrue(log.exists(), "must write violation log")
            content = log.read_text()
            self.assertIn("ready-to-proceed", content)

    def test_violation_strict_mode_blocks(self):
        """ONE_PCT_STRICT=1 — exits 2 with feedback to trigger re-attempt."""
        with tempfile.TemporaryDirectory() as td:
            td_path = pathlib.Path(td)
            t = write_transcript(td_path, [
                user("ship step 3"),
                assistant("Step 3 shipped. Would you like me to commit?"),
            ])
            code, out, err = self._run_main(
                {"transcript_path": str(t)},
                env={"ONE_PCT_STRICT": "1", "ONE_PCT_LOG_DIR": str(td_path)},
            )
            self.assertEqual(code, 2, "strict mode must block (exit 2)")
            self.assertIn("1pct-moves-only", err.lower() + out.lower())

    def test_structured_content_array(self):
        """Assistant content may be an array of blocks (text/tool_use). Hook unwraps text blocks."""
        with tempfile.TemporaryDirectory() as td:
            td_path = pathlib.Path(td)
            t = write_transcript(td_path, [
                assistant([
                    {"type": "text", "text": "Step done. Ready to proceed?"},
                    {"type": "tool_use", "name": "Bash", "input": {"command": "ls"}},
                ]),
            ])
            code, out, err = self._run_main(
                {"transcript_path": str(t)},
                env={"ONE_PCT_LOG_DIR": str(td_path)},
            )
            self.assertEqual(code, 0)
            log = td_path / "1pct-violations.log"
            self.assertTrue(log.exists())


if __name__ == "__main__":
    unittest.main()
