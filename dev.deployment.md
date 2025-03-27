1. Development builds → Development server (from dev branch)
2. Production builds → Production server (from main branch)

## 1. Additional GitHub Secrets for Development

For the development workflow, add these secrets:

- `DEV_SERVER_HOST`: Hostname/IP of your development server
- `DEV_SERVER_USER`: SSH username for development server
- `DEV_SSH_PRIVATE_KEY`: SSH private key for development server access
- `DEV_ENV_FILE`: Contents of your .env.development file
- `DEV_PORT`: Port number for verification

## 2. Environment-Specific docker-compose Files

I've created a `docker-compose.dev.yml` file that includes:

- Development-specific configuration
- Environment indicators (`ENVIRONMENT: "development"`)
- Different container names to avoid conflicts with production
- Reference to a development-specific nginx configuration

## 3. Tagging Strategy

The workflow implements a proper tagging strategy:

- Production: `ghcr.io/username/repo/service:latest`
- Development: `ghcr.io/username/repo/service:dev`
- Versioned: `ghcr.io/username/repo/service:dev-20241027-a1b2c3d`

## 4. Key Differences Between Dev and Prod Workflows

- **Target Branches**:

  - Production deploys from `main`
  - Development deploys from `dev`

- **Environment Variables**:

  - Uses `DEV_` prefixed secrets for development
  - Passes `ENVIRONMENT=development` to builds

- **Compose File**:

  - Production uses `docker-compose.yml`
  - Development uses `docker-compose.dev.yml`

- **Image Tags**:
  - Production uses `:latest`
  - Development uses `:dev`

## 5. To Complete This Setup

1. Create a development-specific nginx configuration:

   ```
   cp nginx.conf nginx.dev.conf
   # Modify as needed for development
   ```

2. Add the new secrets for the development environment:
   ```bash
   gh secret set DEV_SERVER_HOST --body "dev-server-hostname"
   gh secret set DEV_SERVER_USER --body "username"
   gh secret set DEV_SSH_PRIVATE_KEY < dev_deploy_key
   gh secret set DEV_ENV_FILE < .env.development
   gh secret set DEV_PORT --body "8091"
   ```

This approach gives:

- Complete separation between environments
- Environment-specific configurations
- The same deployment mechanism for both
- Easy tracking of which commits are in which environment
