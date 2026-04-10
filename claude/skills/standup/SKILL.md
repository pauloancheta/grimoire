---
name: standup
description: Generate a daily standup from GitHub and Jira activity. Shows PRs opened/closed/reviewed, Jira ticket statuses, and currently assigned work. Output is formatted for Slack. Usage: /standup [days] where days defaults to 1 (past 24 hours), /standup 2 covers 48 hours, etc.
---

# Standup Generator

Generate a standup summary from GitHub and Jira activity, formatted for pasting directly into Slack.

## When to Use

- User runs `/standup` — cover the past 24 hours (1 day)
- User runs `/standup 2` — cover the past 48 hours (2 days)
- User runs `/standup N` — cover the past N×24 hours

## Step 1: Parse Arguments

Extract the number of days from the skill args. Default to `1` if no argument is given.

```
days = args || 1
```

Calculate the cutoff date (in the user's local timezone, America/Vancouver):

```bash
# macOS: N days ago in ISO 8601
date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ"
```

Also compute a human-readable date range label:
- If days=1: "Feb 26, 2026"
- If days>1: "Feb 24 – Feb 26, 2026"

## Step 2: Resolve User Identities

Run in parallel:

```bash
gh api user --jq '{login: .login, name: .name}'
```

```
mcp__atlassian__atlassianUserInfo   # get account_id and name
```

Known constants (use these directly, no need to look them up):
- Atlassian Cloud ID: `e011c47b-05b6-4434-bf2a-50a16ac25afa`
- GitHub org: `retailzipline`
- Main repo: `retailzipline/zipline-app`

## Step 3: Fetch GitHub Activity

Run all of these in parallel.

### 3a. User events (commits, PRs opened/closed, branch creates, comments)

```bash
gh api "users/<login>/events" --jq '
  .[] | select(.created_at >= "<cutoff>") |
  {
    type,
    repo: .repo.name,
    created_at,
    payload: (
      if .type == "PullRequestEvent" then
        {action: .payload.action, title: .payload.pull_request.title, url: .payload.pull_request.html_url, number: .payload.pull_request.number}
      elif .type == "PullRequestReviewEvent" then
        {action: .payload.action, title: .payload.pull_request.title, url: .payload.pull_request.html_url, number: .payload.pull_request.number}
      elif .type == "PullRequestReviewCommentEvent" then
        {action: .payload.action, title: .payload.pull_request.title, body: .payload.comment.body[:120]}
      elif .type == "IssueCommentEvent" then
        {action: .payload.action, title: .payload.issue.title, body: .payload.comment.body[:120], url: .payload.issue.html_url}
      elif .type == "PushEvent" then
        {ref: .payload.ref, commits: [.payload.commits[] | .message[:80]]}
      elif .type == "CreateEvent" then
        {ref_type: .payload.ref_type, ref: .payload.ref}
      else {}
      end
    )
  }
'
```

### 3b. PRs reviewed (search API)

```bash
gh api "search/issues?q=reviewed-by:<login>+updated:>$(date -u -v-${days}d +"%Y-%m-%d")&type=pr" \
  --jq '.items[] | {repo: .repository_url, title: .title, url: .html_url, number: .number}'
```

### 3c. Open PRs authored by the user

```bash
gh pr list \
  --repo retailzipline/zipline-app \
  --author <login> \
  --state open \
  --json number,title,url,isDraft,createdAt,updatedAt
```

## Step 4: Fetch Jira Activity

Run in parallel.

### 4a. Currently assigned tickets with activity in the window

```
mcp__atlassian__searchJiraIssuesUsingJql
  cloudId: "e011c47b-05b6-4434-bf2a-50a16ac25afa"
  jql: "assignee = currentUser() AND statusCategory != Done AND updated >= -${days}d ORDER BY updated DESC"
  fields: ["summary", "status", "issuetype", "priority", "updated"]
  maxResults: 20
```

### 4b. Tickets assigned to user that were updated in the window

```
mcp__atlassian__searchJiraIssuesUsingJql
  cloudId: "e011c47b-05b6-4434-bf2a-50a16ac25afa"
  jql: "assignee = currentUser() AND updated >= -${days}d ORDER BY updated DESC"
  fields: ["summary", "status", "issuetype", "priority", "updated"]
  maxResults: 20
```

### 4c. Recently closed tickets (done in the window)

```
mcp__atlassian__searchJiraIssuesUsingJql
  cloudId: "e011c47b-05b6-4434-bf2a-50a16ac25afa"
  jql: "assignee = currentUser() AND statusCategory = Done AND updated >= -${days}d ORDER BY updated DESC"
  fields: ["summary", "status", "updated", "resolutiondate"]
  maxResults: 10
```

## Step 5: Synthesize Activity

Organize into three buckets:

### Done (past N days)
Include items where something clearly happened in the window:
- PRs **opened** by the user (PullRequestEvent action=opened)
- PRs **merged** or **closed** by the user (PullRequestEvent action=closed)
- PRs **reviewed** (from search results and PullRequestReviewEvent)
- PR review **comments** left (PullRequestReviewCommentEvent) — group by PR, don't list every comment
- Issue/PR **comments** left on other people's work (IssueCommentEvent where the issue is not theirs)
- Branches **created** (CreateEvent ref_type=branch) — only mention if tied to a meaningful PR
- Jira tickets **closed/resolved** in the window

De-duplicate: if a PR appears in both "opened" events and "reviewed" results, it's theirs — list it under opened, not reviewed.

### In Progress
Jira tickets with status `In Progress`, `In Review`, or `Selected for Work` that were updated within the window (`updated >= -Nd`).
Prioritize by: In Progress > In Review > Selected for Work.
Also include any open non-draft PRs whose `updatedAt` falls within the window and were NOT opened in the window (ongoing review work).

### Up Next / On Hold
Jira tickets with status `Triage`, `On Hold`, or `To Do` that were updated within the window (`updated >= -Nd`).
Omit entirely if none had activity in the window.

## Step 6: Format for Slack

Use Slack formatting only:
- `*text*` for bold (not `**`)
- `_text_` for italic
- `•` for bullet points
- `:emoji:` codes
- NO links of any kind — use bold identifiers instead:
  - Jira tickets: `*ZIP-351*`
  - PRs in the main repo (zipline-app): `*#42860*`
  - PRs in other repos: `*shipit#148*` (repo name prefix, no space, no slash)
- NO markdown headers (`#`), NO tables, NO HTML

### Output wrapping

Always wrap the entire output in a single fenced code block (triple backticks) so the raw Slack formatting characters are preserved when copy-pasted:

````
```
*Standup — ...*
...
```
````

### Template

```
*Standup — {date label}*

*:white_check_mark: Done*
• {action} *#{number}* — {title}
• {action} *{repo}#{number}* — {title}
• Reviewed *#{number}* — {title}
• Closed *{key}* — {summary}
[If nothing done: • _No activity found in this window_]

*:hammer_and_wrench: In Progress*
• *{key}* — {summary} _({status})_
[Also list open non-draft PRs that are in ongoing review]
[If nothing: • _Nothing actively in progress_]

*:soon: Up Next*
• *{key}* — {summary} _({status})_
[If nothing: omit this section entirely]
```

### Rules

- PRs in `zipline-app`: bold number only — `*#42860*`
- PRs in other repos: bold repo-prefixed number — `*shipit#148*` (no space, no slash)
- Jira tickets: bold key — `*ZIP-351*`
- Merge related events into one bullet: "Opened *#42860*, *#42861*, *#42862* — CDN session cookie + blob authorization endpoint" instead of 3 separate bullets if they share a theme
- Don't list draft PRs in Done or In Progress unless asked
- Keep bullets to one line each; no sub-bullets
- If days > 1, group Done items by day with a sub-label like `_Feb 25_` and `_Feb 26_` before the bullets for that day

### Multi-day grouping example (days=2)

```
*Standup — Feb 25 – Feb 26, 2026*

*:white_check_mark: Done*

_Feb 25_
• Reviewed *shipit#42799* — Fix session expiry in Draco

_Feb 26_
• Opened *#42860*, *#42861*, *#42862* — CDN session cookie + blob authorization endpoint
• Reviewed *#42841* — Fix `jump_token_url` subdomain for 2-level clusters

*:hammer_and_wrench: In Progress*
...
```

## Error Handling

- If GitHub events API returns nothing (private org events may be empty): fall back to `gh pr list` and `gh api search/issues` only
- If Jira search fails: output what GitHub data was found and note Jira is unavailable
- If no activity at all: output the template with "_No activity found_" in Done and the current assigned tickets in In Progress
