#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "repos" ]]; then
    echo "Error: no repos/ directory found. Run from umbrella repo root." >&2
    exit 1
fi

for repo in repos/*/; do
    [[ -d "$repo/.git" ]] || continue
    name=$(basename "$repo")
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)
    dirty=$(git -C "$repo" status --short 2>/dev/null)
    ahead_behind=$(git -C "$repo" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "")

    echo "=== $name ($branch) ==="
    if [[ -n "$ahead_behind" ]]; then
        ahead=$(echo "$ahead_behind" | awk '{print $1}')
        behind=$(echo "$ahead_behind" | awk '{print $2}')
        [[ "$ahead" -gt 0 ]] && echo "  ahead $ahead"
        [[ "$behind" -gt 0 ]] && echo "  behind $behind"
    fi
    if [[ -n "$dirty" ]]; then
        echo "$dirty" | sed 's/^/  /'
    else
        echo "  clean"
    fi
done
