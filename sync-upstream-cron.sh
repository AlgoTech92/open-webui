#!/bin/bash
LOG_FILE="sync-upstream-cron-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting non-interactive upstream sync..."

# Fetch upstream
log "Fetching upstream..."
git fetch upstream 2>&1 | tee -a "$LOG_FILE"

# Check for new commits
NEW_COMMITS=$(git log --oneline HEAD..upstream/main)
if [ -z "$NEW_COMMITS" ]; then
    log "No new upstream commits. Exiting."
    exit 0
fi

# Log new commits
log "New commits from upstream:"
echo "$NEW_COMMITS" | tee -a "$LOG_FILE"

# Auto-cherry-pick all new commits (equivalent to pressing 'a' in original script)
log "Auto-cherry-picking all new commits..."
git cherry-pick HEAD..upstream/main 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "All commits cherry-picked successfully."
else
    log "ERROR: Cherry-pick failed. Manual intervention required."
    exit 1
fi

log "Sync complete. Log saved to $LOG_FILE."