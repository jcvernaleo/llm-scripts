#!/usr/bin/env bash
set -euo pipefail

REPOS_TXT="${1:-repos.txt}"

if [[ ! -f "$REPOS_TXT" ]]; then
    echo "Error: $REPOS_TXT not found. Run from umbrella repo root." >&2
    exit 1
fi

mkdir -p repos

while IFS= read -r url || [[ -n "$url" ]]; do
    [[ -z "$url" || "$url" == \#* ]] && continue
    name=$(basename "$url" .git)
    if [[ -d "repos/$name" ]]; then
        echo "  skip  $name (already exists)"
    else
        echo "  clone $name"
        git clone "$url" "repos/$name"
    fi
done < "$REPOS_TXT"
