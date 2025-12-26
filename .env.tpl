# Provider authentication (env vars)
GITHUB_TOKEN=op://ss-infrastructure/github/api-token
CLOUDFLARE_API_TOKEN=op://ss-infrastructure/cloudflare/api-token

# R2 backend (S3-compatible)
AWS_ACCESS_KEY_ID=op://ss-infrastructure/r2/access-key-id
AWS_SECRET_ACCESS_KEY=op://ss-infrastructure/r2/secret-access-key
AWS_ENDPOINT_URL_S3=op://ss-infrastructure/r2/url

# 1Password provider (for writing secrets)
OP_SERVICE_ACCOUNT_TOKEN=op://SignalStratum/1password-sa/tf-managed

# GitHub App - Signal Stratum Infra (Cloudflare Zero Trust OAuth)
TF_VAR_github_app_client_id=op://ss-infrastructure/github/github-app-client-id
TF_VAR_github_app_client_secret=op://ss-infrastructure/github/github-app-client-secret

# GitHub App - Signal Stratum Infra (ARC - Actions Runner Controller)
TF_VAR_github_app_id=op://ss-infrastructure/github/github-app-id
TF_VAR_github_app_installation_id=op://ss-infrastructure/github/github-app-installation-id
TF_VAR_github_app_private_key=op://ss-infrastructure/github/github-app-private-key
