#!/bin/bash
LOG_FILE="sync-upstream-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting upstream sync..."

# Fetch upstream
log "Fetching upstream..."
git fetch upstream 2>&1 | tee -a "$LOG_FILE"

# Show new commits
log "New commits from upstream:"
git log --oneline HEAD..upstream/main | tee -a "$LOG_FILE"

# Prompt for each commit
git log --reverse --format="%H %s" HEAD..upstream/main | while read hash message; do
    echo ""
    read -p "Apply commit $hash ($message)? [y=yes, a=all, n=skip, q=quit]: " choice
    
    case $choice in
        [Yy]*) 
            log "Applying $hash..."
            git cherry-pick $hash 2>&1 | tee -a "$LOG_FILE"
            ;;
        [Aa]*) 
            log "Applying all remaining commits..."
            git cherry-pick HEAD..upstream/main 2>&1 | tee -a "$LOG_FILE"
            break
            ;;
        [Qq]*) 
            log "Quit by user."
            break
            ;;
        *) 
            log "Skipping $hash"
            ;;
    esac
done

log "Sync complete."