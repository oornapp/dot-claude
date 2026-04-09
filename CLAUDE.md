# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

An npm package (`@oorn/dotclaude`) that installs shared Claude Code config (statusline, settings, rules) into `~/.claude/`. There are two install paths:

- **npx** — `npx @oorn/dotclaude init` — copies files via `bin/cli.js`
- **dev** — `./install.sh` — symlinks files for live editing

## Publishing workflow

After every change:
1. Bump version in `package.json`
2. Update `README.md` to reflect the change
3. Commit, publish, push:
   ```bash
   npm publish --access public && git push
   ```

**Always update README.md after every change.** The README is the user-facing doc — keep examples, tables, and descriptions in sync with the actual behavior.

## Architecture

| File | Role |
|------|------|
| `bin/cli.js` | npx entry point — copies `.claude/` files to `~/.claude/`, checks/installs `jq` |
| `install.sh` | Dev install — symlinks instead of copying, for live edits |
| `.claude/statusline-command.sh` | The statusline script itself (bash, reads JSON from stdin) |
| `.claude/settings.json` | Claude Code settings (statusline wired here) |
| `.claude/rules/` | Global rules installed into `~/.claude/rules/` |

## Statusline logic

The statusline script (`statusline-command.sh`) is mode-aware based on what the JSON payload contains:

- **Subscription (Pro/Max)** — `rate_limits` present → show 5h/7d rate limit blocks
- **Anthropic API** — no `rate_limits`, `model.id` starts with `claude-` → show cost estimate
- **3rd-party API** — no `rate_limits`, non-claude model → show token bar only, no cost

Cost is estimated with a 70/30 input/output split using hardcoded per-model pricing.

## jq auto-install

`cli.js` detects `jq` after copying files and tries to install it automatically. Priority order per OS:

- macOS: Homebrew → MacPorts
- Linux: apt → dnf → yum → pacman → zypper → apk
- Windows: winget → Chocolatey → Scoop

Falls back to a manual install message if none are found.

## Key constraints

- `package.json` `"type": "module"` — `bin/cli.js` uses ESM (`import`, not `require`)
- Version in `bin/cli.js` is read dynamically from `package.json` — never hardcode it
- `files` in `package.json` includes `bin/` and `.claude/` — subdirectories like `rules/` are included automatically
