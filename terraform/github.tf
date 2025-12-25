# GitHub Resources
#
# Organization settings and repository configuration for signalstratum.

# =============================================================================
# DATA SOURCES
# =============================================================================

data "github_organization" "signalstratum" {
  name = "signalstratum"
}

data "github_user" "current" {
  username = "" # Empty string returns authenticated user
}

# =============================================================================
# ORGANIZATION SETTINGS
# =============================================================================

resource "github_actions_organization_permissions" "this" {
  allowed_actions      = "selected"
  enabled_repositories = "all"

  allowed_actions_config {
    github_owned_allowed = true
    patterns_allowed = [
      "1password/*",
      "cloudflare/*",
      "hashicorp/*",
    ]
  }
}

# =============================================================================
# REPOSITORIES
# =============================================================================

module "repo_infrastructure" {
  source = "./modules/github-repository"

  name        = "infrastructure"
  description = "Infrastructure as Code for Signal Stratum"
  visibility  = "public"

  owner_bypass_node_id   = local.owner_node_id
  required_status_checks = ["Terraform"]
  topics                 = ["terraform", "infrastructure-as-code", "cloudflare", "github"]
}

module "repo_talos_clusters" {
  source = "./modules/github-repository"

  name        = "talos-clusters"
  description = "Talos Kubernetes clusters on Hetzner Cloud with Cloudflare zero-trust access"
  visibility  = "public"
  auto_init   = true

  owner_bypass_node_id   = local.owner_node_id
  required_status_checks = ["Terraform"]
  topics                 = ["kubernetes", "talos", "hetzner-cloud", "terraform"]
}
