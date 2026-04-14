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

## Phase 1: Classify Ticket

Before any setup, classify the ticket to determine the execution mode. Mode controls which phases run and at what budget.

### Step 1 — Read the full ticket

Fetch from Jira via Atlassian MCP:
- `$TICKET_TITLE`
- `$TICKET_DESCRIPTION` (full body, not a summary)
- `$TICKET_ACCEPTANCE_CRITERIA` if present
- `$TICKET_LINKED` — count of linked/blocking tickets

### Step 2 — Codebase probe

Extract concrete nouns from the ticket: class names, service names, feature names, file paths, method names, table names. Grep the codebase for each:

```bash
grep -r "<term>" "$REPO_ROOT" --include="*.rb" --include="*.ts" --include="*.tsx" -l 2>/dev/null
```

Collect the union of all matching files. Note which domains they appear to live in (inferred from path: `app/graphql/`, `app/services/`, `config/`, etc.).

Run all greps in parallel. Cap at 10 terms — pick the most specific nouns first.

### Step 3 — Judgment call

With the ticket content and probe results, reason through:

- **File count**: how many unique files did the probe surface? (proxy for blast radius)
- **Domain spread**: do the files span 1 domain or multiple?
- **Root cause depth**: does the description suggest a surface fix (wrong label, copy change) or a systemic one (timeout, data model, auth flow)?
- **Linked tickets**: 3+ linked tickets suggests broader impact

Classify as:

**FAST** — surface change, ≤ 2 files, single domain, no systemic root cause
> Examples: wrong label, missing translation, config value tweak, copy change

**FULL** — any of: 5+ files probed, 2+ domains, systemic root cause, 3+ linked tickets
> Examples: performance fix, auth flow change, schema migration, cross-service integration

**STANDARD** — everything else

### Step 4 — Show classification and confirm

Always show the classification before proceeding:

```
Classification: standard
Rationale: Bug in search pagination — probe found SearchController,
SearchService, and 2 view files (4 files, single domain). Isolated fix,
no infrastructure signals.

Override? (fast / standard / full)  or press enter to accept
```

Wait for response. Accept the user's override if given. Set `$MODE` and proceed.

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

## Phase 2: Researcher (Foreground)

Skip if `$MODE = fast`.

Compute base paths first:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_PARENT=$(dirname "$REPO_ROOT")
RESEARCH_BASE="$REPO_PARENT/zipline-research"
```

Read `~/.claude/skills/dev/researcher-prompt.md` and spawn an Agent **synchronously** (no `run_in_background`) with:
- Full contents of `researcher-prompt.md` as instructions
- `$TICKET_ID`, `$TICKET_TITLE`, `$TICKET_DESCRIPTION` from Jira
- `$RESEARCH_BASE` path
- `$REPO_ROOT` (main repo, not worktree — worktree doesn't exist yet)
- `$MODE`

Wait for the researcher to complete and write `<!-- status: ready -->` to `findings.md` before proceeding.

---

## Phase 3: Plan Mode

### Fast mode — one-line confirm

State exactly what you will do and where:
> "Going to [change] in [file]. Proceed?"

Wait for confirmation. On yes, go directly to Phase 5 (no worktree).

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
   (cd "$REPO_ROOT" && bin/wt new "<branch-name>" >/dev/null 2>&1) &
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

If `TICKET_CONTEXT.md` already has a `## Plan` section, skip Phase 2 and 3. Instead:

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

## Phase 4: Worktree Setup

By the time plan is approved, the worktree should already be ready (it was started in background during Phase 3). Get the path — `bin/wt new` is idempotent and returns the existing path if the branch already has a worktree:

```bash
WORKTREE_PATH=$(cd "$REPO_ROOT" && bin/wt new "<branch-name>")
```

Then create `TICKET_CONTEXT.md` in the worktree root with the approved plan as its content.

Tell the user: "Worktree ready at `<WORKTREE_PATH>`. Starting ZIP-XXXX."

### Worktree path convention

All file reads/writes and git commands use `$WORKTREE_PATH`:
- Files: `$WORKTREE_PATH/app/models/user.rb`
- Git: `git -C "$WORKTREE_PATH" <command>`

---

## Phase 5: Build

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

## Phase 6: Push Gate

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

Read `~/.claude/skills/dev/tester-prompt.md`. Spawn an Agent with:
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

Read `~/.claude/skills/dev/reviewer-prompt.md`. Spawn an Agent with:
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

### C. Push and PR

```bash
# worktree (standard / full)
git -C "$WORKTREE_PATH" push -u origin HEAD

# fast (main repo)
git push -u origin HEAD
```

After pushing, invoke the `/create-pull-request` skill **without** `--ready`. PRs opened from `/dev` are always draft — never pass `--ready` unless the user explicitly requests it.

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
## Worktree: <absolute path from bin/wt>
## Mode: fast | standard | full

## Plan
<paste approved plan from Phase 3 here>

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
