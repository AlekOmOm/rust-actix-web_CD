#!/bin/bash
# Pull the specific tagged images defined by the env vars
docker-compose pull

# Stop (if running), remove old containers, and start new ones based on the pulled images
# --remove-orphans removes containers for services no longer defined in compose file
docker-compose up -d --remove-orphans

# Cleanup unused images (dangling and unreferenced)
docker image prune -af

