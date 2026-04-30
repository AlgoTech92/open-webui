#!/bin/bash
set -euo pipefail

# === Configuration ===
LOG_FILE="merge-helper-$(date +%Y%m%d-%H%M%S).log"
MERGE_PATHS=(
  "dev-to-test:development:testing"
  "test-to-prod:testing:aisyncapp"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# === Logging Functions ===
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
  log "${RED}ERROR: $1${NC}"
  exit 1
}

success() {
  log "${GREEN}SUCCESS: $1${NC}"
}

usage() {
  echo "Usage: $0 [merge-path] [--push|--no-push]"
  echo ""
  echo "Merge helper for AiSyncapp branch workflow"
  echo "Predefined merge paths (matches your hierarchy: dev → testing → aisyncapp):"
  for path in "${MERGE_PATHS[@]}"; do
    IFS=':' read -r name source target <<< "$path"
    echo "  $name: Merge $source → $target"
  done
  echo ""
  echo "Options:"
  echo "  --push: Auto-push target branch to origin after merge"
  echo "  --no-push: Skip pushing to origin"
  echo "  (Default: Ask for push confirmation interactively)"
  echo "  --help: Show this message"
  exit 0
}

# === Argument Parsing ===
MERGE_PATH=""
PUSH_FLAG="ask"

while [[ $# -gt 0 ]]; do
  case $1 in
    --push)
      PUSH_FLAG="true"
      shift
      ;;
    --no-push)
      PUSH_FLAG="false"
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      if [ -z "$MERGE_PATH" ]; then
        MERGE_PATH="$1"
      else
        echo "Unknown argument: $1"
        usage
      fi
      shift
      ;;
  esac
done

# Validate merge path
if [ -z "$MERGE_PATH" ]; then
  echo "Error: No merge path specified."
  usage
fi

# Extract source/target branches
SOURCE_BRANCH=""
TARGET_BRANCH=""
for path in "${MERGE_PATHS[@]}"; do
  IFS=':' read -r name source target <<< "$path"
  if [ "$name" = "$MERGE_PATH" ]; then
    SOURCE_BRANCH="$source"
    TARGET_BRANCH="$target"
    break
  fi
done

if [ -z "$SOURCE_BRANCH" ] || [ -z "$TARGET_BRANCH" ]; then
  error "Invalid merge path: $MERGE_PATH. Valid options: dev-to-test, test-to-prod"
fi

# Block merges to/from main (main tracks upstream, must stay clean)
if [ "$TARGET_BRANCH" = "main" ] || [ "$SOURCE_BRANCH" = "main" ]; then
  error "Cannot merge to/from main branch. Main tracks upstream and must stay clean. Use sync-upstream-cron.sh for main updates."
fi

log "Starting merge helper: $MERGE_PATH ($SOURCE_BRANCH → $TARGET_BRANCH)"
log "Log file: $LOG_FILE"

# === Repo Safety Checks ===
# Check if inside git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  error "Not inside a git repository."
fi

# Check origin is correct fork
ORIGIN_URL=$(git remote get-url origin)
if [[ ! "$ORIGIN_URL" =~ AlgoTech92/open-webui ]]; then
  error "Origin remote is not AlgoTech92/open-webui. Current origin: $ORIGIN_URL"
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  error "Working directory has uncommitted changes. Commit or stash them first."
fi

# === Fetch Latest Changes ===
log "Fetching latest changes from origin..."
git fetch origin "$SOURCE_BRANCH" "$TARGET_BRANCH" || error "Failed to fetch from origin."

# === Verify New Commits Exist ===
log "Checking for new commits to merge..."
NEW_COMMITS=$(git log --oneline "$TARGET_BRANCH..$SOURCE_BRANCH" | wc -l)
if [ "$NEW_COMMITS" -eq 0 ]; then
  log "${YELLOW}No new commits to merge from $SOURCE_BRANCH to $TARGET_BRANCH. Exiting.${NC}"
  exit 0
fi
log "Found $NEW_COMMITS new commit(s) to merge."

# === Perform Merge ===
log "Checking out target branch: $TARGET_BRANCH"
git checkout "$TARGET_BRANCH" || error "Failed to checkout $TARGET_BRANCH."

log "Pulling latest $TARGET_BRANCH from origin..."
git pull origin "$TARGET_BRANCH" || error "Failed to pull latest $TARGET_BRANCH."

log "Merging $SOURCE_BRANCH into $TARGET_BRANCH (--no-ff to preserve history)..."
if git merge --no-ff "$SOURCE_BRANCH" -m "Merge $SOURCE_BRANCH into $TARGET_BRANCH"; then
  success "Merge completed successfully."
else
  error "Merge conflict detected. Resolve conflicts manually, then run: git merge --continue"
fi

# === Push to Origin ===
if [ "$PUSH_FLAG" = "ask" ]; then
  read -p "Push $TARGET_BRANCH to origin? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    PUSH_FLAG="true"
  else
    PUSH_FLAG="false"
  fi
fi

if [ "$PUSH_FLAG" = "true" ]; then
  log "Pushing $TARGET_BRANCH to origin..."
  git push origin "$TARGET_BRANCH" || error "Failed to push $TARGET_BRANCH to origin."
  success "Pushed $TARGET_BRANCH to origin."
else
  log "Skipping push to origin. Remember to push manually if needed."
fi

success "Merge helper completed for $MERGE_PATH."
