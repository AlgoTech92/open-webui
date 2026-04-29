#!/bin/bash
LOG_FILE="release-monitor-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Checking for new upstream releases..."

git fetch upstream --tags 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "Latest upstream tags:"
git tag --sort=-v:refname | head -10 | tee -a "$LOG_FILE"

log "Release check complete."