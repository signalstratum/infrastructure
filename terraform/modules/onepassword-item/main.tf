# 1Password Item Module
# See README.md for usage documentation

terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }
}

variable "vault_id" {
  type        = string
  description = "1Password vault ID to store the item"
}

variable "title" {
  type        = string
  description = "Item title"
}

variable "category" {
  type        = string
  default     = "password"
  description = "Item category: login, password, database, secure_note, etc."
  validation {
    condition     = contains(["login", "password", "database", "secure_note", "credit_card", "identity", "document", "ssh_key"], var.category)
    error_message = "Category must be one of: login, password, database, secure_note, credit_card, identity, document, ssh_key"
  }
}

variable "fields" {
  type        = map(string)
  description = "Map of field names to values (all marked sensitive)"
  sensitive   = true
}

variable "tags" {
  type        = list(string)
  default     = ["terraform-managed"]
  description = "Tags for the item"
}

variable "url" {
  type        = string
  default     = null
  description = "URL associated with the item"
}

variable "notes" {
  type        = string
  default     = "Managed by Terraform - do not edit manually"
  description = "Notes for the item"
}

resource "onepassword_item" "this" {
  vault      = var.vault_id
  title      = var.title
  category   = var.category
  tags       = var.tags
  url        = var.url
  note_value = var.notes

  dynamic "section" {
    for_each = length(var.fields) > 0 ? [1] : []
    content {
      label = "Credentials"

      dynamic "field" {
        for_each = var.fields
        content {
          label = field.key
          value = field.value
          type  = "CONCEALED"
        }
      }
    }
  }
}

output "item_id" {
  description = "1Password item ID"
  value       = onepassword_item.this.id
}

output "item_uuid" {
  description = "1Password item UUID"
  value       = onepassword_item.this.uuid
}
