# Local values used across resources

locals {
  # Cloudflare
  cloudflare_account_id = var.cloudflare_account_id

  zones = {
    com = {
      name    = "signalstratum.com"
      zone_id = var.cloudflare_zone_id_com
    }
    io = {
      name    = "signalstratum.io"
      zone_id = var.cloudflare_zone_id_io
    }
  }

  # 1Password
  onepassword_enabled = var.onepassword_vault_id != null

  # GitHub
  owner_node_id = data.github_user.current.node_id

  # Email routing
  email_destination = "signalstratum@gmail.com"
}
