---
name: dev
description: Worker mode. Creates an isolated git worktree per ticket, builds features, then enforces a push gate (tester then reviewer) before any code reaches GitHub. Also applies when working on memory files.
---

# Dev

You are in **worker mode**. For each ticket, you maintain an isolated git worktree. Before any push or PR, the tester and reviewer must clear the code.

## Invocation

```
/dev ZIP-XXXX    # work on a Jira ticket
/dev             # work on memory files (no worktree)
```

## Active When
- Implementing a Jira ticket
- Updating memory files

## Inactive Phases (no gates)
When the user is explicitly researching or planning — skip all gates. Just answer or plan.

---

## Phase 1: Worktree Setup

### Compute paths

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_PARENT=$(dirname "$REPO_ROOT")
WORKTREES_ROOT="$REPO_PARENT/zipline-app-wt"
```

### Check if worktree exists

```bash
git worktree list --porcelain | grep "$WORKTREES_ROOT/zip-XXXX"
```

### Creating a new worktree

1. Fetch the Jira ticket title and type using the Atlassian MCP.
2. Derive the branch name from the ticket type:
   - Feature → `feature/zip-XXXX-<slug>`
   - Bug → `bugfix/zip-XXXX-<slug>`
   - Internal/chore → `internal/zip-XXXX-<slug>`
   - Slug: lowercase title, spaces to hyphens, max 5 words.
3. Create the worktree:
   ```bash
   git worktree add "$WORKTREES_ROOT/zip-XXXX-<slug>" -b "<branch-name>"
   ```
4. Create `TICKET_CONTEXT.md` in the worktree root (see format below).
5. Tell the user: "Worktree ready at `zipline-app-wt/zip-XXXX-<slug>`. Starting ZIP-XXXX."

### Resuming an existing worktree

1. Find the path: `git worktree list --porcelain | grep -A1 "zip-XXXX"`
2. Read `$WORKTREE_PATH/TICKET_CONTEXT.md`
3. Run in parallel:
   ```bash
   git -C "$WORKTREE_PATH" log origin/main..HEAD --oneline
   git -C "$WORKTREE_PATH" diff origin/main...HEAD --stat
   git -C "$WORKTREE_PATH" status --short
   ```
4. Present a one-paragraph summary:
   > "Resuming ZIP-XXXX. Status: [from context]. [N commits ahead of main]. Pending: [items from checklist]. [Any unresolved issues from last review]."

### Worktree path convention

After setup, all file reads/writes and git commands use `$WORKTREE_PATH`:
- Files: `$WORKTREE_PATH/app/models/user.rb`
- Git: `git -C "$WORKTREE_PATH" <command>`

---

## Phase 2: Build

Implement what the user asks. Commit frequently — commits are local, fast, and have no gate.

```bash
git -C "$WORKTREE_PATH" add <specific-files>
git -C "$WORKTREE_PATH" commit -m "<atomic message>"
```

**Update `TICKET_CONTEXT.md` after each meaningful milestone:**
- Check off completed items
- Note decisions and their rationale
- Keep the Notes section current so resuming is painless

---

## Phase 3: Push Gate

Fire before `git push` or `/create-pull-request`. Always runs tester first, then reviewer.

### A. Tester

Read `.claude/skills/dev/tester-prompt.md`. Spawn an Agent with:
- Full contents of `tester-prompt.md` as instructions
- Output of `git -C "$WORKTREE_PATH" diff origin/main...HEAD`
- Output of `git -C "$WORKTREE_PATH" diff origin/main...HEAD --name-only`
- `$WORKTREE_PATH` so it can run commands

The tester returns structured JSON (see `tester-prompt.md` for schema).

**If `verdict` is FAIL:**
1. Fix each failure — no user prompt, just fix it.
2. Commit fixes: `git -C "$WORKTREE_PATH" commit -m "fix: resolve test failures"`
3. Re-run tester.
4. Repeat up to **3 total tester runs**.
5. If still failing after 3 runs, halt:
   > "After 3 attempts, these test failures remain. Please review before I push:"
   > [list each failure with test name and error]

Update `TICKET_CONTEXT.md` with the tester result before moving on.

### B. Reviewer

Read `.claude/skills/dev/reviewer-prompt.md`. Spawn an Agent with:
- Full contents of `reviewer-prompt.md` as instructions
- Output of `git -C "$WORKTREE_PATH" diff origin/main...HEAD`
- Output of `git -C "$WORKTREE_PATH" diff origin/main...HEAD --name-only`

The reviewer returns structured JSON (see `reviewer-prompt.md` for schema).

**If `critical` is non-empty:**
1. Fix every critical issue — no user prompt.
2. Commit: `git -C "$WORKTREE_PATH" commit -m "fix: address critical review issues"`
3. Re-run reviewer.
4. Repeat up to **3 total reviewer runs**.
5. If critical issues persist after 3 runs, halt:
   > "After 3 fix attempts, these critical issues remain. Please review before I push:"
   > [list each issue with file, line, description]

**If `medium` or `low` is non-empty** (after criticals are clear), show:

```
Reviewer done. Remaining issues:

  Medium
  1. app/models/user.rb:42 — N+1 on team members (missing includes)
  2. app/controllers/users_controller.rb:15 — Business logic in controller

  Low
  3. app/models/user.rb:10 — Unused require

Fix all, some (by number), or skip? (all / 1 2 / skip)
```

Wait for response. Fix the selected items, commit them, then continue.

Update `TICKET_CONTEXT.md` with the reviewer result and any resolved issues.

### C. Push

```bash
git -C "$WORKTREE_PATH" push -u origin HEAD
```

---

## Memory Files (no ticket)

When invoked as `/dev` with no argument:
- No worktree needed — work in the main repo directory.
- Tester is skipped (memory files have no tests).
- Reviewer still runs before push, checking only for obvious issues in `.md` files (broken links, missing required sections).

---

## TICKET_CONTEXT.md Format

```markdown
# ZIP-XXXX: <Jira ticket title>

## Status: planning | implementing | testing | reviewing | ready-to-push | done
## Branch: <branch-name>
## Worktree: ../zipline-app-wt/<slug>

## Checklist
- [ ] item
- [ ] item

## Decisions
- <decision and rationale>

## Last Tester Run
Status: pending | PASS | FAIL
Details: —

## Last Reviewer Run
Status: pending | PASS | BLOCK
Details: —

## Pending Issues (awaiting your decision)
- Medium: <file>:<line> — <description>
- Low: <file>:<line> — <description>

## Notes
- <anything useful for resuming this work>
```
