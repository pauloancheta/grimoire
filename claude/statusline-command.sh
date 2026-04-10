#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Get git branch (skip optional locks)
branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Build context info
context_info=""
if [ -n "$used" ]; then
  context_info=" | ctx: ${used}%"
fi

# Build git info
git_info=""
if [ -n "$branch" ]; then
  git_info=" | $branch"
fi

printf "\033[32m%s\033[0m%s \033[33m%s\033[0m%s" \
  "$cwd" "$git_info" "$model" "$context_info"
