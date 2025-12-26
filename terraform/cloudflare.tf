# Cloudflare Resources
#
# All Cloudflare configuration for signalstratum.com and signalstratum.io:
#   - Zone data sources (connectivity verification)
#   - Zero Trust Tunnel (Virginia Talos cluster access)
#   - Zero Trust WARP client settings (split tunnels, enrollment)
#   - Zero Trust Gateway (DNS filtering, logging)
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
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "virginia_talos" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id

  config = {
    warp_routing = { enabled = true }
    ingress = [
      {
        hostname = "kube.signalstratum.com"
        service  = "tcp://localhost:6443"
      },
      {
        hostname = "kube.signalstratum.io"
        service  = "tcp://localhost:6443"
      },
      { service = "http_status:404" } # catch-all
    ]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "virginia_private_network" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id
  network    = "10.0.1.0/24"
  comment    = "Virginia Talos cluster nodes - K8s/Talos API access"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "virginia_talos" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id

  depends_on = [cloudflare_zero_trust_tunnel_cloudflared.virginia_talos]
}

# =============================================================================
# ZERO TRUST TUNNEL - Home LAN (tool-chain.io)
# =============================================================================
# Zero-trust access to home network via WARP:
#   1. Cloudflared runs on Talos worker nodes (system extension)
#   2. Tunnel exposes home LAN CIDR (192.168.1.0/24)
#   3. Users connect via Cloudflare WARP client when remote
#   4. Enables access to home k8s nodes, NAS, and other infrastructure

resource "cloudflare_zero_trust_tunnel_cloudflared" "home_lan" {
  account_id = local.cloudflare_account_id
  name       = "home-lan"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "home_lan" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.home_lan.id

  config = {
    warp_routing = { enabled = true }
    ingress      = [{ service = "http_status:404" }]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "home_private_network" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.home_lan.id
  network    = "192.168.1.0/24"
  comment    = "Home LAN - tool-chain.io (k8s nodes, infrastructure)"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "home_lan" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.home_lan.id

  depends_on = [cloudflare_zero_trust_tunnel_cloudflared.home_lan]
}

# Store home tunnel credentials in 1Password
module "onepassword_home_tunnel" {
  count  = local.onepassword_enabled ? 1 : 0
  source = "./modules/onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = "Cloudflare Tunnel - Home LAN"
  category = "password"
  url      = "https://one.dash.cloudflare.com/"

  fields = {
    tunnel_id    = cloudflare_zero_trust_tunnel_cloudflared.home_lan.id
    tunnel_token = data.cloudflare_zero_trust_tunnel_cloudflared_token.home_lan.token
  }

  tags  = ["terraform", "cloudflare", "home-lan", "tunnel"]
  notes = "Cloudflare Tunnel for home LAN (tool-chain.io). Used by Talos worker nodes. Managed by Terraform."
}

# =============================================================================
# ZERO TRUST ACCESS - Enrollment & Identity
# =============================================================================
# Identity providers for WARP device enrollment
# Allows: GitHub org members, email OTP as fallback

resource "cloudflare_zero_trust_access_identity_provider" "email_otp" {
  account_id = local.cloudflare_account_id
  name       = "Email OTP"
  type       = "onetimepin"
  config     = {}
}

resource "cloudflare_zero_trust_access_identity_provider" "github" {
  count      = var.github_oauth_client_id != "" ? 1 : 0
  account_id = local.cloudflare_account_id
  name       = "GitHub"
  type       = "github"

  config = {
    client_id     = var.github_oauth_client_id
    client_secret = var.github_oauth_client_secret
  }
}

resource "cloudflare_zero_trust_access_group" "allowed_users" {
  account_id = local.cloudflare_account_id
  name       = "Allowed Users - WARP Enrollment"

  include = [
    { email = { email = "jaredhawkins@tool-chain.io" } },
    { email_domain = { domain = "signalstratum.com" } },
    { email_domain = { domain = "signalstratum.io" } }
  ]
}

# Access group for GitHub org members (when GitHub IdP is configured)
resource "cloudflare_zero_trust_access_group" "github_org_members" {
  count      = var.github_oauth_client_id != "" ? 1 : 0
  account_id = local.cloudflare_account_id
  name       = "GitHub - signalstratum org"

  include = [
    {
      github_organization = {
        name                 = "signalstratum"
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.github[0].id
      }
    }
  ]
}

# WARP Device Enrollment - allows users to enroll devices via WARP client
resource "cloudflare_zero_trust_access_application" "warp_enrollment" {
  account_id = local.cloudflare_account_id
  name       = "Warp Login App" # Cloudflare's default name for WARP enrollment
  type       = "warp"

  session_duration = "720h" # 30 days

  # Allow both GitHub and Email OTP login methods
  allowed_idps = concat(
    [cloudflare_zero_trust_access_identity_provider.email_otp.id],
    var.github_oauth_client_id != "" ? [cloudflare_zero_trust_access_identity_provider.github[0].id] : []
  )

  # Enrollment policy - who can enroll devices
  policies = [
    {
      name     = "Allow signalstratum users"
      decision = "allow"
      include = [
        { group = { id = cloudflare_zero_trust_access_group.allowed_users.id } }
      ]
    }
  ]
}

# =============================================================================
# ZERO TRUST GATEWAY - DNS Location
# =============================================================================
# DNS location for Gateway filtering and logging
# Configure router to use these DNS servers for Zero Trust visibility

resource "cloudflare_zero_trust_dns_location" "home_lan" {
  account_id = local.cloudflare_account_id
  name       = "Home LAN - tool-chain.io"

  # Networks that will use this DNS location (for identification)
  # Note: Home IP is dynamic, so this uses DNS-over-HTTPS for identification
  networks = []

  # Enables ECS (EDNS Client Subnet) for better geo-routing
  ecs_support = false
}

# =============================================================================
# ZERO TRUST DEVICE SETTINGS
# =============================================================================
# Default WARP client profile - configures split tunnel routing
# Uses "Include" mode - only specified CIDRs go through WARP, rest goes direct.

resource "cloudflare_zero_trust_device_default_profile" "warp_settings" {
  account_id = local.cloudflare_account_id

  # Split tunnel: Include mode - route only these CIDRs through WARP
  include = [
    # Hetzner Cloud - Virginia Talos cluster
    {
      address     = "10.0.0.0/16"
      description = "Hetzner Cloud private network - Virginia Talos cluster"
    },
    {
      address     = "10.244.0.0/16"
      description = "Kubernetes Pod CIDR - Virginia Talos cluster"
    },
    {
      address     = "10.96.0.0/12"
      description = "Kubernetes Service CIDR - Virginia Talos cluster"
    },
    # Home LAN - tool-chain.io
    {
      address     = "192.168.1.0/24"
      description = "Home LAN - tool-chain.io (k8s nodes, infrastructure)"
    }
  ]

  # WARP mode (full tunnel with Gateway)
  service_mode_v2 = {
    mode = "warp"
  }

  # Client behavior
  allowed_to_leave  = true
  allow_mode_switch = true
  allow_updates     = true
  auto_connect      = 0
  switch_locked     = false
  captive_portal    = 180
  tunnel_protocol   = "wireguard"
  support_url       = "https://signalstratum.com"
}

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

# Kubernetes API - routed through Cloudflare tunnel to localhost:6443
# Client must use: cloudflared access tcp --hostname kube.signalstratum.com --url localhost:6443
# Then: kubectl --server=https://localhost:6443
resource "cloudflare_dns_record" "com_kube" {
  zone_id = local.zones.com.zone_id
  name    = "kube"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id}.cfargotunnel.com"
  ttl     = 1    # Auto TTL when proxied
  proxied = true # Required for tunnel ingress routing
  comment = "Virginia Talos cluster API - TCP tunnel to localhost:6443"
}

resource "cloudflare_dns_record" "io_kube" {
  zone_id = local.zones.io.zone_id
  name    = "kube"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  comment = "Virginia Talos cluster API - TCP tunnel to localhost:6443"
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
