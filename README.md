# Infrastructure

IaC for Signal Stratum. Terraform manages Cloudflare and GitHub resources, with secrets injected from 1Password at runtime.

## What's Managed

| Resource | Provider |
|----------|----------|
| DNS (signalstratum.com, .io) | Cloudflare |
| Email routing → Gmail | Cloudflare |
| Zone security (TLS 1.2+, strict SSL) | Cloudflare |
| Zero Trust tunnel (Virginia Talos cluster) | Cloudflare |
| Repositories + branch protection | GitHub |
| Actions permissions (allowed orgs) | GitHub |

## Architecture

```mermaid
flowchart TB
    subgraph github["GitHub Actions"]
        secret["OP_SERVICE_ACCOUNT_TOKEN"]
        job["Terraform Job"]
    end

    subgraph op["1Password Vault"]
        cf["cloudflare/*"]
        gh["github/*"]
        r2["r2/*"]
    end

    subgraph infra["Infrastructure"]
        cloudflare["Cloudflare<br/>DNS, Email, Security, Tunnel"]
        github_api["GitHub<br/>Repos, Branch Protection"]
        state["R2 Backend<br/>tfstate"]
    end

    secret --> job
    job -->|"op://ss-infrastructure/*"| cf & gh & r2
    cf --> cloudflare
    gh --> github_api
    r2 --> state
```

One secret in GitHub. Everything else lives in 1Password.

## CI/CD Workflow

```mermaid
flowchart LR
    subgraph pr["Pull Request"]
        A[Push] --> B[TFLint + Checkov]
        B --> C[terraform plan]
        C --> D[Plan commented on PR]
    end

    subgraph main["Main Branch"]
        E[Merge] --> F[terraform apply]
    end

    D -->|Review + Approve| E
```

- **Fork PRs** skip entirely (no secrets access)
- **Feature PRs** run plan, comment results for review
- **Main branch** auto-applies after merge

## Structure

```
terraform/
├── providers.tf    # Backend (R2) + provider configs
├── variables.tf    # Inputs (via TF_VAR_ from 1Password)
├── locals.tf       # Computed values
├── outputs.tf      # All outputs
├── cloudflare.tf   # Zones, tunnel, DNS, email, security
├── github.tf       # Org settings, repositories
└── modules/
    ├── github-repository/   # Standardized repo + branch protection
    └── onepassword-item/    # Store terraform-generated secrets
```

## Secrets

```
ss-infrastructure/
├── cloudflare/api-token
├── cloudflare/account-id
├── cloudflare/com-zone-id
├── cloudflare/io-zone-id
├── github/api-token
└── r2/access-key-id, secret-access-key, url
```

## Local Development

```bash
cd terraform
op run --env-file=../.env.tpl -- terraform plan
```

## Branch Protection

- Signed commits required
- Squash merge only
- Status checks must pass
- Owner bypass for solo dev workflow

## Adding Resources

1. Add to appropriate `.tf` file
2. `terraform plan` locally to verify
3. PR → review plan → merge
4. Apply runs automatically

## Adding Secrets

1. Add to 1Password vault `ss-infrastructure`
2. Reference in workflow as `op://ss-infrastructure/item/field`
3. Add to `.env.tpl` for local dev

---

This repo was bootstrapped manually (chicken/egg), then imported into Terraform.
