# dot-claude

Global Claude Code configuration installer — statusline, settings, rules, and CLAUDE.md for `~/.claude/`.

## Install

```bash
npx @oorn/dot-claude init
```

`jq` is required for the statusline. The installer will attempt to install it automatically via the available package manager on your system (Homebrew, apt, dnf, yum, pacman, zypper, apk, winget, Chocolatey, or Scoop). If auto-install fails, you'll be shown the manual command.

To update to the latest version:

```bash
npx @oorn/dot-claude@latest init
```

## What gets installed

| File | Destination | Description |
|------|-------------|-------------|
| `settings.json` | `~/.claude/settings.json` | Claude Code preferences |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line script |

## Statusline

The status line is mode-aware — it adapts based on whether you're on a subscription plan or using an API key.

**Subscription (Pro/Max):**
```
Claude Sonnet 4.6 | [████                ] 42% | 84k/200k | 5h:37% (1h22m) 7d:15%
```

**Anthropic API key (`claude-*` models):**
```
Claude Sonnet 4.6 | [████                ] 42% | 84k/200k | ~$0.5544
```

**3rd-party API (Gemini, MiniMax, etc.):**
```
Gemini 2.5 Pro | [███████████         ] 55% | 550k/1000k
```

| Segment | Description |
|---------|-------------|
| Model name | Current model display name |
| `[████   ]` | Context window usage bar (green < 50%, yellow < 80%, red ≥ 80%) |
| `42%` | Context used percentage |
| `84k/200k` | Used tokens / total context window size |
| `5h:37% (1h22m)` | 5-hour rate limit usage + countdown to reset *(subscription only)* |
| `7d:15%` | 7-day rate limit usage *(subscription only)* |
| `~$0.5544` | Estimated session cost *(Anthropic API only)* |

Cost is estimated using a 70/30 input/output token split with per-model pricing:

| Model | Input | Output |
|-------|-------|--------|
| Opus 4.x | $15/MTok | $75/MTok |
| Sonnet 4.x / 3.7 | $3/MTok | $15/MTok |
| Haiku 4.x / 3.x | $0.8/MTok | $4/MTok |

For 3rd-party models the right section is omitted — token usage is already visible in the bar.

### How it works

Claude Code invokes `statusline-command.sh` after each response, passing a JSON payload via stdin. The script parses the JSON with `jq` and prints a formatted line with ANSI colors.

The script is wired up in `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

### Available JSON fields

The full payload Claude Code sends to the script includes:

```json
{
  "model": { "id": "claude-sonnet-4-6", "display_name": "Sonnet 4.6" },
  "context_window": {
    "used_percentage": 21,
    "remaining_percentage": 79,
    "context_window_size": 200000,
    "total_input_tokens": 44,
    "total_output_tokens": 7202,
    "current_usage": {
      "input_tokens": 1,
      "output_tokens": 28,
      "cache_creation_input_tokens": 219,
      "cache_read_input_tokens": 34414
    }
  },
  "rate_limits": {
    "five_hour": { "used_percentage": 18, "resets_at": 1775725200 },
    "seven_day": { "used_percentage": 17, "resets_at": 1776067200 }
  },
  "cost": {
    "total_cost_usd": 0.67,
    "total_lines_added": 86,
    "total_lines_removed": 79
  },
  "cwd": "/Users/you/project",
  "version": "2.1.97"
}
```

## Updating the config

1. Edit files in `.claude/`
2. Bump version in `package.json`
3. Update this README to reflect the change
4. Publish and push:
   ```bash
   npm publish --access public && git push
   ```
