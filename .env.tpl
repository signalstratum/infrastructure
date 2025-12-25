# Provider authentication (env vars)
GITHUB_TOKEN=op://ss-infrastructure/github/api-token
CLOUDFLARE_API_TOKEN=op://ss-infrastructure/cloudflare/api-token

# R2 backend (S3-compatible)
AWS_ACCESS_KEY_ID=op://ss-infrastructure/r2/access-key-id
AWS_SECRET_ACCESS_KEY=op://ss-infrastructure/r2/secret-access-key
AWS_ENDPOINT_URL_S3=op://ss-infrastructure/r2/url

# 1Password provider (for writing secrets)
OP_SERVICE_ACCOUNT_TOKEN=op://SignalStratum/1password-sa/tf-managed
