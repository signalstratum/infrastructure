# GitHub Repository Module

Creates a standardized GitHub repository with optional branch protection.

## Usage

```hcl
module "repo_example" {
  source = "./modules/github-repository"

  name        = "my-repo"
  description = "Example repository"
  visibility  = "private"

  owner_bypass_node_id   = data.github_user.current.node_id
  required_status_checks = ["Terraform", "Test"]

  topics = ["terraform", "example"]
}
```

## Features

- Consistent repository settings across all repos
- Squash-merge only with clean history
- Security defaults (vulnerability alerts, signed commits)
- Optional branch protection (disable if using org-wide ruleset)
- Solo developer optimized (owner bypass for PRs)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Repository name | `string` | - | yes |
| `description` | Repository description | `string` | - | yes |
| `visibility` | Repository visibility: public, private, or internal | `string` | `"private"` | no |
| `has_issues` | Enable issues | `bool` | `true` | no |
| `auto_init` | Initialize with README | `bool` | `false` | no |
| `topics` | Repository topics/tags | `list(string)` | `[]` | no |
| `enable_branch_protection` | Enable branch protection | `bool` | `true` | no |
| `required_status_checks` | Required CI status checks | `list(string)` | `["Terraform"]` | no |
| `owner_bypass_node_id` | Node ID of user who can bypass branch protection | `string` | - | yes |
| `homepage_url` | Repository homepage URL | `string` | `null` | no |
| `is_template` | Mark as template repository | `bool` | `false` | no |
| `template` | Template repository to use | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `repository` | Repository details (name, url, visibility, etc.) |
| `node_id` | Repository node ID for use in other resources |
