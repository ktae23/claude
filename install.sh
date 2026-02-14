#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Create symlink with backup
# Usage: create_link <source> <target> <type: file|dir>
create_link() {
    local src="$1" tgt="$2" type="${3:-file}"

    # Already correct symlink → skip
    if [ -L "$tgt" ] && [ "$(readlink "$tgt")" = "$src" ]; then
        ok "$tgt → already linked"
        return 0
    fi

    # Backup existing file/dir/symlink
    if [ -e "$tgt" ] || [ -L "$tgt" ]; then
        local backup="${tgt}.backup.${TIMESTAMP}"
        mv "$tgt" "$backup"
        warn "Backed up $tgt → $backup"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$tgt")"

    ln -s "$src" "$tgt"
    ok "$tgt → $src"
}

# Ask yes/no with default
# Usage: ask "prompt" [Y|n]
ask() {
    local prompt="$1" default="${2:-Y}"
    if [ "$default" = "Y" ]; then
        read -rp "$prompt [Y/n] " answer
        answer="${answer:-Y}"
    else
        read -rp "$prompt [y/N] " answer
        answer="${answer:-N}"
    fi
    [[ "$answer" =~ ^[Yy] ]]
}

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   Claude Code Portable Config Installer   ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Repo: $REPO_DIR"
echo "║  Target: $CLAUDE_DIR"
echo "╚════════════════════════════════════════════╝"
echo ""

mkdir -p "$CLAUDE_DIR"

# ──────────────────────────────────────────────
# Phase 1: Core config (CLAUDE.md, settings.json)
# ──────────────────────────────────────────────
info "Phase 1: Core configuration"

if ask "  Install CLAUDE.md (global instructions)?"; then
    create_link "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

if ask "  Install settings.json?"; then
    create_link "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
fi

echo ""

# ──────────────────────────────────────────────
# Phase 2: sync-claude skill (always installed)
# ──────────────────────────────────────────────
info "Phase 2: sync-claude skill (auto-install)"
mkdir -p "$CLAUDE_DIR/skills"
create_link "$REPO_DIR/skills/sync-claude" "$CLAUDE_DIR/skills/sync-claude" dir

echo ""

# ──────────────────────────────────────────────
# Phase 3: Skills (directory symlinks)
# ──────────────────────────────────────────────
info "Phase 3: Skills"

for skill_dir in "$REPO_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "sync-claude" ] && continue  # already installed

    if ask "  Install skill: ${skill_name}?"; then
        create_link "$REPO_DIR/skills/$skill_name" "$CLAUDE_DIR/skills/$skill_name" dir
    fi
done

echo ""

# ──────────────────────────────────────────────
# Phase 4: Commands (file symlinks)
# ──────────────────────────────────────────────
info "Phase 4: Commands"

if [ -d "$REPO_DIR/commands" ]; then
    mkdir -p "$CLAUDE_DIR/commands"
    for cmd_file in "$REPO_DIR"/commands/*.md; do
        [ -f "$cmd_file" ] || continue
        cmd_name="$(basename "$cmd_file")"
        if ask "  Install command: ${cmd_name}?"; then
            create_link "$cmd_file" "$CLAUDE_DIR/commands/$cmd_name"
        fi
    done
fi

echo ""

# ──────────────────────────────────────────────
# Phase 5: Plugin notice
# ──────────────────────────────────────────────
info "Phase 5: Plugins"
echo "  Plugins cannot be symlinked. See ~/claude/plugins/README.md for manual setup."

echo ""
echo "════════════════════════════════════════════"
ok "Installation complete!"
echo "  Restart Claude Code to apply changes."
echo "════════════════════════════════════════════"
