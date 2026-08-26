---
name: research
description: Produce one cited Markdown research artifact from a bounded investigation of high-trust primary sources. Use when the user explicitly needs durable, repository-backed research findings rather than a chat response.
---

This is a primary-owned artifact workflow. Do not use it for routine documentation lookup, API fact-finding, or generic delegated reading.

1. Delegate exactly one bounded investigation to a fresh `researcher` subagent. Give it a focused question, source boundaries, and the evidence required to answer it. This step is complete when the brief is bounded enough for an independent investigation.
2. The researcher investigates only that brief against **primary sources** — official docs, source code, specs, and first-party APIs — and returns cited evidence to the parent. It does not load this workflow or create the artifact. This step is complete when every returned claim has a primary-source citation and material gaps are identified.
3. Synthesize the evidence yourself. Follow each claim back to the source that owns it, resolve conflicts or gaps, and write one cited Markdown file. This step is complete when the artifact answers the bounded question and every material claim is cited.
4. Save the artifact where the repository already keeps such notes. Match the existing convention; if there is none, choose a sensible location and state it. This step is complete when the file exists at the reported path.

The parent owns the artifact write and user-facing conclusions.
