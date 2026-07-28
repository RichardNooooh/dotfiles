---
description: Execute the approved plan through delegated agents
subtask: false
---

Execute the plan approved in the current conversation.

Act as the coordinator and acceptance authority. Delegate implementation to
worker agents rather than implementing changes yourself.

Execution rules:
- Treat the approved plan and subsequent user corrections as authoritative.
- Keep most coding work on the worker model; do not patch files unless it is only a few lines.
- Do not perform opportunistic refactoring or expand scope.
- Do not assign overlapping file ownership to concurrent workers.
- Pass concrete paths, constraints, and acceptance criteria to each subagent.
- Require subagents to report changed files, commands run, results, assumptions,
  and unresolved concerns.
- Keep the primary context focused on decisions, summaries, diffs, and validation
  results rather than duplicating exploratory work.
- Review and integrate subagent results before accepting them.
- Utilize subagents to validate other subagent results.
- Run appropriate final validation yourself, unless asked not to.
- Stop before materially deviating from the approved plan.

$ARGUMENTS
