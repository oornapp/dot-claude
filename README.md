# dot-claude

Shared Claude Code configuration for the team — statusline, settings, and rules.

## Install

```bash
npx @oorn/dotclaude init
```

To update to the latest version:

```bash
npx @oorn/dotclaude@latest init
```

## What gets installed

| File | Destination | Description |
|------|-------------|-------------|
| `settings.json` | `~/.claude/settings.json` | Claude Code preferences |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line script |

## Statusline

The status line displays at the bottom of Claude Code and shows:

```
Sonnet 4.6 | [████                ] 21% | 42k/200k | 5h:18% (2h5m) 7d:17%
```

| Segment | Description |
|---------|-------------|
| `Sonnet 4.6` | Current model name |
| `[████   ]` | Context window usage bar (green < 50%, yellow < 80%, red ≥ 80%) |
| `21%` | Context used percentage |
| `42k/200k` | Used tokens / total context window size |
| `5h:18% (2h5m)` | 5-hour rate limit usage + countdown to reset (Claude Max only) |
| `7d:17%` | 7-day rate limit usage (Claude Max only) |

### Requirements

- `jq` — used to parse the JSON Claude Code passes to the script
  ```bash
  brew install jq
  ```

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

Other fields you could add to the statusline: `cost.total_cost_usd`, `cost.total_lines_added/removed`, cache hit ratio from `cache_read_input_tokens`, `exceeds_200k_tokens` warning.

## Updating the config

1. Edit files in `.claude/`
2. Bump version in `package.json`
3. Publish and push:
   ```bash
   npm publish --access public && git push
   ```
