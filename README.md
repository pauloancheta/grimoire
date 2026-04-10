# 📖 Grimoire

A personal collection of spells and learnings. Please note that I'm using "oh-my-zsh", so MMV

## Scripts (Spell Casting)
Instead of adding custom scripts to `/usr/bin`, it's better to add this repositories' `/bin` to your
`PATH`. Here's how to add it:

```zsh
# on your .zshconfig or .bashconfig
# assuming that this repository is in your `~` dir.
export PATH="$HOME/grimoire/bin:$PATH"
```
## Authentications
* [Oauth: Authorization Code Flow](./auth/oauth_auth_code.md)

## ITERM / Terminal
* [cmd + B](./iterm/cmd_+_b.md)
* [type faster](./iterm/type_faster.md)
* [ag hidden files](./iterm/ag_hidden_files.md)

## Linux Commands
* [scp](./linux_commands/scp.md)
* [less](./linux_commands/less.md)
* [make](./linux_commands/make.md)

## Ruby
* [benckmark-ips](./ruby/benckmark-ips.md)
* [pattern_matching](./ruby/pattern_matching.md)
* [Acts like array](./ruby/acts_like_array.md)
* [Split Multi Chars](./ruby/split_multi_chars.md)

## Ruby on Rails
* [find_each](./ruby_on_rails/find_each.md)
* [installation](./ruby_on_rails/installation.md)
* [dead_code](./ruby_on_rails/dead_code.md)
* [Debug Callbacks](./ruby_on_rails/debug_callbacks.md)
* [rake_tasks](./ruby_on_rails/rake_tasks.md)
* [setting_cucumber_cookies](./ruby_on_rails/setting_cucumber_cookies.md)
* [Deploy to Elastic Beanstalk](./ruby_on_rails/deploy_to_elastic_beanstalk.md)
* [Sanitize SQL Query](./ruby_on_rails/sanitize_sql_query.md)
* [Get Table Row Totals](./ruby_on_rails/get_table_totals.md)
* [Useful Sidekiq Commands](./ruby_on_rails/sidekiq_commands.md)

## Python
* [open](./python/open.md)
* [debugger](./python/debugger.md)
* [is](./python/is.md)

## Vim
* [expand directory](./vim/expand_directory.md)
* [maximize and restore tabs](./vim/maximize_and_restore_tabs.md)
* [new line](./vim/new_line.md)
* [remove empty lines](./vim/remove_empty_lines.md)

## Git
* [patch](./git/patch.md)

## MySql
* [utf8](./mysql/utf8.md)

## Terminal Productivity
- https://github.com/junegunn/fzf
- https://github.com/sharkdp/bat

## Claude Code

Skills and config live in `claude/`. Run `_install` to symlink them into `~/.claude/`.

### Skills (`claude/skills/`)
* [dev](./claude/skills/dev/SKILL.md) - Worker mode: worktree per ticket, tester + reviewer gates before push
* [standup](./claude/skills/standup/SKILL.md) - Daily standup from GitHub and Jira activity
* [performance-review](./claude/skills/performance-review/SKILL.md) - 6-month performance review from GitHub and Jira

### Config (`claude/`)
* [statusline-command.sh](./claude/statusline-command.sh) - Claude Code statusline setup
