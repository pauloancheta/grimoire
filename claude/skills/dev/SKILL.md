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
| Researcher | Skip | Foreground, reduced budget | Foreground, full budget |
| Plan mode | One-line confirm | Lightweight (approach + files + checklist) | Full (context + approach + risks + questions + checklist) |
| Worktree | No | Yes, background during plan review | Yes, background during plan review |
| Tester | Skip | Parallel with reviewer | Sequential first |
| Reviewer | Yes (lightweight, no worktree) | Parallel with tester | Sequential after tester |

Set `$MODE = fast | standard | full` and carry it through all phases.

---

## Phase 0.5: Researcher (Foreground)

Skip if `$MODE = fast`.

Compute base paths first:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_PARENT=$(dirname "$REPO_ROOT")
RESEARCH_BASE="$REPO_PARENT/zipline-research"
```

Read `.claude/skills/dev/researcher-prompt.md` and spawn an Agent **synchronously** (no `run_in_background`) with:
- Full contents of `researcher-prompt.md` as instructions
- `$TICKET_ID`, `$TICKET_TITLE`, `$TICKET_DESCRIPTION` from Jira
- `$RESEARCH_BASE` path
- `$REPO_ROOT` (main repo, not worktree — worktree doesn't exist yet)
- `$MODE`

Wait for the researcher to complete and write `<!-- status: ready -->` to `findings.md` before proceeding.

---

## Phase 0.7: Plan Mode

### Fast mode — one-line confirm

State exactly what you will do and where:
> "Going to [change] in [file]. Proceed?"

Wait for confirmation. On yes, go directly to Phase 2 (no worktree).

---

### Standard and Full mode — structured plan

Enter plan mode (use the `EnterPlanMode` tool). In plan mode:

1. Read `$RESEARCH_BASE/tickets/$TICKET_ID/findings.md`
2. Explore 3–5 codebase files most relevant to the ticket (read only, no edits)
3. Derive the branch name from ticket type:
   - Feature → `feature/zip-XXXX-<slug>`
   - Bug → `bugfix/zip-XXXX-<slug>`
   - Internal/chore → `internal/zip-XXXX-<slug>`
   - Slug: lowercase title, spaces to hyphens, max 5 words
4. **Start worktree creation in background** while you write the plan:
   ```bash
   git worktree add "$WORKTREES_ROOT/zip-XXXX-<slug>" -b "<branch-name>" &
   ```
5. Write and present the plan to the user (format below by mode)
6. Wait for user approval or edits

On approval, exit plan mode (`ExitPlanMode` tool). Write the approved plan into `TICKET_CONTEXT.md`.

### Plan format — Standard

```markdown
## Plan: ZIP-XXXX — <title>

### Approach
<2–3 sentences on what changes and why>

### Files
- path/to/file.rb — <what changes>
- path/to/other.rb — <what changes>

### From research
- <key finding that shaped this plan>

### Checklist
- [ ] task
- [ ] task
```

### Plan format — Full

```markdown
## Plan: ZIP-XXXX — <title>

### Context
<key findings from researcher that shaped this approach — 3–5 bullets>

### Approach
<paragraph explaining the implementation strategy>

### Files
- path/to/file.rb — <what changes and why>

### Risks
- <risk and mitigation>

### Open questions
<questions for the user before building, if any — omit section if none>

### Checklist
- [ ] task
- [ ] task
```

### Resuming a ticket

If `TICKET_CONTEXT.md` already has a `## Plan` section, skip Phase 0.5 and 0.7. Instead:

1. Read `TICKET_CONTEXT.md`
2. Run git status in parallel:
   ```bash
   git -C "$WORKTREE_PATH" log origin/main..HEAD --oneline
   git -C "$WORKTREE_PATH" diff origin/main...HEAD --stat
   git -C "$WORKTREE_PATH" status --short
   ```
3. Present a one-paragraph resume summary:
   > "Resuming ZIP-XXXX. Status: [from context]. [N commits ahead]. Pending: [checklist items]. [Any unresolved review issues]."

---

## Phase 1: Worktree Setup

```bash
WORKTREES_ROOT="$REPO_PARENT/zipline-app-wt"
```

By the time plan is approved, the worktree should already be ready (it was started in background during Phase 0.7). Verify:

```bash
git worktree list --porcelain | grep "$WORKTREES_ROOT/zip-XXXX"
```

If not ready yet, wait for it to complete. Then create `TICKET_CONTEXT.md` in the worktree root with the approved plan as its content.

Tell the user: "Worktree ready at `zipline-app-wt/zip-XXXX-<slug>`. Starting ZIP-XXXX."

### Worktree path convention

All file reads/writes and git commands use `$WORKTREE_PATH`:
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
## Mode: fast | standard | full

## Plan
<paste approved plan from Phase 0.7 here>

## Research
Path: ../zipline-research/tickets/ZIP-XXXX/findings.md

## Checklist
- [ ] item  ← copied from plan and updated as work progresses
- [ ] item

## Decisions
- <decision and rationale made during build, beyond the plan>

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
