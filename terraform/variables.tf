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
