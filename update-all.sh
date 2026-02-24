#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "repos" ]]; then
    echo "Error: no repos/ directory found. Run from umbrella repo root." >&2
    exit 1
fi

for repo in repos/*/; do
    [[ -d "$repo/.git" ]] || continue
    name=$(basename "$repo")
    echo "=== $name ==="
    git -C "$repo" fetch --all --prune --tags 2>&1 | sed 's/^/  /'
    git -C "$repo" merge --ff-only 2>&1 | sed 's/^/  /'
done
