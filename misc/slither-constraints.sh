#!/usr/bin/env bash
#
# slither-constraints.sh - Print pinned dependencies for a Slither release
#
# Usage:
#   misc/slither-constraints.sh <slither-version>
#
# Installs slither-analyzer==<version> with pipx in a throwaway alpine:3.24
# container (same Alpine release and Python as the dev container image) and
# prints the venv's pip freeze.  Paste the output into SLITHER_CONSTRAINTS in
# ai-devcontainer.sh, set SLITHER_VERSION to match, and rebuild.
#
# Environment variables:
#   AI_DEVCONTAINER_ENGINE   Container engine to use (default: podman)

set -euo pipefail

ENGINE="${AI_DEVCONTAINER_ENGINE:-podman}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <slither-version>" >&2
    exit 1
fi
version="$1"

"$ENGINE" run --rm alpine:3.24 sh -euc "
    apk add --no-cache -q pipx >&2
    PIP_NO_CACHE_DIR=1 pipx install -q slither-analyzer==$version >&2
    pipx runpip slither-analyzer freeze
"
