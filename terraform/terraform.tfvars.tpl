# Terraform Variables
# Injected from 1Password via: op inject -i terraform.tfvars.tpl -o terraform.tfvars

cloudflare_account_id  = "{{ op://ss-infrastructure/cloudflare/account-id }}"
cloudflare_zone_id_com = "{{ op://ss-infrastructure/cloudflare/com-zone-id }}"
cloudflare_zone_id_io  = "{{ op://ss-infrastructure/cloudflare/io-zone-id }}"
onepassword_vault_id   = "ss-tf-managed"
