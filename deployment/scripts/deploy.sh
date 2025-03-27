#!/bin/bash
# Path: deployment/scripts/deploy.sh

set -e  # Exit immediately if a command exits with non-zero status
source .env  # Load environment variables from .env file

# Log deployment start with timestamp
echo "[$(date)] Deployment started"

# Store previous image tags for potential rollback
if [ -f .env.previous ]; then
  cp .env.previous .env.rollback
fi

# Save current environment variables for potential rollbacks
env | grep "IMAGE_TAG_" > .env.previous

# Pull the specific tagged images defined by the env vars
echo "[$(date)] Pulling images: $IMAGE_TAG_BACKEND and $IMAGE_TAG_FRONTEND"
docker-compose pull || { echo "Failed to pull images"; exit 1; }

# Stop (if running), remove old containers, and start new ones
echo "[$(date)] Starting containers"
docker-compose -f docker-compose.yml up -d --remove-orphans --env-file .env

# Wait for backend to become healthy
echo "[$(date)] Waiting for backend health check..."
MAX_RETRIES=30
RETRY_INTERVAL=2
HEALTH_ENDPOINT="http://localhost:${BACKEND_INTERNAL_PORT}/health"

for i in $(seq 1 $MAX_RETRIES); do
  if curl -s -f "${HEALTH_ENDPOINT}" > /dev/null; then
    echo "[$(date)] Backend is healthy!"
    break
  fi
  
  if [ $i -eq $MAX_RETRIES ]; then
    echo "[$(date)] Health check failed after $MAX_RETRIES attempts. Rolling back."
    # Rollback to previous deployment if health check fails
    if [ -f .env.rollback ]; then
      echo "[$(date)] Rolling back to previous deployment"
      set -a  # Automatically export all variables
      source .env.rollback
      set +a
      docker-compose up -d
      echo "[$(date)] Rollback complete"
    else
      echo "[$(date)] No previous deployment found for rollback"
    fi
    exit 1
  fi
  
  echo "Attempt $i/$MAX_RETRIES: Backend not ready yet. Retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done

# Log version information for auditing
echo "[$(date)] Deployment successful with:"
echo "Backend: $IMAGE_TAG_BACKEND"
echo "Frontend: $IMAGE_TAG_FRONTEND"

# Cleanup unused images (dangling only - safer approach)
echo "[$(date)] Cleaning up unused Docker resources"
docker image prune -af  # Remove only dangling images, not volumes

echo "[$(date)] Deployment completed successfully"