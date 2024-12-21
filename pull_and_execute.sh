#!/bin/bash

LOG_DIR="./log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/googledrive-sync.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >>"$LOG_FILE"
}

# Load environment variables from .env file
if [ -f .env ]; then
  # Export variables from .env
  set -a
  source .env
  set +a
else
  log_error ".env file not found. Please create one."
  exit 1
fi

# Variables
IMAGE_NAME="google-drive-diff-and-sync"
TAG="latest"

# Validate required variables
REQUIRED_VARS=("DOCKER_HUB_USERNAME" "SERVICE_KEY_PATH" "ROOT_DIRECTORY" "PARENT_FOLDERS")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    log_error "$var is not set. Please add it to the .env file." "ERROR"
    exit 1
  fi
done

FULL_IMAGE_NAME="$DOCKER_HUB_USERNAME/$IMAGE_NAME:$TAG"

# Set a registry pull timeout
TIMEOUT=10

# Function to cleanup background processes
cleanup() {
  # Kill the timer and docker pull if they're still running
  kill $TIMER_PID 2>/dev/null
  kill $DOCKER_PID 2>/dev/null
  # Wait for docker process to finish
  wait $DOCKER_PID 2>/dev/null
}

# Set trap for script interruption
trap cleanup EXIT

# Start docker pull in the background
docker pull "$FULL_IMAGE_NAME" &
DOCKER_PID=$!

# Start timer to wait for the timeout
(
  sleep "$TIMEOUT"
  if kill -0 $DOCKER_PID 2>/dev/null; then
    log "Docker pull timeout after ${TIMEOUT} seconds"
    kill $DOCKER_PID
  fi
) &
TIMER_PID=$!

# Wait for the docker pull to complete
if wait $DOCKER_PID; then
  log "Successfully pulled latest image"
else
  # Check if the process was killed by timeout
  if kill -0 $TIMER_PID 2>/dev/null; then
    log "Registry unavailable or pull failed, using cached image"
  else
    log "Pull timed out, using cached image"
  fi
fi

# Determine if the -l flag should be set
SYNC_TO_LOCAL_FLAG=""
if [ "$(echo "$SYNC_TO_LOCAL" | tr '[:upper:]' '[:lower:]')" == "true" ]; then
  SYNC_TO_LOCAL_FLAG="-l"
fi

log "Starting sync process"
docker run --rm \
  -v "$ROOT_DIRECTORY:/backup" \
  -v "$SERVICE_KEY_PATH:/app/service-key.json" \
  "$FULL_IMAGE_NAME" \
  -r /backup \
  -c /app/service-key.json \
  -p "$PARENT_FOLDERS" \
  $SYNC_TO_LOCAL_FLAG \
  1> >(while read line; do log "$line"; done) \
  2> >(while read line; do log_error "$line"; done)

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  log "Sync completed successfully"
else
  log_error "Sync failed with exit code $EXIT_CODE"
fi
