#!/bin/bash
# Claude Code statusline — jq is the only dependency
# Install: cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
#
# Add to ~/.claude/settings.json:
# {
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/statusline.sh",
#     "padding": 0
#   }
# }
#
# Configuration via environment variables (set in your shell profile):
#   CLAUDE_PLAN        — "pro" (default), "max5", "max20", or "api"
#   CLAUDE_BUDGET      — session cost warning threshold in USD (default: varies by plan)
#   CLAUDE_CTX_WARN    — context % to turn yellow (default: 50)
#   CLAUDE_CTX_CRIT    — context % to turn red (default: 80)

set -euo pipefail

# --- Read JSON from stdin (Claude Code pipes session data here) ---
input=$(cat)

# --- ANSI colors ---
RST='\033[0m'
BOLD='\033[1m'
RED='\033[1;31m'
YEL='\033[1;33m'
GRN='\033[1;32m'
CYN='\033[1;36m'
MAG='\033[1;35m'
DIM='\033[2m'

# --- Configuration ---
PLAN="${CLAUDE_PLAN:-pro}"
CTX_WARN="${CLAUDE_CTX_WARN:-50}"
CTX_CRIT="${CLAUDE_CTX_CRIT:-80}"

# Budget defaults per plan (USD per session — rough guidance, not hard limits)
case "$PLAN" in
  pro)   BUDGET="${CLAUDE_BUDGET:-5}"   ; PLAN_LABEL="Pro" ;;
  max5)  BUDGET="${CLAUDE_BUDGET:-25}"  ; PLAN_LABEL="Max5x" ;;
  max20) BUDGET="${CLAUDE_BUDGET:-100}" ; PLAN_LABEL="Max20x" ;;
  api)   BUDGET="${CLAUDE_BUDGET:-50}"  ; PLAN_LABEL="API" ;;
  *)     BUDGET="${CLAUDE_BUDGET:-5}"   ; PLAN_LABEL="$PLAN" ;;
esac

# --- Extract fields ---
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Context window — newer Claude Code versions provide this directly
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)

# Fallback: check exceeds_200k_tokens boolean (older versions)
if [ -z "$CTX_PCT" ]; then
  EXCEEDS=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
  if [ "$EXCEEDS" = "true" ]; then
    CTX_PCT="99"
  fi
fi

# --- Git info (fast, no-optional-locks to avoid contention) ---
GIT_INFO=""
if command -v git &>/dev/null && git -C "$CWD" rev-parse --git-dir &>/dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" --no-optional-locks branch --show-current 2>/dev/null || echo "")
  if [ -n "$BRANCH" ]; then
    # Count dirty files (staged + unstaged + untracked)
    DIRTY=$(git -C "$CWD" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY" -gt 0 ]; then
      GIT_INFO="${CYN}${BRANCH}${RST}${DIM}*${DIRTY}${RST}"
    else
      GIT_INFO="${CYN}${BRANCH}${RST}"
    fi
  fi
fi

# --- Context bar ---
CTX_DISPLAY=""
if [ -n "$CTX_PCT" ]; then
  # Truncate to integer
  CTX_INT=${CTX_PCT%%.*}
  CTX_INT=${CTX_INT:-0}

  # Color based on thresholds
  if [ "$CTX_INT" -ge "$CTX_CRIT" ]; then
    CTX_COLOR="$RED"
  elif [ "$CTX_INT" -ge "$CTX_WARN" ]; then
    CTX_COLOR="$YEL"
  else
    CTX_COLOR="$GRN"
  fi

  # Visual bar (10 chars wide)
  FILLED=$(( CTX_INT / 10 ))
  EMPTY=$(( 10 - FILLED ))
  BAR=""
  for ((i=0; i<FILLED; i++)); do BAR+="▓"; done
  for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

  # Token count in K if available
  TOKEN_STR=""
  if [ -n "$CTX_SIZE" ] && [ "$CTX_SIZE" != "null" ]; then
    CTX_K=$(( CTX_SIZE / 1000 ))
    TOKEN_STR="/${CTX_K}k"
  fi

  CTX_DISPLAY="${CTX_COLOR}${BAR} ${CTX_INT}%${TOKEN_STR}${RST}"
fi

# --- Cost with budget indicator ---
COST_FMT=$(printf '%.2f' "$COST")
BUDGET_FMT=$(printf '%.0f' "$BUDGET")

# Color cost: green if under 50% of budget, yellow 50-80%, red 80%+
# Use awk for float comparison (no bc dependency)
COST_COLOR=$(awk -v c="$COST" -v b="$BUDGET" 'BEGIN {
  pct = (b > 0) ? (c / b) * 100 : 0
  if (pct >= 80) print "RED"
  else if (pct >= 50) print "YEL"
  else print "GRN"
}')

case "$COST_COLOR" in
  RED) COST_CLR="$RED" ;;
  YEL) COST_CLR="$YEL" ;;
  *)   COST_CLR="$GRN" ;;
esac

COST_DISPLAY="${COST_CLR}\$${COST_FMT}${RST}${DIM}/\$${BUDGET_FMT}${RST}"

# --- Assemble status line ---
# Format: [Model] dir (branch*N) | ▓▓▓░░░░░░░ 42%/200k | $1.23/$5
PARTS=()
PARTS+=("${MAG}${MODEL}${RST}")

if [ -n "$GIT_INFO" ]; then
  PARTS+=("${GIT_INFO}")
fi

SEP="${DIM}|${RST}"

OUTPUT=""
for i in "${!PARTS[@]}"; do
  if [ "$i" -gt 0 ]; then
    OUTPUT+=" "
  fi
  OUTPUT+="${PARTS[$i]}"
done

# Add metrics after separator
METRICS=""
if [ -n "$CTX_DISPLAY" ]; then
  METRICS+="${CTX_DISPLAY}"
fi
METRICS+=" ${SEP} ${COST_DISPLAY}"
METRICS+=" ${DIM}[${PLAN_LABEL}]${RST}"

OUTPUT+=" ${SEP} ${METRICS}"

printf '%b' "$OUTPUT"
