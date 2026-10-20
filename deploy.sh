#!/usr/bin/env bash
# Deploy the Xendit ledger flow walkthrough (static single-page site on GitHub Pages).
#
# Usage:
#   ./deploy.sh
#
# What it does:
#   1. Requires a clean working tree — this script deploys committed code only.
#   2. Pushes the current branch to origin. GitHub Pages is configured to build from this
#      branch's root, so a push is the entire deploy — nothing else to run.
#
# Live at: https://priyankraj.github.io/ledger-flow-walkthrough-temp/

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

log() {
  echo "[$(date '+%H:%M:%S')] $*"
}

record_deploy() {
  local target="$1" version="$2"
  local history_file="$ROOT/.deploy-history.json"
  local commit entry
  commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  entry="$(jq -n --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg target "$target" \
    --arg version "$version" --arg commit "$commit" \
    '{timestamp:$ts, target:$target, version:$version, commit:$commit}')"
  if [[ -f "$history_file" ]]; then
    jq --argjson entry "$entry" '. + [$entry]' "$history_file" > "$history_file.tmp" && mv "$history_file.tmp" "$history_file"
  else
    jq -n --argjson entry "$entry" '[$entry]' > "$history_file"
  fi
}

BRANCH="$(git branch --show-current)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes — commit them first, deploy.sh only pushes committed code." >&2
  git status --short >&2
  exit 1
fi

if git rev-parse --verify -q "origin/$BRANCH" >/dev/null && [[ -z "$(git log "origin/$BRANCH..HEAD" --oneline)" ]]; then
  log "origin/$BRANCH is already up to date — nothing to push."
else
  log "Pushing to origin/$BRANCH (GitHub Pages will rebuild automatically)..."
  git push origin "$BRANCH"
fi

record_deploy "static" "$(git rev-parse --short HEAD)"
log "Deploy complete: pushed $(git rev-parse --short HEAD) to $BRANCH."
log "Live at: https://priyankraj.github.io/ledger-flow-walkthrough-temp/"
