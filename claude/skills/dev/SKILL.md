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

## Phase 0: Classify Ticket

Before any setup, classify the ticket to determine the execution mode. Mode controls which phases run and at what budget.

Fetch `$TICKET_TYPE`, `$TICKET_TITLE`, `$TICKET_DESCRIPTION` from Jira first.

### Keyword counts

**Domain keywords** — count how many appear in title + description:
`elasticsearch`, `graphql`, `aws`, `heroku`, `search`, `deploy`, `infrastructure`, `redis`, `postgres`, `sidekiq`, `websocket`, `auth`, `billing`, `api`

**Complexity keywords** — count how many appear in title + description:
`performance`, `latency`, `upgrade`, `migration`, `timeout`, `scaling`, `N+1`, `security`, `refactor`, `rewrite`

### Classification rules

**FAST** — if ALL of:
- Type is `Chore` or `Internal`
- Zero complexity keywords in title
- Estimated scope ≤ 2 files (inferred from description)

**FULL** — if ANY of:
- Type is `Feature`
- 2+ domain keywords present
- 1+ complexity keyword present

**STANDARD** — everything else (bugs, isolated single-domain changes)

### Mode behavior

| | Fast | Standard | Full |
|---|---|---|---|
| Worktree | No | Yes | Yes |
| Researcher | Skip | Reduced budget | Full budget |
| Tester | Skip | Parallel with reviewer | Sequential first |
| Reviewer | Yes (lightweight, no worktree) | Parallel with tester | Sequential after tester |

Set `$MODE = fast | standard | full` and carry it through all phases.

**Fast path:** skip Phases 1–2. Work directly in the main repo, commit. Go straight to Phase 3 (reviewer only, no tester).

---

## Phase 1: Worktree Setup

### Compute paths

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_PARENT=$(dirname "$REPO_ROOT")
WORKTREES_ROOT="$REPO_PARENT/zipline-app-wt"
RESEARCH_BASE="$REPO_PARENT/zipline-research"
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
5. Spawn the Researcher in the background (see Phase 1.5 below).
6. Tell the user: "Worktree ready at `zipline-app-wt/zip-XXXX-<slug>`. Researcher running in background. Starting ZIP-XXXX."

### Resuming an existing worktree

When resuming, also spawn the Researcher in the background (Phase 1.5). It will pick up any new domain knowledge written since the last session and append findings.

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

---

## Phase 1.5: Spawn Researcher (Background)

Skip entirely if `$MODE = fast`.

Immediately after worktree setup (new or resumed), spawn the Researcher as a background agent.

Read `.claude/skills/dev/researcher-prompt.md` and spawn an Agent with:
- `run_in_background: true`
- Full contents of `researcher-prompt.md` as instructions
- `$TICKET_ID`, `$TICKET_TITLE`, `$TICKET_DESCRIPTION` from Jira
- `$RESEARCH_BASE` path
- `$REPO_ROOT` path (the worktree path)
- `$MODE` — researcher uses this to apply the correct budget limits

The researcher writes to `$RESEARCH_BASE/tickets/$TICKET_ID/findings.md`. It signals completion by writing `<!-- status: ready -->` as the last line.

### Consuming research before the first commit

Before writing any code, check if research is ready:

```bash
tail -1 "$RESEARCH_BASE/tickets/$TICKET_ID/findings.md" 2>/dev/null
```

- If output is `<!-- status: ready -->`: read `findings.md` and incorporate context into your approach. Add a `## Research` section to `TICKET_CONTEXT.md` pointing to the findings path.
- If not ready yet: note "Research still running — will incorporate before first commit." Check again before the first `git commit`.
- If still not ready before first commit: proceed and check again before Phase 3.

Do not block the user waiting for research. Work in parallel.

---

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

Fire before `git push` or `/create-pull-request`. Behavior varies by `$MODE`.

Collect the diff inputs once — reused by both agents:
```bash
DIFF=$(git -C "$WORKTREE_PATH" diff origin/main...HEAD)         # fast: git diff HEAD~1
FILES=$(git -C "$WORKTREE_PATH" diff origin/main...HEAD --name-only)
```

---

### FAST mode — reviewer only

Spawn the Reviewer with the diff. No tester. No worktree path needed.

Apply the same reviewer fix loop (see Full mode § Reviewer below).

---

### STANDARD mode — tester and reviewer in parallel

Spawn both agents simultaneously:

```
Tester  ──────────────────┐
                           ├── collect results
Reviewer ─────────────────┘
```

**Happy path** (tester PASS, reviewer PASS/no criticals): fix any medium/low items the user selects, then push.

**Tester FAIL:** fix failures, commit, re-run tester (up to 3 runs). Once tester passes, re-run reviewer on the updated diff before pushing.

**Reviewer BLOCK:** fix criticals, commit, re-run reviewer (up to 3 runs). Tester does not need to re-run.

---

### FULL mode — sequential (tester first, then reviewer)

#### A. Tester

Read `.claude/skills/dev/tester-prompt.md`. Spawn an Agent with:
- Full contents of `tester-prompt.md` as instructions
- `$DIFF`, `$FILES`
- `$WORKTREE_PATH` so it can run commands

The tester returns structured JSON (see `tester-prompt.md` for schema).

**If `verdict` is FAIL:**
1. Fix each failure — no user prompt, just fix it.
2. Commit: `git -C "$WORKTREE_PATH" commit -m "fix: resolve test failures"`
3. Re-run tester. Repeat up to **3 total runs**.
4. If still failing after 3 runs, halt:
   > "After 3 attempts, these test failures remain. Please review before I push:"
   > [list failures]

Update `TICKET_CONTEXT.md` with the tester result before moving on.

#### B. Reviewer

Read `.claude/skills/dev/reviewer-prompt.md`. Spawn an Agent with:
- Full contents of `reviewer-prompt.md` as instructions
- Current `$DIFF`, `$FILES` (re-collect if tester made fixes)

The reviewer returns structured JSON (see `reviewer-prompt.md` for schema).

**If `critical` is non-empty:**
1. Fix every critical issue — no user prompt.
2. Commit: `git -C "$WORKTREE_PATH" commit -m "fix: address critical review issues"`
3. Re-run reviewer. Repeat up to **3 total runs**.
4. If critical issues persist after 3 runs, halt:
   > "After 3 fix attempts, these critical issues remain. Please review before I push:"
   > [list issues with file, line, description]

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

Wait for response. Fix selected items, commit, then continue.

Update `TICKET_CONTEXT.md` with the reviewer result and resolved issues.

---

### C. Push

```bash
# worktree (standard / full)
git -C "$WORKTREE_PATH" push -u origin HEAD

# fast (main repo)
git push -u origin HEAD
```

---

## Memory Files (no ticket)

When invoked as `/dev` with no argument:
- No worktree needed — work in the main repo directory.
- Researcher is skipped (no ticket context to research).
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

## Research
Status: pending | ready | not-started
Path: ../zipline-research/tickets/ZIP-XXXX/findings.md
Key findings: —

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
