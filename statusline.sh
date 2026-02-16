#!/bin/bash
input=$(cat)

# Data extraction
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
REMAIN=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Colors
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# Line 1: git info (preserve existing behavior)
GIT_INFO=""
if cd "$DIR" 2>/dev/null; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    STATUS=$(git status --porcelain 2>/dev/null)
    if [ -n "$STATUS" ]; then
      GIT_INFO=" ${BOLD}\033[34mgit:${RED}${BRANCH}${RESET} ${YELLOW}✗${RESET}"
    else
      GIT_INFO=" ${BOLD}\033[34mgit:${RED}${BRANCH}${RESET}"
    fi
  fi
fi
echo -e "${BOLD}${GREEN}➜${RESET}  ${CYAN}$(basename "$DIR")${RESET}${GIT_INFO}"

# Line 2: context usage bar + cost + duration
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=15
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))
COST_FMT=$(printf '$%.2f' "$COST")

echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% ${DIM}(${REMAIN}% left)${RESET} | ${DIM}[${MODEL}]${RESET} ${COST_FMT} ${DIM}${MINS}m${SECS}s${RESET}"
