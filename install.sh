#!/usr/bin/env bash
# claw-statusline install script
# Symlinks .claude config files into ~/.claude/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing claw-statusline config to $CLAUDE_DIR..."

mkdir -p "$CLAUDE_DIR/rules" "$CLAUDE_DIR/skills"

# settings.json
ln -sf "$REPO_DIR/.claude/settings.json" "$CLAUDE_DIR/settings.json"
echo "  ✓ settings.json"

# statusline script
ln -sf "$REPO_DIR/.claude/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "  ✓ statusline-command.sh"

# rules
for f in "$REPO_DIR/.claude/rules/"*; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$CLAUDE_DIR/rules/$(basename "$f")"
  echo "  ✓ rules/$(basename "$f")"
done

# skills
for f in "$REPO_DIR/.claude/skills/"*; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$CLAUDE_DIR/skills/$(basename "$f")"
  echo "  ✓ skills/$(basename "$f")"
done

echo ""
echo "Done! Claude Code will pick up changes automatically."
echo "To update: git pull && ./install.sh"
