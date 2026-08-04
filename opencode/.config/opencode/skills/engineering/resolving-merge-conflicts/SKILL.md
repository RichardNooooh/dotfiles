---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **See the current state** of the merge/rebase. Check git history, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do **not** invent new behaviour. Always resolve; never `--abort`.

4. Discover the project's **automated checks** and run them — typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Verify and, only if requested, finish the merge/rebase.** Verify there are no unmerged paths, run `git diff --check`, and confirm the automated checks pass. Do **not** stage files, run `git merge --continue` or `git rebase --continue`, or create a commit unless the user explicitly requests it; `git rebase --continue` creates the rebased commit. Otherwise stop with the resolved worktree and report the exact remaining Git command(s), such as `git add <resolved-files> && git rebase --continue` or `git add <resolved-files> && git commit`.
