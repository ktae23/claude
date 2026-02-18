#!/bin/bash
input=$(cat)

# Skip rendering if terminal width is too narrow (startup timing issue)
COLS=$(tput cols 2>/dev/null || echo 80)
[ "$COLS" -lt 20 ] && exit 0

# Data extraction
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
AGENT=$(echo "$input" | jq -r '.agent.name // empty')

# Colors
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
BLUE='\033[34m'; MAGENTA='\033[35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# Line 1: dir + git + agent
GIT_INFO=""
if cd "$DIR" 2>/dev/null; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    STATUS=$(git status --porcelain 2>/dev/null)
    if [ -n "$STATUS" ]; then
      GIT_INFO=" ${BOLD}${BLUE}git:${RED}${BRANCH}${RESET} ${YELLOW}✗${RESET}"
    else
      GIT_INFO=" ${BOLD}${BLUE}git:${RED}${BRANCH}${RESET}"
    fi
  fi
fi
AGENT_INFO=""
[ -n "$AGENT" ] && AGENT_INFO=" ${DIM}[${RESET}${BOLD}${YELLOW}${AGENT}${RESET}${DIM}]${RESET}"
echo -e "${BOLD}${GREEN}➜${RESET}  ${CYAN}$(basename "$DIR")${RESET}${GIT_INFO}${AGENT_INFO}"

# --- Line 2: Subscription usage (cached, background refresh) ---
CACHE="$HOME/.claude/usage-cache.json"
LOCK="$HOME/.claude/usage-cache.lock"
CACHE_TTL=60  # seconds

# Background refresh
refresh_cache() {
  # Skip if another refresh is running
  [ -f "$LOCK" ] && return
  touch "$LOCK"
  (
    TOKEN=$(security find-generic-password -a "$USER" -w -s "Claude Code-credentials" 2>/dev/null \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null)
    if [ -n "$TOKEN" ]; then
      DATA=$(curl -sf --max-time 5 --config - \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null <<CURL_CFG
header = "Authorization: Bearer $TOKEN"
header = "Content-Type: application/json"
header = "anthropic-beta: oauth-2025-04-20"
CURL_CFG
      )
      if [ -n "$DATA" ] && echo "$DATA" | jq -e . >/dev/null 2>&1; then
        echo "$DATA" > "$CACHE"
        chmod 600 "$CACHE"
      fi
    fi
    rm -f "$LOCK"
  ) &
  disown 2>/dev/null
}

# Check if cache needs refresh
needs_refresh=false
if [ ! -f "$CACHE" ]; then
  needs_refresh=true
else
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
  [ "$CACHE_AGE" -ge "$CACHE_TTL" ] && needs_refresh=true
fi
[ "$needs_refresh" = true ] && refresh_cache

# Render from cache
if [ -f "$CACHE" ]; then
  mini_bar() {
    local p=${1:-0} w=10 c="$GREEN"
    [ "$p" -ge 50 ] && c="$YELLOW"
    [ "$p" -ge 80 ] && c="$RED"
    local f=$(( (p * w + 50) / 100 ))
    [ "$p" -gt 0 ] && [ "$f" -lt 1 ] && f=1
    [ "$p" -lt 100 ] && [ "$f" -ge "$w" ] && f=$((w - 1))
    [ "$f" -gt "$w" ] && f=$w
    local e=$((w - f)) b=""
    [ "$f" -gt 0 ] && b=$(printf "%${f}s" | tr ' ' '▓')
    [ "$e" -gt 0 ] && b="${b}$(printf "%${e}s" | tr ' ' '░')"
    echo -ne "${c}${b}${RESET}"
  }

  to_epoch() {
    local clean
    clean=$(echo "$1" | sed 's/\.[^+Z]*//;s/+.*//;s/Z//')
    TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null
  }

  countdown() {
    local rep now diff
    rep=$(to_epoch "$1") || return
    now=$(date +%s)
    diff=$((rep - now))
    [ "$diff" -le 0 ] && echo "done" && return
    local h=$((diff / 3600)) m=$(((diff % 3600) / 60))
    if [ "$h" -ge 24 ]; then echo "$((h/24))d$((h%24))h"
    elif [ "$h" -gt 0 ]; then echo "${h}h${m}m"
    else echo "${m}m"
    fi
  }

  fmt_reset() {
    local ep
    ep=$(to_epoch "$1") || return
    date -j -f "%s" "$ep" "+%m/%d %H:%M" 2>/dev/null
  }

  FH=$(jq -r '.five_hour.utilization // empty' "$CACHE")
  FH_R=$(jq -r '.five_hour.resets_at // empty' "$CACHE")
  SD=$(jq -r '.seven_day.utilization // empty' "$CACHE")
  SD_R=$(jq -r '.seven_day.resets_at // empty' "$CACHE")

  LINE2=""
  if [ -n "$FH" ]; then
    FH_P=${FH%.*}
    FH_CD=$(countdown "$FH_R")
    FH_DT=$(fmt_reset "$FH_R")
    LINE2="$(mini_bar "$FH_P") ${BOLD}${FH_P}%${RESET}${DIM}5h${RESET}"
    [ -n "$FH_CD" ] && LINE2="${LINE2}${DIM}→${FH_CD}${RESET}"
    [ -n "$FH_DT" ] && LINE2="${LINE2}${DIM}(${FH_DT})${RESET}"
  fi
  if [ -n "$SD" ]; then
    SD_P=${SD%.*}
    SD_CD=$(countdown "$SD_R")
    SD_DT=$(fmt_reset "$SD_R")
    [ -n "$LINE2" ] && LINE2="${LINE2} ${DIM}│${RESET} "
    LINE2="${LINE2}$(mini_bar "$SD_P") ${BOLD}${SD_P}%${RESET}${DIM}7d${RESET}"
    [ -n "$SD_CD" ] && LINE2="${LINE2}${DIM}→${SD_CD}${RESET}"
    [ -n "$SD_DT" ] && LINE2="${LINE2}${DIM}(${SD_DT})${RESET}"
  fi

  [ -n "$LINE2" ] && echo -e "${LINE2}"
fi
