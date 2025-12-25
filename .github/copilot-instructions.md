# infrastructure

Infrastructure-as-Code for Signal Stratum resources.

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `terraform/` | Terraform configurations for cloud resources |
| `.github/workflows/` | CI/CD pipelines for terraform apply |
| `.github/instructions/` | Copilot instruction files |

## Key Technologies

- **Terraform** 1.x with providers: Cloudflare, GitHub, Hetzner
- **GitHub Actions** for CI/CD
- **Copilot** with custom instructions.

## Conventions

- Terraform files: one resource type per file or logical grouping
- Naming: `snake_case` for resources, prefix with provider (`github_`, `cloudflare_`)
- Secrets: Never hardcoded—use Terraform variables with `sensitive = true`
- State: Remote backend (configure per environment)

## Instruction Files

Core governance and domain-specific rules are in `.github/instructions/`:

- **core.instructions.md** — Meta-governance (confidence model, communication patterns)
- **terraform.instructions.md** — IaC conventions and security patterns

## Getting Started

```bash
cd terraform/
terraform init
terraform plan
```

For CI/CD, see `.github/workflows/`.
