# Cloudflare Resources
#
# All Cloudflare configuration for signalstratum.com and signalstratum.io:
#   - Zone data sources (connectivity verification)
#   - Zero Trust Tunnel (Virginia Talos cluster access)
#   - DNS records
#   - Email routing
#   - Security settings (TLS, HTTPS)

# =============================================================================
# DATA SOURCES
# =============================================================================

data "cloudflare_zone" "com" {
  zone_id = local.zones.com.zone_id
}

data "cloudflare_zone" "io" {
  zone_id = local.zones.io.zone_id
}

# =============================================================================
# ZERO TRUST TUNNEL - Virginia Talos Cluster
# =============================================================================
# Zero-trust access to Hetzner Cloud private network via WARP:
#   1. Cloudflared runs on Talos nodes (system extension)
#   2. Tunnel exposes private network CIDR (10.0.0.0/16)
#   3. Users connect via Cloudflare WARP client
#   4. WARP routes traffic to private IPs through tunnel

resource "cloudflare_zero_trust_tunnel_cloudflared" "virginia_talos" {
  account_id = local.cloudflare_account_id
  name       = "virginia-talos"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "virginia_talos" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id

  config = {
    warp_routing = { enabled = true }
    ingress      = [{ service = "http_status:404" }]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "virginia_private_network" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id
  network    = "10.0.0.0/16"
  comment    = "Hetzner Cloud private network - Virginia Talos cluster"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "virginia_talos" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id
}

# NOTE: Split tunnel "Include" for 10.0.0.0/16 must be configured manually:
# Cloudflare Dashboard → Settings → WARP Client → Device settings → Split Tunnels

# Store tunnel credentials in 1Password
module "onepassword_virginia_tunnel" {
  count  = local.onepassword_enabled ? 1 : 0
  source = "./modules/onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = "Cloudflare Tunnel - Virginia Talos"
  category = "password"
  url      = "https://one.dash.cloudflare.com/"

  fields = {
    tunnel_id    = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id
    tunnel_token = data.cloudflare_zero_trust_tunnel_cloudflared_token.virginia_talos.token
  }

  tags  = ["terraform", "cloudflare", "virginia-talos", "tunnel"]
  notes = "Cloudflare Tunnel for Virginia Talos cluster. Managed by Terraform."
}

# =============================================================================
# DNS RECORDS
# =============================================================================

# Kubernetes API - private IP accessed via WARP tunnel
resource "cloudflare_dns_record" "com_kube" {
  zone_id = local.zones.com.zone_id
  name    = "kube"
  type    = "A"
  content = "10.0.1.100"
  ttl     = 300
  proxied = false
  comment = "Virginia Talos cluster API - private IP via WARP"
}

resource "cloudflare_dns_record" "io_kube" {
  zone_id = local.zones.io.zone_id
  name    = "kube"
  type    = "CNAME"
  content = "kube.signalstratum.com"
  ttl     = 300
  proxied = false
  comment = "Alias to .com for Virginia Talos cluster"
}

# DMARC records for email authentication
resource "cloudflare_dns_record" "com_dmarc" {
  zone_id = local.zones.com.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${local.zones.com.name}"
  ttl     = 3600
}

resource "cloudflare_dns_record" "io_dmarc" {
  zone_id = local.zones.io.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${local.zones.io.name}"
  ttl     = 3600
}

# =============================================================================
# EMAIL ROUTING
# =============================================================================
# Forwards all emails to gmail. MX/SPF records auto-created by cloudflare_email_routing_dns.

resource "cloudflare_email_routing_address" "primary" {
  account_id = local.cloudflare_account_id
  email      = local.email_destination
}

# signalstratum.com
resource "cloudflare_email_routing_settings" "com" {
  zone_id = local.zones.com.zone_id
}

resource "cloudflare_email_routing_dns" "com" {
  zone_id    = local.zones.com.zone_id
  depends_on = [cloudflare_email_routing_settings.com]
}

resource "cloudflare_email_routing_catch_all" "com" {
  zone_id  = local.zones.com.zone_id
  enabled  = true
  name     = "Catch-all forward to ${local.email_destination}"
  matchers = [{ type = "all" }]
  actions  = [{ type = "forward", value = [local.email_destination] }]

  depends_on = [cloudflare_email_routing_dns.com, cloudflare_email_routing_address.primary]
}

# signalstratum.io
resource "cloudflare_email_routing_settings" "io" {
  zone_id = local.zones.io.zone_id
}

resource "cloudflare_email_routing_dns" "io" {
  zone_id    = local.zones.io.zone_id
  depends_on = [cloudflare_email_routing_settings.io]
}

resource "cloudflare_email_routing_catch_all" "io" {
  zone_id  = local.zones.io.zone_id
  enabled  = true
  name     = "Catch-all forward to ${local.email_destination}"
  matchers = [{ type = "all" }]
  actions  = [{ type = "forward", value = [local.email_destination] }]

  depends_on = [cloudflare_email_routing_dns.io, cloudflare_email_routing_address.primary]
}

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
# TLS and security configuration applied to both zones

# signalstratum.com
resource "cloudflare_zone_setting" "com_ssl" {
  zone_id    = local.zones.com.zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "com_always_use_https" {
  zone_id    = local.zones.com.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "com_min_tls_version" {
  zone_id    = local.zones.com.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "com_tls_1_3" {
  zone_id    = local.zones.com.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_zone_setting" "com_automatic_https_rewrites" {
  zone_id    = local.zones.com.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "com_security_level" {
  zone_id    = local.zones.com.zone_id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_setting" "com_brotli" {
  zone_id    = local.zones.com.zone_id
  setting_id = "brotli"
  value      = "on"
}

# signalstratum.io
resource "cloudflare_zone_setting" "io_ssl" {
  zone_id    = local.zones.io.zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "io_always_use_https" {
  zone_id    = local.zones.io.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "io_min_tls_version" {
  zone_id    = local.zones.io.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "io_tls_1_3" {
  zone_id    = local.zones.io.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_zone_setting" "io_automatic_https_rewrites" {
  zone_id    = local.zones.io.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "io_security_level" {
  zone_id    = local.zones.io.zone_id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_setting" "io_brotli" {
  zone_id    = local.zones.io.zone_id
  setting_id = "brotli"
  value      = "on"
}
