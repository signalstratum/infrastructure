# Input Variables
#
# All values populated via TF_VAR_ environment variables from 1Password.
# See .env.tpl for the 1Password references.

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id_com" {
  description = "Zone ID for signalstratum.com"
  type        = string
}

variable "cloudflare_zone_id_io" {
  description = "Zone ID for signalstratum.io"
  type        = string
}

variable "onepassword_vault_id" {
  description = "1Password vault ID for storing Terraform-generated secrets (optional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# GitHub App - Signal Stratum Infra
# -----------------------------------------------------------------------------
# Used for: Cloudflare Zero Trust (OAuth)
# Stored in: ss-infrastructure/github (oauth-client-id, oauth-client-secret)

variable "github_oauth_client_id" {
  description = "GitHub OAuth App Client ID (for Cloudflare Zero Trust)"
  type        = string
  default     = ""
}

variable "github_oauth_client_secret" {
  description = "GitHub OAuth App Client Secret (for Cloudflare Zero Trust)"

  type        = string
  sensitive   = true
  default     = ""
}

# Commented out until ARC (Actions Runner Controller) is deployed
# variable "github_app_id" {
#   description = "GitHub App ID (for ARC)"
#   type        = string
#   default     = ""
# }
#
# variable "github_app_installation_id" {
#   description = "GitHub App Installation ID (for ARC)"
#   type        = string
#   default     = ""
# }
#
# variable "github_app_private_key" {
#   description = "GitHub App Private Key PEM (for ARC)"
#   type        = string
#   sensitive   = true
#   default     = ""
# }
