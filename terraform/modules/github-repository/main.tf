# GitHub Repository Module
# See README.md for usage documentation

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "name" {
  type        = string
  description = "Repository name"
}

variable "description" {
  type        = string
  description = "Repository description"
}

variable "visibility" {
  type        = string
  default     = "private"
  description = "Repository visibility: public, private, or internal"
  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be public, private, or internal"
  }
}

variable "has_issues" {
  type        = bool
  default     = true
  description = "Enable issues"
}

variable "auto_init" {
  type        = bool
  default     = false
  description = "Initialize with README"
}

variable "topics" {
  type        = list(string)
  default     = []
  description = "Repository topics/tags"
}

variable "enable_branch_protection" {
  type        = bool
  default     = true
  description = "Enable branch protection (disable if using org ruleset)"
}

variable "required_status_checks" {
  type        = list(string)
  default     = ["Terraform"]
  description = "Required CI status checks before merge"
}

variable "owner_bypass_node_id" {
  type        = string
  description = "Node ID of user who can bypass branch protection"
}

variable "homepage_url" {
  type        = string
  default     = null
  description = "Repository homepage URL"
}

variable "is_template" {
  type        = bool
  default     = false
  description = "Mark as template repository"
}

variable "template" {
  type = object({
    owner      = string
    repository = string
  })
  default     = null
  description = "Template repository to use"
}

resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  visibility   = var.visibility
  homepage_url = var.homepage_url

  # Features
  has_issues      = var.has_issues
  has_wiki        = false
  has_projects    = false
  has_downloads   = false
  has_discussions = false

  # Merge settings (squash only, clean history)
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Security
  vulnerability_alerts = true
  archive_on_destroy   = true

  # Template
  is_template = var.is_template
  auto_init   = var.auto_init
  topics      = var.topics

  dynamic "template" {
    for_each = var.template != null ? [var.template] : []
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }
}

resource "github_branch_protection" "main" {
  count = var.enable_branch_protection ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = "main"

  # PR requirements (solo dev: 0 approvers, owner can bypass)
  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
    pull_request_bypassers          = [var.owner_bypass_node_id]
  }

  # CI requirements
  required_status_checks {
    strict   = true
    contexts = var.required_status_checks
  }

  # Security requirements
  require_signed_commits          = true
  required_linear_history         = true
  require_conversation_resolution = true

  # Lock down main branch
  allows_force_pushes = false
  allows_deletions    = false
  enforce_admins      = true

  # Restrict pushes (owner only)
  restrict_pushes {
    blocks_creations = true
    push_allowances  = [var.owner_bypass_node_id]
  }
}

output "repository" {
  description = "Repository details"
  value = {
    name          = github_repository.this.name
    full_name     = github_repository.this.full_name
    url           = github_repository.this.html_url
    ssh_clone_url = github_repository.this.ssh_clone_url
    node_id       = github_repository.this.node_id
    visibility    = github_repository.this.visibility
  }
}

output "node_id" {
  description = "Repository node ID for use in other resources"
  value       = github_repository.this.node_id
}
