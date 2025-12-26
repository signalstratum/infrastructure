# Consolidated outputs for all resources
#
# Connectivity outputs verify provider authentication works.
# Resource outputs expose IDs and configuration for reference.

# -----------------------------------------------------------------------------
# Connectivity Verification
# -----------------------------------------------------------------------------

output "cloudflare_connectivity" {
  description = "Cloudflare connectivity verification"
  value = {
    status = "✅ Connected"
    zones = {
      com = {
        name   = data.cloudflare_zone.com.name
        status = data.cloudflare_zone.com.status
      }
      io = {
        name   = data.cloudflare_zone.io.name
        status = data.cloudflare_zone.io.status
      }
    }
  }
}

output "github_connectivity" {
  description = "GitHub connectivity verification"
  value = {
    status           = "✅ Connected"
    organization     = data.github_organization.signalstratum.name
    authenticated_as = data.github_user.current.login
  }
}

# -----------------------------------------------------------------------------
# Cloudflare Resources
# -----------------------------------------------------------------------------

output "virginia_tunnel_id" {
  description = "Cloudflare Tunnel ID for Virginia cluster"
  value       = cloudflare_zero_trust_tunnel_cloudflared.virginia_talos.id
}

output "virginia_tunnel_token" {
  description = "Tunnel token for cloudflared connector"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.virginia_talos.token
  sensitive   = true
}

output "home_tunnel_id" {
  description = "Cloudflare Tunnel ID for home LAN"
  value       = cloudflare_zero_trust_tunnel_cloudflared.home_lan.id
}

output "home_tunnel_token" {
  description = "Tunnel token for home LAN cloudflared connector"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.home_lan.token
  sensitive   = true
}

output "gateway_dns_location" {
  description = "Gateway DNS location for router configuration"
  value = {
    name                 = cloudflare_zero_trust_dns_location.home_lan.name
    doh_subdomain        = cloudflare_zero_trust_dns_location.home_lan.doh_subdomain
    ipv4_destination     = cloudflare_zero_trust_dns_location.home_lan.ipv4_destination
    ipv4_destination_alt = cloudflare_zero_trust_dns_location.home_lan.ipv4_destination_backup
  }
}

output "email_routing" {
  description = "Email routing configuration"
  value = {
    destination = local.email_destination
    domains     = [local.zones.com.name, local.zones.io.name]
  }
}

output "security_settings" {
  description = "Zone security configuration summary"
  value = {
    tls_mode       = "strict"
    min_tls        = "1.2"
    security_level = "medium"
  }
}

# -----------------------------------------------------------------------------
# GitHub Resources
# -----------------------------------------------------------------------------

output "repositories" {
  description = "Managed GitHub repositories"
  value = {
    infrastructure = module.repo_infrastructure.repository
    talos_clusters = module.repo_talos_clusters.repository
  }
}
