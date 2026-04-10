---
name: performance-review
description: Generate a 6-month performance review for one or more engineers by combining their Jira and GitHub contributions. Highlights what went well and what could have gone better. Can generate one markdown file per user for team-wide reviews.
---

# Performance Review Generator

Generate a 6-month performance review summary by pulling Jira tickets and GitHub PRs for one or more engineers. Each review highlights what went well and what could have gone better.

## When to Use

- User asks for a performance review or contribution summary
- User says "generate a review for [name]" or "review my last 6 months"
- User wants a team-wide review across multiple engineers
- User says "generate reviews for my team" or passes a list of GitHub usernames

## Step 1: Determine Mode

**Single user** (default — use current user's credentials):
- No argument, or user says "my review" → use `atlassianUserInfo` + `gh api user`

**Single named user**:
- User provides a name, email, or GitHub username → look up their Jira account ID and GitHub login

**Multi-user / team mode**:
- User provides a list of GitHub usernames or says "for my whole team"
- If no list is given, fetch org members: `gh api orgs/retailzipline/members --jq '.[].login'`
- Run the full pipeline for each user and write one markdown file per person

## Step 2: Resolve User Identities

For each user you need two identifiers:

**Jira account ID** — use the Atlassian MCP:
```
mcp__atlassian__atlassianUserInfo        # for current user
mcp__atlassian__lookupJiraAccountId      # for others, search by name or email
  cloudId: "e011c47b-05b6-4434-bf2a-50a16ac25afa"
  searchString: "<name or email>"
```

**GitHub login** — for current user:
```bash
gh api user --jq '.login'
```

## Step 3: Fetch Jira Contributions (past 6 months)

```
mcp__atlassian__searchJiraIssuesUsingJql
  cloudId: "e011c47b-05b6-4434-bf2a-50a16ac25afa"
  jql: "assignee = \"<ACCOUNT_ID>\" AND updated >= -180d ORDER BY updated DESC"
  fields: ["summary", "status", "issuetype", "priority", "created", "updated", "labels", "resolution"]
  maxResults: 100
```

If the result is too large, parse it with jq:
```bash
cat <result-file> | jq -r '.[0].text' | jq -r '.issues[] | [.key, .fields.issuetype.name, .fields.status.name, .fields.priority.name, .fields.created[:10], .fields.updated[:10], .fields.summary] | @tsv'
```

## Step 4: Fetch GitHub Contributions (past 6 months)

Calculate the date 6 months ago (ISO 8601):
```bash
date -u -v-6m +"%Y-%m-%dT%H:%M:%SZ"   # macOS
date -u -d "6 months ago" +"%Y-%m-%dT%H:%M:%SZ"  # Linux
```

Fetch PRs in the org's repo:
```bash
gh pr list \
  --repo retailzipline/zipline-app \
  --author <github-login> \
  --state all \
  --limit 100 \
  --json number,title,state,mergedAt,createdAt,headRefName
```

Filter to the 6-month window using jq:
```bash
| jq --arg since "<6-months-ago-date>" '[.[] | select(.createdAt >= $since)]'
```

Also fetch commit count via GraphQL:
```bash
gh api graphql -f query='{
  viewer {
    contributionsCollection(from: "<6-months-ago>", to: "<today>") {
      totalCommitContributions
      totalPullRequestReviewContributions
    }
  }
}'
```

## Step 5: Analyze and Write the Review

Group contributions into themes based on PR titles, branch names, and Jira summaries. Look for:

- **DRACO / cluster work** — infrastructure standup tasks
- **Authentication / SSO / OIDC** — auth-related PRs and tickets
- **Security** — vulnerability fixes, authorization, rate limiting, credential handling
- **Reliability / observability** — Datadog, monitors, error handling
- **Bug fixes** — BUGFIX-prefixed PRs and bug-type Jira issues
- **Spikes / research** — exploratory PRs and spike tickets
- **Dependency / maintenance** — INTERNAL bumps, cleanup

### What Went Well

Look for:
- Closed Jira tickets and merged PRs — completed, shipped work
- Security vulnerabilities remediated
- Infrastructure projects with clear before/after outcomes
- Consistent velocity (steady stream of merged PRs)
- Cross-cutting improvements (observability, auth, reliability)

### What Could Have Gone Better

Look for:
- PRs opened and closed without merging — stalled or abandoned work
- The same effort attempted multiple times across different PRs (e.g., repeated Dockerfile attempts)
- Long-running Jira tickets still open or In Review after 60+ days
- Work that is all breadth with no clear depth or domain ownership
- Security/important tickets that are In Review for a long time
- Periods heavy on operational toil (e.g., manual cluster provisioning) vs. engineering leverage

## Step 6: Format the Review

Use only: **bold**, *italics*, unordered lists (`-`), and ordered lists (`1.`). No headings with `#`, no tables, no HTML.

```
**[Name] — 6-Month Performance Review ([Month Year] – [Month Year])**

[2-3 sentence summary of the overall theme of their contributions.]

**What Went Well**

*[Theme 1 Name]*
[Description of the work and its impact.]
- [Specific item]
- [Specific item]

*[Theme 2 Name]*
[Description]
- [Specific item]

**What Could Have Gone Better**

- [Honest, specific observation with evidence — e.g., PR numbers, ticket keys, durations]
- [Another observation]
- [Another observation]

**By the Numbers**
- [X] PRs merged
- [X] PRs opened total
- [X] Jira tickets worked, [Y] closed
- [X] currently active or in review

**In Flight**
- **[Item]** — [one-line description]
- **[Item]** — [one-line description]
```

## Multi-User Mode: Writing Files

When generating reviews for multiple users, write one file per person:

```bash
# Output directory — ask user if not specified, default to ~/performance-reviews/
mkdir -p ~/performance-reviews

# File per user
~/performance-reviews/<github-login>-review.md
```

After writing all files, list them for the user:
```
Generated [N] reviews in ~/performance-reviews/:
- alice-review.md
- bob-review.md
- paulo-review.md
```

## Handling Large Result Sets

If Jira or GitHub returns too many results:
- Use jq to extract only what you need (key, summary, status, dates)
- Summarize by theme rather than listing every ticket
- Focus on closed/merged items for "what went well" and open/stalled for "what could improve"

## Atlassian Cloud ID

Zipline's Atlassian Cloud ID: `e011c47b-05b6-4434-bf2a-50a16ac25afa`

## GitHub Org

Zipline's GitHub org: `retailzipline`
Main repo: `retailzipline/zipline-app`
