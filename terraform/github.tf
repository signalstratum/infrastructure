# -----------------------------------------------------------------------------
# GitHub Data Sources
# -----------------------------------------------------------------------------

data "github_organization" "signalstratum" {
  name = "signalstratum"
}

data "github_user" "current" {
  username = "" # Empty string returns authenticated user
}

# -----------------------------------------------------------------------------
# Repository: infrastructure
# -----------------------------------------------------------------------------

resource "github_repository" "infrastructure" {
  name        = "infrastructure"
  description = "Infrastructure as Code for Signal Stratum"
  visibility  = "public"

  # Disable features we don't need
  has_issues      = true
  has_wiki        = false
  has_projects    = false
  has_downloads   = false
  has_discussions = false

  # Security settings
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Vulnerability alerts
  vulnerability_alerts = true

  # Archive on destroy instead of delete (safety)
  archive_on_destroy = true
}

# -----------------------------------------------------------------------------
# Branch Protection: main
# -----------------------------------------------------------------------------

resource "github_branch_protection" "main" {
  repository_id = github_repository.infrastructure.node_id
  pattern       = "main"

  # Require PR before merging
  required_pull_request_reviews {
    required_approving_review_count = 0 # Solo developer, no required approvers
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false

    # Only I can bypass PR requirement and merge
    pull_request_bypassers = [
      data.github_user.current.node_id
    ]
  }

  # Require status checks
  required_status_checks {
    strict   = true # Require branch is up to date before merging
    contexts = ["Terraform"]
  }

  # Require signed commits
  require_signed_commits = true

  # Require linear history (no merge commits)
  required_linear_history = true

  # Require conversation resolution
  require_conversation_resolution = true

  # Block force pushes and deletions
  allows_force_pushes = false
  allows_deletions    = false

  # Enforce for admins too
  enforce_admins = true

  # Restrict who can push to main (only me)
  restrict_pushes {
    blocks_creations = true
    push_allowances = [
      data.github_user.current.node_id
    ]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "github_connectivity" {
  description = "GitHub connectivity verification"
  value = {
    status = "✅ Connected"
    organization = {
      name        = data.github_organization.signalstratum.name
      description = data.github_organization.signalstratum.description
      plan        = data.github_organization.signalstratum.plan
    }
    authenticated_as = data.github_user.current.login
  }
}

output "github_repository" {
  description = "Infrastructure repository configuration"
  value = {
    name              = github_repository.infrastructure.name
    url               = github_repository.infrastructure.html_url
    visibility        = github_repository.infrastructure.visibility
    branch_protection = "main (signed commits required)"
  }
}
