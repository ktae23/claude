#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  Claude Code Config Uninstaller            ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Removing symlinks pointing to:            ║"
echo "║  $REPO_DIR"
echo "╚════════════════════════════════════════════╝"
echo ""

removed=0

# Remove symlinks in ~/.claude/ that point to this repo
remove_if_linked() {
    local target="$1"
    if [ -L "$target" ]; then
        local link_dest
        link_dest="$(readlink "$target")"
        # Check if symlink points into our repo
        if [[ "$link_dest" == "$REPO_DIR"* ]]; then
            rm "$target"
            ok "Removed: $target → $link_dest"
            ((removed++))
        fi
    fi
}

# Core files
remove_if_linked "$CLAUDE_DIR/CLAUDE.md"
remove_if_linked "$CLAUDE_DIR/settings.json"

# Skills (directory symlinks)
if [ -d "$CLAUDE_DIR/skills" ]; then
    for item in "$CLAUDE_DIR"/skills/*/; do
        [ -d "$item" ] || continue
        item="${item%/}"
        remove_if_linked "$item"
    done
fi

# Commands (file symlinks)
if [ -d "$CLAUDE_DIR/commands" ]; then
    for item in "$CLAUDE_DIR"/commands/*.md; do
        [ -f "$item" ] || [ -L "$item" ] || continue
        remove_if_linked "$item"
    done
fi

echo ""
if [ "$removed" -gt 0 ]; then
    ok "Removed $removed symlink(s)."
else
    info "No symlinks pointing to this repo were found."
fi
echo "  Restart Claude Code to apply changes."
