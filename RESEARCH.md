# Research trail — v2 supercharge (2026-04-14)

v2 of this skill integrates three parallel research streams: a deep literature + framework scan, a multi-model council critique, and a last-30-days trend scan. Summary below; full notes live in the [memory-vault](https://github.com/7alexhale5-rgb) (private).

## Stream 1 — deep research (prompting + agentic doctrine)

- **Anthropic context engineering** ([source](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)): +54% agent-task improvement from removing contradictions. Reframed v1's "override" as a *context-coherence device*.
- **Auftragstaktik / mission-type tactics** ([Wikipedia](https://en.wikipedia.org/wiki/Mission-type_tactics)): Moltke's doctrine that only intent is centralized. Became the **Doctrine** section.
- **OODA loop** ([Schneier — Agentic AI's OODA Loop Problem](https://www.schneier.com/essays/archives/2025/10/agentic-ais-ooda-loop-problem.html)): hedging is pathological re-Orient. Became the "already Oriented" line.
- **Amazon Bias for Action / one-way doors** ([IGotAnOffer](https://igotanoffer.com/en/advice/amazon-leadership-principles)): reversibility gates the override. Replaced vague "irreversible on shared state" fence.
- **Tilo Mitra — Autonomous Mode for Superpowers** ([post](https://www.tilomitra.com/blog/autonomous-mode-superpowers)): "maybe / it depends / TBD" in a plan means it's not execution-ready. Became the plan-quality precondition.
- **obra/superpowers — executing-plans** ([SKILL.md](https://github.com/obra/superpowers/blob/main/skills/executing-plans/SKILL.md)): Critical Stop Conditions pattern. Mirrored in "Stop signs" and "Speed bumps" split.
- **anthropics/claude-code#22557** ([issue](https://github.com/anthropics/claude-code/issues/22557)): *"STOP ASKING GODDAMN FUCKING PERMISSION JUST FUCKING DO IT."* Root-cause lesson baked in as the **Rejection as signal** rule.

## Stream 2 — council critique (GPT-5.1 / Gemini 2.5 Flash / DeepSeek-R1 / Grok 4)

- **Grok 4 refused** to critique v1, flagging it as a suspected jailbreak. This motivated the "productivity override, not safety override" disclaimer at the top — cheap insurance against teammate / external-agent misreading.
- **Consensus across the 3 responders:**
  1. Phrase-banning is brittle ("whack-a-mole"). → v2 adds the **silent pre-send self-audit** (behavior-level, not phrase-level).
  2. "Plan approval = execution approval" was under-specified. → v2 adds explicit **Scope of approval** with expiration rules.
  3. `>1 question mark` rule was wrong. → v2 restates as `>1 distinct decision point`.
  4. Skill needed a mid-execution escape hatch. → v2 adds the **Deviation path**: `Deviation: using B instead of A because X. Continuing.`
  5. Missing few-shot examples. → v2 adds 5 worked examples including ambiguous continuation and legitimate clarification.
- **DeepSeek-R1's contribution:** the **"What is a 1% move?"** definition.
- **GPT-5.1's contribution:** the **approval-scope state machine** with 4 explicit expiration conditions.
- **Gemini's contribution:** the **STOP-SIGN vs SPEED-BUMP** distinction, replacing flat "red flags."

## Stream 3 — last-30-days trend scan

- **Leaked Claude Code source** ([Alex Kim, 2026-03-31](https://alex000kim.com/posts/2026-03-31-claude-code-source-leak/)): Anthropic ships a **frustration-detection regex** in production (`"so frustrating"`, `"this sucks"`, swearing). Baked into v2's **evaluation metrics** as a grep-able success signal.
- **Leaked Claude Code system prompt** ([mirror](https://github.com/asgeirtj/system_prompts_leaks/blob/main/Anthropic/claude-code.md)): Anthropic's own prompt says *"Only make changes that are directly requested or clearly necessary"* and *"Prioritize technical accuracy over validating the user's beliefs."* v2 quotes these verbatim in the top disclaimer to anchor the skill as safety-aligned.
- **Anthropic — Effective harnesses for long-running agents** ([post](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)): Claude Code P99.9 turn length doubled (25min → 45min) Oct 2025 → Jan 2026. Anthropic guidance: *"let intelligent models act intelligently, with progressively less human curation."* Top-down endorsement.
- **Claude Managed Agents** ([platform.claude.com, 2026-04-08 beta](https://platform.claude.com/docs/en/managed-agents/overview)): Anthropic's own hosted harness runs without a human to ask. v2 adds the **Managed Agents parity clause** — "if it would run unattended there, don't stop here."
- **IatroBench** ([arXiv 2604.07709](https://arxiv.org/html/2604.07709v1)): peer-reviewed evidence that **omission harm** is measurable. Over-refusal = regression. Baked into v2 Doctrine ("Omission is harm") and eval metrics.
- **Superpowers enforcement pattern** ([blog.fsck.com](https://blog.fsck.com/2025/10/09/superpowers/)): skills should enforce via hard gates, not describe via prose. v2 leans harder on enforcement — self-audit is mandatory, rationalization table now has a "legitimate alternative" column so the boundary is explicit.

## What changed v1 → v2

| v1 | v2 |
|---|---|
| "Override" framing (negative) | "Doctrine" framing (positive + Moltke) |
| "Plan approval = execution approval" (fuzzy) | Same thesis + explicit expiration rules |
| Flat red-flag list | Silent pre-send self-audit + red flags |
| `>1 question mark` | `>1 distinct decision point` |
| Vague "irreversible on shared state" | One-way-door test + stop-sign table |
| No deviation path (implicit pause) | Explicit `Deviation: ... Continuing.` |
| No eval section | 5 measurable metrics including frustration-regex |
| Generic "when this misapplies" | Plus Grok-refusal-proof top disclaimer |

## Source trail

All research and critique notes are preserved in the author's memory-vault:

- `memory-vault/research/2026-04-14-1pct-moves-only-supercharge.md` — deep research
- `memory-vault/research/2026-04-14-1pct-moves-only-council.md` — multi-model critique
- `memory-vault/research/2026-04-14-1pct-moves-only-last30days.md` — trend scan
