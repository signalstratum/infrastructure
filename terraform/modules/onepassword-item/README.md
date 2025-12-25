# 1Password Item Module

Creates items in 1Password vault for storing Terraform-generated secrets.

## Usage

```hcl
module "tunnel_secret" {
  source = "./modules/onepassword-item"

  vault_id = var.onepassword_vault_id
  title    = "Cloudflare Tunnel - Virginia"
  category = "password"
  url      = "https://one.dash.cloudflare.com/"

  fields = {
    tunnel_id    = cloudflare_zero_trust_tunnel_cloudflared.virginia.id
    tunnel_token = data.cloudflare_zero_trust_tunnel_cloudflared_token.virginia.token
  }

  tags  = ["terraform", "cloudflare", "virginia"]
  notes = "Managed by Terraform"
}
```

## Features

- Automatically stores Terraform-generated secrets in 1Password
- All field values marked as concealed
- Supports multiple categories (password, login, secure_note, etc.)
- Custom tags and notes

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vault_id` | 1Password vault ID | `string` | - | yes |
| `title` | Item title | `string` | - | yes |
| `category` | Item category | `string` | `"password"` | no |
| `fields` | Map of field names to values | `map(string)` | - | yes |
| `tags` | Tags for the item | `list(string)` | `["terraform-managed"]` | no |
| `url` | URL associated with the item | `string` | `null` | no |
| `notes` | Notes for the item | `string` | `"Managed by Terraform..."` | no |

### Valid Categories

- `login`
- `password`
- `database`
- `secure_note`
- `credit_card`
- `identity`
- `document`
- `ssh_key`

## Outputs

| Name | Description |
|------|-------------|
| `item_id` | 1Password item ID |
| `item_uuid` | 1Password item UUID |
