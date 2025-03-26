#!/bin/bash
set -e

echo "--- GitHub Actions Secrets Setup ---"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI ('gh') not found. Please install it first."
    echo "See: https://cli.github.com/"
    exit 1
fi

# Check gh auth status
if ! gh auth status &>/dev/null; then
 echo "Error: Not logged into GitHub CLI. Please run 'gh auth login'."
 exit 1
fi

# --- Configuration ---
DEFAULT_SSH_KEY_FILE="deploy_key" # Assumes key from setup_ssh_access.sh
DEFAULT_ENV_FILE=".env"
DEFAULT_SERVER_PORT="22"
# --- End Configuration ---

# 1. Get Repository Info
echo "Enter the GitHub repository (e.g., your-username/your-repo-name):"
read GITHUB_REPO
if [[ -z "$GITHUB_REPO" ]]; then
    echo "Error: GitHub repository cannot be empty."
    exit 1
fi
# Simple validation
if ! [[ "$GITHUB_REPO" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
    echo "Error: Invalid repository format. Use 'owner/repo'."
    exit 1
fi

# 2. Get Secret Values
read -p "Enter the Server Host/IP address (SERVER_HOST): " SERVER_HOST
read -p "Enter the Server Deployment Username (SERVER_USER): " SERVER_USER
read -p "Enter the Server SSH Port [${DEFAULT_SERVER_PORT}]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-$DEFAULT_SERVER_PORT}
read -p "Enter the path to the PRIVATE SSH key file [${DEFAULT_SSH_KEY_FILE}]: " SSH_KEY_FILE
SSH_KEY_FILE=${SSH_KEY_FILE:-$DEFAULT_SSH_KEY_FILE}
read -p "Enter the path to the production .env file [${DEFAULT_ENV_FILE}]: " ENV_FILE_PATH
ENV_FILE_PATH=${ENV_FILE_PATH:-$DEFAULT_ENV_FILE}
read -p "Enter your GitHub PAT with read:packages scope (GHCR_PAT_OR_TOKEN): " GHCR_PAT_OR_TOKEN

# Validate inputs
if [[ -z "$SERVER_HOST" ]] || [[ -z "$SERVER_USER" ]] || [[ -z "$GHCR_PAT_OR_TOKEN" ]]; then
    echo "Error: Server Host, Server User, and GHCR PAT cannot be empty."
    exit 1
fi
if [[ ! -f "$SSH_KEY_FILE" ]]; then
    echo "Error: SSH private key file not found at '$SSH_KEY_FILE'."
    exit 1
fi
if [[ ! -f "$ENV_FILE_PATH" ]]; then
    echo "Error: .env file not found at '$ENV_FILE_PATH'."
    exit 1
fi


echo "---------------------------------"
echo "Secrets to be set for repo '$GITHUB_REPO':"
echo "SERVER_HOST:       $SERVER_HOST"
echo "SERVER_USER:       $SERVER_USER"
echo "SERVER_PORT:       $SERVER_PORT"
echo "SSH_PRIVATE_KEY:   (from file $SSH_KEY_FILE)"
echo "ENV_FILE:          (from file $ENV_FILE_PATH)"
echo "GHCR_PAT_OR_TOKEN: (provided)"
echo "---------------------------------"
read -p "Proceed? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# 3. Set Secrets using gh cli
echo "Setting secrets..."

gh secret set SERVER_HOST --body "$SERVER_HOST" --repo "$GITHUB_REPO"
gh secret set SERVER_USER --body "$SERVER_USER" --repo "$GITHUB_REPO"
gh secret set SERVER_PORT --body "$SERVER_PORT" --repo "$GITHUB_REPO"
gh secret set SSH_PRIVATE_KEY < "$SSH_KEY_FILE" --repo "$GITHUB_REPO"
gh secret set ENV_FILE < "$ENV_FILE_PATH" --repo "$GITHUB_REPO"
gh secret set GHCR_PAT_OR_TOKEN --body "$GHCR_PAT_OR_TOKEN" --repo "$GITHUB_REPO"

echo "--- GitHub Secrets set successfully! ---"